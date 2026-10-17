import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smarttimelog/main.dart';
import 'package:smarttimelog/providers/theme_notifier.dart';
import 'package:smarttimelog/screens/registration_screen.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';
import 'package:zxing2/qrcode.dart' as zxing;

void main() {
  final token = List.filled(64, 'a').join();
  var registrationRequests = 0;

  setUpAll(() {
    SmartTimeLogApi.instance = SmartTimeLogApiClient(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/admin/registration-qr':
            return http.Response(
              jsonEncode({
                'qrCode': _qrDataUrl(token),
                'expiresAt': DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
              }),
              200,
            );
          case '/api/mobile/headquarters':
            return http.Response(
              jsonEncode([
                {'hq_id': 7, 'hq_name': 'Davao Office'},
              ]),
              200,
            );
          case '/api/mobile/register':
            registrationRequests++;
            return http.Response(
              jsonEncode({'ok': false, 'message': 'Username already exists.'}),
              409,
            );
        }
        return http.Response('Not found', 404);
      }),
    );
  });

  testWidgets(
    'form uses the global theme and validates password confirmation',
    (tester) async {
      registrationRequests = 0;
      themeNotifier.setTheme(ThemeMode.light);
      final originalPlatform = MobileScannerPlatform.instance;
      final fakePlatform = _FakeScannerPlatform();
      MobileScannerPlatform.instance = fakePlatform;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(const MyApp(home: RegistrationScreen()));
        expect(find.byTooltip('Dark Mode'), findsOneWidget);
        await tester.tap(find.byTooltip('Dark Mode'));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(RegistrationScreen))).brightness,
          Brightness.dark,
        );

        fakePlatform.addBarcode(
          BarcodeCapture(
            barcodes: [Barcode(rawValue: token, format: BarcodeFormat.qrCode)],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Complete your registration'), findsOneWidget);
        expect(find.text('Confirm password'), findsOneWidget);
        expect(find.byTooltip('Light Mode'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'secret123',
        );
        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Confirm password'),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'different123',
        );
        await tester.ensureVisible(find.text('Request registration'));
        await tester.tap(find.text('Request registration'));
        await tester.pumpAndSettle();
        expect(find.text('Passwords do not match'), findsOneWidget);
        expect(registrationRequests, 0);
        final darkTheme = Theme.of(
          tester.element(find.byType(RegistrationScreen)),
        );
        final darkErrorBorder =
            darkTheme.inputDecorationTheme.errorBorder! as OutlineInputBorder;
        final darkFocusedErrorBorder =
            darkTheme.inputDecorationTheme.focusedErrorBorder!
                as OutlineInputBorder;
        expect(darkErrorBorder.borderSide.color, darkTheme.colorScheme.error);
        expect(
          darkFocusedErrorBorder.borderSide.color,
          darkTheme.colorScheme.error,
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'secret123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'First name'),
          'Ada',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last name'),
          'Lovelace',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'ada.lovelace',
        );
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final headquarters = find.byType(DropdownButtonFormField<int>);
        await tester.ensureVisible(headquarters);
        await tester.drag(find.byType(ListView), const Offset(0, 180));
        await tester.pumpAndSettle();
        await tester.tap(headquarters);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Davao Office').last);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Request registration'));
        await tester.pumpAndSettle();
        expect(registrationRequests, 1);
        expect(
          find.text('Registration could not be submitted'),
          findsOneWidget,
        );
        expect(find.text('Username already exists.'), findsOneWidget);

        await tester.tap(find.byTooltip('Light Mode'));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(RegistrationScreen))).brightness,
          Brightness.light,
        );
        final lightTheme = Theme.of(
          tester.element(find.byType(RegistrationScreen)),
        );
        final lightErrorBorder =
            lightTheme.inputDecorationTheme.errorBorder! as OutlineInputBorder;
        expect(lightErrorBorder.borderSide.color, lightTheme.colorScheme.error);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        MobileScannerPlatform.instance = originalPlatform;
        debugDefaultTargetPlatformOverride = null;
        themeNotifier.setTheme(ThemeMode.light);
      }
    },
  );
}

String _qrDataUrl(String token) {
  final matrix = zxing.Encoder.encode(
    token,
    zxing.ErrorCorrectionLevel.h,
  ).matrix!;
  const scale = 5;
  const margin = 4;
  final side = (matrix.width + margin * 2) * scale;
  final image = img.Image(width: side, height: side);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < matrix.height; y++) {
    for (var x = 0; x < matrix.width; x++) {
      if (matrix.get(x, y) == 1) {
        img.fillRect(
          image,
          x1: (x + margin) * scale,
          y1: (y + margin) * scale,
          x2: (x + margin + 1) * scale - 1,
          y2: (y + margin + 1) * scale - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }
  return 'data:image/png;base64,${base64Encode(Uint8List.fromList(img.encodePng(image)))}';
}

class _FakeScannerPlatform extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture>.broadcast();

  void addBarcode(BarcodeCapture capture) => _barcodes.add(capture);

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async =>
      const MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.unavailable,
        size: Size(200, 200),
        numberOfCameras: 1,
      );

  @override
  Widget buildCameraView() => const SizedBox.square(dimension: 100);

  @override
  Future<void> dispose() => _barcodes.close();
}
