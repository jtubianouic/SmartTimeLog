import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smarttimelog/screens/login_screen.dart';

void main() {
  testWidgets(
    'registration opens the camera with upload beside the scan flow',
    (tester) async {
      final originalPlatform = MobileScannerPlatform.instance;
      MobileScannerPlatform.instance = _FakeScannerPlatform();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.tap(find.text('Register with QR code'));
        await tester.pumpAndSettle();

        expect(find.byType(MobileScanner), findsOneWidget);
        expect(find.text('Upload QR image'), findsOneWidget);
        expect(find.text('Generate QR'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        MobileScannerPlatform.instance = originalPlatform;
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

class _FakeScannerPlatform extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture>.broadcast();

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
