import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';

void main() {
  final token = List.filled(64, 'a').join();
  test(
    'loads public QR expiry and headquarters, then registers with the selected ID',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/admin/registration-qr':
            return http.Response(
              jsonEncode({
                'qrCode': 'data:image/png;base64,AA==',
                'expiresAt': '2026-10-17T12:30:00Z',
              }),
              200,
            );
          case '/api/mobile/headquarters':
            return http.Response(
              jsonEncode([
                {'hq_id': 7, 'hq_name': 'Davao Office'},
                {'hq_id': 9, 'hq_name': null},
              ]),
              200,
            );
          case '/api/mobile/register':
            return http.Response(
              jsonEncode({
                'ok': true,
                'isPending': true,
                'employee': {'employeeId': 42},
              }),
              201,
            );
        }
        return http.Response('Not found', 404);
      });
      final api = SmartTimeLogApiClient(
        baseUrl: 'https://example.test',
        client: client,
      );

      final currentQr = await api.getCurrentRegistrationQr();
      expect(currentQr.expiresAt, DateTime.utc(2026, 10, 17, 12, 30));
      expect(currentQr.dataUrl, 'data:image/png;base64,AA==');
      final headquarters = await api.getRegistrationHeadquarters();
      expect(headquarters.map((hq) => hq.id), [7, 9]);
      expect(headquarters.first.name, 'Davao Office');
      await api.register(
        registrationToken: token,
        firstName: 'Test',
        lastName: 'User',
        username: 'testuser',
        password: 'secret123',
        headquartersId: headquarters.first.id,
      );
      expect(requests.map((request) => request.url.path), [
        '/api/admin/registration-qr',
        '/api/mobile/headquarters',
        '/api/mobile/register',
      ]);
      for (final request in requests) {
        expect(request.headers.containsKey('authorization'), isFalse);
      }
      expect(jsonDecode(requests.last.body), {
        'registrationToken': token,
        'firstName': 'Test',
        'lastName': 'User',
        'username': 'testuser',
        'plainPassword': 'secret123',
        'headquartersId': 7,
      });
    },
  );

  test('surfaces expired or invalid registration QR from server', () async {
    final api = SmartTimeLogApiClient(
      baseUrl: 'https://example.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'ok': false, 'message': 'Registration QR expired.'}),
          401,
        ),
      ),
    );
    await expectLater(
      api.register(
        registrationToken: token,
        firstName: 'Test',
        lastName: 'User',
        username: 'testuser',
        password: 'secret123',
        headquartersId: 7,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
