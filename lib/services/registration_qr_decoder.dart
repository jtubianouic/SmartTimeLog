import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

String decodeRegistrationQrImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('The selected file is not an image.');
  }
  try {
    final pixels = image
        .convert(numChannels: 4)
        .getBytes(order: img.ChannelOrder.abgr)
        .buffer
        .asInt32List();
    final source = RGBLuminanceSource(image.width, image.height, pixels);
    return QRCodeReader()
        .decode(BinaryBitmap(GlobalHistogramBinarizer(source)))
        .text;
  } on Object {
    throw const FormatException('No readable QR code was found in that image.');
  }
}

String decodeRegistrationQrDataUrl(String dataUrl) {
  const prefix = 'data:image/png;base64,';
  if (!dataUrl.startsWith(prefix)) {
    throw const FormatException('The server returned an invalid QR image.');
  }
  try {
    return decodeRegistrationQrImage(
      base64Decode(dataUrl.substring(prefix.length)),
    );
  } on FormatException {
    throw const FormatException('The server returned an unreadable QR image.');
  }
}
