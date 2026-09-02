import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'session_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class Headquarters {
  const Headquarters({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String? name;
  final double latitude;
  final double longitude;

  factory Headquarters.fromJson(Map<String, dynamic> json) {
    final id = json['hq_id'];
    final latitude = json['lat'];
    final longitude = json['long'];
    if (id is! int || latitude is! num || longitude is! num) {
      throw const FormatException('Invalid headquarters response.');
    }
    return Headquarters(
      id: id,
      name: json['hq_name'] as String?,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'hq_id': id,
    'hq_name': name,
    'lat': latitude,
    'long': longitude,
  };
}

class AuthenticatedEmployee {
  const AuthenticatedEmployee({
    required this.employeeId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.headquarters,
  });

  final int employeeId;
  final String username;
  final String? firstName;
  final String? lastName;
  final Headquarters? headquarters;

  factory AuthenticatedEmployee.fromJson(Map<String, dynamic> json) {
    final employeeId = json['employeeId'];
    final username = json['username'];
    if (employeeId is! int || username is! String) {
      throw const FormatException('Invalid employee response.');
    }
    final headquartersJson = json['headquarters'];
    return AuthenticatedEmployee(
      employeeId: employeeId,
      username: username,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      headquarters: headquartersJson is Map<String, dynamic>
          ? Headquarters.fromJson(headquartersJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'headquarters': headquarters?.toJson(),
  };
}

enum AttendanceState {
  notClockedIn,
  clockedIn,
  onBreak,
  clockedOut;

  factory AttendanceState.fromJson(String value) => switch (value) {
    'not_clocked_in' => notClockedIn,
    'clocked_in' => clockedIn,
    'on_break' => onBreak,
    'clocked_out' => clockedOut,
    _ => throw const FormatException('Invalid attendance status.'),
  };
}

class AttendanceStatus {
  const AttendanceStatus({
    required this.date,
    required this.state,
    required this.latestTimelog,
  });

  final DateTime date;
  final AttendanceState state;
  final Map<String, dynamic>? latestTimelog;

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final status = json['status'];
    if (date == null || status is! String) {
      throw const FormatException('Invalid attendance status response.');
    }
    return AttendanceStatus(
      date: date,
      state: AttendanceState.fromJson(status),
      latestTimelog: json['latestTimelog'] is Map<String, dynamic>
          ? json['latestTimelog'] as Map<String, dynamic>
          : null,
    );
  }
}

class SmartTimeLogApi {
  SmartTimeLogApi._();

  static late final SmartTimeLogApiClient instance;

  static Future<void> initialize({
    required String baseUrl,
    SessionStorage sessionStorage = const SecureSessionStorage(),
  }) async {
    instance = SmartTimeLogApiClient(
      baseUrl: baseUrl,
      sessionStorage: sessionStorage,
    );
    try {
      await instance.restoreSession();
    } on Object {
      // A storage failure must not prevent the login screen from starting.
    }
  }
}

class SmartTimeLogApiClient {
  SmartTimeLogApiClient({
    required String baseUrl,
    http.Client? client,
    SessionStorage? sessionStorage,
    Duration requestTimeout = const Duration(seconds: 20),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _client = client ?? http.Client(),
       _sessionStorage = sessionStorage,
       _requestTimeout = requestTimeout;

  static const _tokenKey = 'access_token';
  static const _expiresAtKey = 'token_expires_at';
  static const _employeeKey = 'employee';

  final String _baseUrl;
  final http.Client _client;
  final SessionStorage? _sessionStorage;
  final Duration _requestTimeout;
  String? _accessToken;
  AuthenticatedEmployee? _currentEmployee;

  bool get hasSession => _accessToken != null && _currentEmployee != null;
  AuthenticatedEmployee? get currentEmployee => _currentEmployee;

  Future<void> restoreSession() async {
    final storage = _sessionStorage;
    if (storage == null) return;

    final values = await Future.wait([
      storage.read(_tokenKey),
      storage.read(_expiresAtKey),
      storage.read(_employeeKey),
    ]);
    final [token, expiresAtValue, employeeValue] = values;
    final expiresAt = DateTime.tryParse(expiresAtValue ?? '');
    if (token == null ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now().toUtc()) ||
        employeeValue == null) {
      await clearSession();
      return;
    }

    try {
      final employeeJson = jsonDecode(employeeValue);
      if (employeeJson is! Map<String, dynamic>) {
        throw const FormatException();
      }
      _accessToken = token;
      _currentEmployee = AuthenticatedEmployee.fromJson(employeeJson);
    } on FormatException {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _currentEmployee = null;
    try {
      await _sessionStorage?.deleteAll();
    } on Object {
      // In-memory logout must still succeed if secure storage is unavailable.
    }
  }

  Future<AuthenticatedEmployee> login({
    required String username,
    required String password,
  }) async {
    final response = await _post(
      '/api/mobile/login',
      body: {'username': username, 'plainPassword': password},
      authenticated: false,
    );
    _accessToken = response['accessToken'] as String?;
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw const ApiException(
        'The server returned an invalid login response.',
      );
    }
    final employee = response['employee'];
    if (employee is! Map<String, dynamic>) {
      throw const ApiException(
        'The server returned an invalid employee response.',
      );
    }
    try {
      final authenticatedEmployee = AuthenticatedEmployee.fromJson(employee);
      _currentEmployee = authenticatedEmployee;
      final expiresIn = response['expiresIn'];
      if (expiresIn is! int) {
        throw const FormatException();
      }
      final storage = _sessionStorage;
      if (storage != null) {
        await storage.write(_tokenKey, _accessToken!);
        await storage.write(
          _expiresAtKey,
          DateTime.now()
              .toUtc()
              .add(Duration(seconds: expiresIn))
              .toIso8601String(),
        );
        await storage.write(
          _employeeKey,
          jsonEncode(authenticatedEmployee.toJson()),
        );
      }
      return authenticatedEmployee;
    } on FormatException {
      await clearSession();
      throw const ApiException(
        'The server returned an invalid employee response.',
      );
    }
  }

  Future<AttendanceStatus> getAttendanceStatus() async {
    final response = await _request('GET', '/api/mobile/status');
    try {
      return AttendanceStatus.fromJson(response);
    } on FormatException {
      throw const ApiException(
        'The server returned an invalid attendance status.',
      );
    }
  }

  Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
  }) {
    return _post(
      '/api/mobile/clock-in',
      body: {'lat': latitude, 'long': longitude},
    );
  }

  Future<Map<String, dynamic>> takeBreak({
    required double latitude,
    required double longitude,
  }) {
    return _post(
      '/api/mobile/break',
      body: {'lat': latitude, 'long': longitude},
    );
  }

  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
    required String employeeInput,
  }) {
    return _post(
      '/api/mobile/clock-out',
      body: {
        'lat': latitude,
        'long': longitude,
        'employeeInput': employeeInput,
      },
    );
  }

  Future<String> summarizeWork(String employeeInput) async {
    final response = await _post(
      '/api/mobile/ai-summary',
      body: {'employeeInput': employeeInput},
    );
    final summary = response['summary'] as String?;
    if (summary == null || summary.isEmpty) {
      throw const ApiException(
        'The server returned an invalid summary response.',
      );
    }
    return summary;
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    return _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    if (authenticated && _accessToken == null) {
      throw const ApiException('Please log in again.');
    }

    try {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'))
        ..headers.addAll({
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
          if (authenticated) 'Authorization': 'Bearer $_accessToken',
        });
      if (body != null) {
        request.body = jsonEncode(body);
      }
        final response = await _client
          .send(request)
          .then(http.Response.fromStream)
            .timeout(_requestTimeout);

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message'] as String?
            : null;
        if (response.statusCode == 401 || response.statusCode == 403) {
          await clearSession();
        }
        throw ApiException(
          message ?? 'Request failed (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('The server returned an invalid response.');
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const ApiException('Unable to reach the server.');
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }
}
