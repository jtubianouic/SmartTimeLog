import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smarttimelog/services/device_location_service.dart';
import 'package:smarttimelog/services/session_storage.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';

void main() {
  test('sends documented payloads and bearer token', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/mobile/login') {
        return http.Response(
          jsonEncode({
            'ok': true,
            'accessToken': 'test-token',
            'tokenType': 'Bearer',
            'expiresIn': 43200,
            'employee': {
              'employeeId': 42,
              'username': 'employee',
              'firstName': 'Test',
              'lastName': 'User',
              'headquarters': {
                'hq_id': 7,
                'hq_name': 'Davao Office',
                'lat': 7.0731,
                'long': 125.6128,
              },
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/mobile/ai-summary') {
        return http.Response(
          jsonEncode({'ok': true, 'summary': 'Generated summary'}),
          200,
        );
      }
      if (request.url.path == '/api/mobile/status') {
        return http.Response(
          jsonEncode({
            'ok': true,
            'date': '2026-09-02',
            'status': 'clocked_in',
            'latestTimelog': {
              'timelog_id': 9,
              'employee_id': 42,
              'log_type': 'clock_in',
              'lat': 7.0731,
              'long': 125.6128,
              'timestamp': '2026-09-02T08:00:00Z',
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'ok': true, 'timelog': {}}), 201);
    });
    final storage = _MemorySessionStorage();
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://example.com/',
      client: client,
      sessionStorage: storage,
    );

    final employee = await api.login(
      username: 'employee',
      password: 'password',
    );
    final status = await api.getAttendanceStatus();
    await api.clockIn(latitude: 7.0731, longitude: 125.6128);
    await api.takeBreak(latitude: 7.0731, longitude: 125.6128);
    final summary = await api.summarizeWork('Completed API integration');
    await api.clockOut(
      latitude: 7.0731,
      longitude: 125.6128,
      employeeInput: 'Completed API integration',
    );

    expect(summary, 'Generated summary');
    expect(employee.employeeId, 42);
    expect(employee.headquarters?.id, 7);
    expect(employee.headquarters?.name, 'Davao Office');
    expect(employee.headquarters?.latitude, 7.0731);
    expect(employee.headquarters?.longitude, 125.6128);
    expect(status.state, AttendanceState.clockedIn);
    expect(status.latestTimelog?['timelog_id'], 9);
    expect(storage.values['access_token'], 'test-token');
    expect(requests.map((request) => request.url.path), [
      '/api/mobile/login',
      '/api/mobile/status',
      '/api/mobile/clock-in',
      '/api/mobile/break',
      '/api/mobile/ai-summary',
      '/api/mobile/clock-out',
    ]);
    expect(jsonDecode(requests[0].body), {
      'username': 'employee',
      'plainPassword': 'password',
    });
    expect(requests[0].headers.containsKey('authorization'), isFalse);
    expect(requests[1].method, 'GET');
    for (final request in requests.skip(1)) {
      expect(request.headers['authorization'], 'Bearer test-token');
    }
    expect(jsonDecode(requests[2].body), {'lat': 7.0731, 'long': 125.6128});
    expect(jsonDecode(requests[3].body), {'lat': 7.0731, 'long': 125.6128});
    expect(jsonDecode(requests[4].body), {
      'employeeInput': 'Completed API integration',
    });
    expect(jsonDecode(requests[5].body), {
      'lat': 7.0731,
      'long': 125.6128,
      'employeeInput': 'Completed API integration',
    });
  });

  test(
    'restores a valid session and clears it after unauthorized status',
    () async {
      final storage = _MemorySessionStorage()
        ..values['access_token'] = 'stored-token'
        ..values['token_expires_at'] = DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String()
        ..values['employee'] = jsonEncode({
          'employeeId': 42,
          'username': 'employee',
          'firstName': null,
          'lastName': null,
          'headquarters': null,
        });
      final api = SmartTimeLogApiClient(
        baseUrl: 'https://example.com',
        sessionStorage: storage,
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({'ok': false, 'message': 'Expired token.'}),
            401,
          ),
        ),
      );

      await api.restoreSession();
      expect(api.hasSession, isTrue);
      await expectLater(
        api.getAttendanceStatus(),
        throwsA(isA<ApiException>()),
      );
      expect(api.hasSession, isFalse);
      expect(storage.values, isEmpty);
    },
  );

  test('clears an expired persisted session', () async {
    final storage = _MemorySessionStorage()
      ..values['access_token'] = 'expired-token'
      ..values['token_expires_at'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 1))
          .toIso8601String()
      ..values['employee'] = jsonEncode({
        'employeeId': 42,
        'username': 'employee',
        'firstName': null,
        'lastName': null,
        'headquarters': null,
      });
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://example.com',
      sessionStorage: storage,
    );

    await api.restoreSession();

    expect(api.hasSession, isFalse);
    expect(storage.values, isEmpty);
  });

  test('surfaces the backend error message', () async {
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'ok': false, 'message': 'Invalid credentials.'}),
          401,
        ),
      ),
    );

    expect(
      () => api.login(username: 'employee', password: 'wrong'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              'Invalid credentials.',
            ),
      ),
    );
  });

  test('times out when the response body never completes', () async {
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://example.com',
      client: _NeverCompletingClient(),
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      api.login(username: 'employee', password: 'password'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The request timed out. Please try again.',
        ),
      ),
    );
  });

  test('calculates employee proximity to headquarters in meters', () {
    final sameLocation = DeviceLocationService.distanceBetween(
      startLatitude: 7.0731,
      startLongitude: 125.6128,
      endLatitude: 7.0731,
      endLongitude: 125.6128,
    );
    final nearbyLocation = DeviceLocationService.distanceBetween(
      startLatitude: 7.0731,
      startLongitude: 125.6128,
      endLatitude: 7.0740,
      endLongitude: 125.6128,
    );

    expect(sameLocation, 0);
    expect(nearbyLocation, greaterThan(95));
    expect(nearbyLocation, lessThan(105));
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

class _NeverCompletingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      StreamController<List<int>>().stream,
      200,
    );
  }
}
