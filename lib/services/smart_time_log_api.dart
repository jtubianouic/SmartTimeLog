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

enum AttendanceTimelogType {
  clockIn,
  breakStart,
  breakEnd,
  clockOut;

  String get label => switch (this) {
    clockIn => 'Clocked in',
    breakStart => 'Break started',
    breakEnd => 'Break ended',
    clockOut => 'Clocked out',
  };

  factory AttendanceTimelogType.fromJson(String value) => switch (value) {
    'clock_in' => clockIn,
    'break' || 'break_start' => breakStart,
    'break_end' => breakEnd,
    'clock_out' => clockOut,
    _ => throw const FormatException('Invalid attendance timelog type.'),
  };
}

class AttendanceTimelog {
  const AttendanceTimelog({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  final int id;
  final int employeeId;
  final AttendanceTimelogType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  factory AttendanceTimelog.fromJson(Map<String, dynamic> json) {
    final id = json['timelog_id'];
    final employeeId = json['employee_id'];
    final logType = json['log_type'];
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
    if (id is! int ||
        employeeId is! int ||
        logType is! String ||
        timestamp == null) {
      throw const FormatException('Invalid attendance timelog response.');
    }
    return AttendanceTimelog(
      id: id,
      employeeId: employeeId,
      type: AttendanceTimelogType.fromJson(logType),
      timestamp: timestamp,
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['long'] as num?)?.toDouble(),
    );
  }
}

class AttendanceStatus {
  const AttendanceStatus({
    required this.date,
    required this.state,
    required this.clockedInDurationSeconds,
    required this.breakDurationSeconds,
    required this.currentBreakDurationSeconds,
    required this.latestTimelog,
    this.timelogs = const [],
  });

  final DateTime date;
  final AttendanceState state;
  final int clockedInDurationSeconds;
  final int breakDurationSeconds;
  final int currentBreakDurationSeconds;
  final AttendanceTimelog? latestTimelog;
  final List<AttendanceTimelog> timelogs;

  bool get hasTakenBreak =>
      state == AttendanceState.onBreak ||
      breakDurationSeconds > 0 ||
      currentBreakDurationSeconds > 0 ||
      latestTimelog?.type == AttendanceTimelogType.breakStart ||
      latestTimelog?.type == AttendanceTimelogType.breakEnd ||
      timelogs.any(
        (timelog) =>
            timelog.type == AttendanceTimelogType.breakStart ||
            timelog.type == AttendanceTimelogType.breakEnd,
      );

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final timelogsJson = json['timelogs'];
    if (status is! String ||
        (timelogsJson != null && timelogsJson is! List<dynamic>)) {
      throw const FormatException('Invalid attendance status response.');
    }
    final state = AttendanceState.fromJson(status);
    final timelogs = (timelogsJson as List<dynamic>? ?? const [])
        .map((entry) {
          if (entry is! Map) {
            throw const FormatException('Invalid attendance timelog response.');
          }
          return AttendanceTimelog.fromJson(Map<String, dynamic>.from(entry));
        })
        .toList(growable: false);
    final latestTimelogJson = json['latestTimelog'];
    final latestTimelog =
        latestTimelogJson is Map && latestTimelogJson.isNotEmpty
        ? AttendanceTimelog.fromJson(
            Map<String, dynamic>.from(latestTimelogJson),
          )
        : null;
    final derivedDurations = _deriveDurations(state, timelogs);
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ??
        (timelogs.isEmpty
            ? DateTime.now()
            : timelogs
                  .map((timelog) => timelog.timestamp)
                  .reduce((a, b) => a.isAfter(b) ? a : b));
    return AttendanceStatus(
      date: date,
      state: state,
      clockedInDurationSeconds:
          (json['clockedInDurationSeconds'] as num?)?.toInt() ??
          derivedDurations.clockedIn,
      breakDurationSeconds:
          (json['breakDurationSeconds'] as num?)?.toInt() ??
          derivedDurations.completedBreak,
      currentBreakDurationSeconds:
          (json['currentBreakDurationSeconds'] as num?)?.toInt() ??
          derivedDurations.currentBreak,
      latestTimelog: latestTimelog,
      timelogs: timelogs,
    );
  }

  static ({int clockedIn, int completedBreak, int currentBreak})
  _deriveDurations(AttendanceState state, List<AttendanceTimelog> timelogs) {
    final ordered = [...timelogs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final clockInIndex = ordered.lastIndexWhere(
      (timelog) => timelog.type == AttendanceTimelogType.clockIn,
    );
    if (clockInIndex == -1) {
      return (clockedIn: 0, completedBreak: 0, currentBreak: 0);
    }

    final now = DateTime.now().toUtc();
    final currentShift = ordered.sublist(clockInIndex);
    final clockInTime = currentShift.first.timestamp;
    AttendanceTimelog? clockOut;
    for (final timelog in currentShift) {
      if (timelog.type == AttendanceTimelogType.clockOut) {
        clockOut = timelog;
        break;
      }
    }
    final shiftEnd = clockOut?.timestamp ?? now;
    final clockedIn = shiftEnd.difference(clockInTime).inSeconds;

    var completedBreak = 0;
    DateTime? breakStartedAt;
    for (final timelog in currentShift.skip(1)) {
      switch (timelog.type) {
        case AttendanceTimelogType.breakStart:
          breakStartedAt ??= timelog.timestamp;
        case AttendanceTimelogType.breakEnd:
          final startedAt = breakStartedAt;
          if (startedAt != null) {
            completedBreak += timelog.timestamp.difference(startedAt).inSeconds;
            breakStartedAt = null;
          }
        case AttendanceTimelogType.clockOut:
          final startedAt = breakStartedAt;
          if (startedAt != null) {
            completedBreak += timelog.timestamp.difference(startedAt).inSeconds;
            breakStartedAt = null;
          }
        case AttendanceTimelogType.clockIn:
          break;
      }
    }
    final currentBreak =
        state == AttendanceState.onBreak && breakStartedAt != null
        ? now.difference(breakStartedAt).inSeconds
        : 0;
    return (
      clockedIn: clockedIn < 0 ? 0 : clockedIn,
      completedBreak: completedBreak < 0 ? 0 : completedBreak,
      currentBreak: currentBreak < 0 ? 0 : currentBreak,
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
    this._sessionStorage,
    this._requestTimeout = const Duration(seconds: 20),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _client = client ?? http.Client();

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
      final storage = _sessionStorage;
      if (storage != null) {
        await Future.wait([
          storage.delete(_tokenKey),
          storage.delete(_expiresAtKey),
          storage.delete(_employeeKey),
        ]);
      }
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

  Future<Map<String, dynamic>> endBreak({
    required double latitude,
    required double longitude,
  }) {
    return _post(
      '/api/mobile/break/end',
      body: {'lat': latitude, 'long': longitude},
    );
  }

  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
    required String employeeInput,
    required String aiSummary,
  }) {
    return _post(
      '/api/mobile/clock-out',
      body: {
        'lat': latitude,
        'long': longitude,
        'employeeInput': employeeInput,
        'aiSummary': aiSummary,
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
