import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smarttimelog/services/session_storage.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';

void main() {
  test('does not send authentication on the login request', () async {
    http.Request? capturedRequest;
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://smarttimelog-admin.vercel.app',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'accessToken': 'server-token',
            'expiresIn': 3600,
            'employee': {
              'employeeId': 42,
              'username': 'employee',
              'firstName': 'Test',
              'lastName': 'User',
              'headquarters': null,
            },
          }),
          200,
        );
      }),
    );

    await api.login(username: 'employee', password: 'password');

    expect(capturedRequest?.headers.containsKey('authorization'), isFalse);
  });

  test('requires an authenticated session before protected requests', () async {
    final api = SmartTimeLogApiClient(baseUrl: 'https://smarttimelog-admin.vercel.app');

    await expectLater(
      api.getAttendanceStatus(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Please log in again.',
        ),
      ),
    );
  });

  test('clears the persisted session after an unauthorized response', () async {
    final storage = _MemorySessionStorage()
      ..values['access_token'] = 'stored-token'
      ..values['token_expires_at'] = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String()
      ..values['employee'] = jsonEncode({
        'employeeId': 42,
        'username': 'employee',
        'firstName': 'Test',
        'lastName': 'User',
        'headquarters': null,
      });
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://smarttimelog-admin.vercel.app',
      sessionStorage: storage,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Session expired.'}),
          401,
        ),
      ),
    );

    await api.restoreSession();
    await expectLater(api.getAttendanceStatus(), throwsA(isA<ApiException>()));

    expect(api.hasSession, isFalse);
    expect(storage.values, isEmpty);
  });
}

class _MemorySessionStorage implements SessionStorage {
  final Map<String, String> values = {};

  @override
  Future<void> deleteAll() async => values.clear();

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
