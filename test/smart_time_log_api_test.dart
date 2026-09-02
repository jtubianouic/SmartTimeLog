import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smarttimelog/services/device_location_service.dart';
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
      return http.Response(jsonEncode({'ok': true, 'timelog': {}}), 201);
    });
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://example.com/',
      client: client,
    );

    final employee = await api.login(
      username: 'employee',
      password: 'password',
    );
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
    expect(requests.map((request) => request.url.path), [
      '/api/mobile/login',
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
    for (final request in requests.skip(1)) {
      expect(request.headers['authorization'], 'Bearer test-token');
    }
    expect(jsonDecode(requests[1].body), {'lat': 7.0731, 'long': 125.6128});
    expect(jsonDecode(requests[2].body), {'lat': 7.0731, 'long': 125.6128});
    expect(jsonDecode(requests[3].body), {
      'employeeInput': 'Completed API integration',
    });
    expect(jsonDecode(requests[4].body), {
      'lat': 7.0731,
      'long': 125.6128,
      'employeeInput': 'Completed API integration',
    });
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
