import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
}

class SmartTimeLogApi {
  SmartTimeLogApi._();

  static late final SmartTimeLogApiClient instance;

  static void initialize({required String baseUrl}) {
    instance = SmartTimeLogApiClient(baseUrl: baseUrl);
  }
}

class SmartTimeLogApiClient {
  SmartTimeLogApiClient({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  String? _accessToken;

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
      return AuthenticatedEmployee.fromJson(employee);
    } on FormatException {
      throw const ApiException(
        'The server returned an invalid employee response.',
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
    if (authenticated && _accessToken == null) {
      throw const ApiException('Please log in again.');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (authenticated) 'Authorization': 'Bearer $_accessToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message'] as String?
            : null;
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
