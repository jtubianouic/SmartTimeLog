import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smarttimelog/services/registration_qr_decoder.dart';
import 'package:zxing2/qrcode.dart';

void main() {
  test('decodes an uploaded QR image and the API PNG data URL', () {
    final token = List.filled(64, 'a').join();
    final matrix = Encoder.encode(token, ErrorCorrectionLevel.h).matrix!;
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
    final bytes = Uint8List.fromList(img.encodePng(image));
    expect(decodeRegistrationQrImage(bytes), token);
    expect(
      decodeRegistrationQrDataUrl(
        'data:image/png;base64,${base64Encode(bytes)}',
      ),
      token,
    );
  });
}
