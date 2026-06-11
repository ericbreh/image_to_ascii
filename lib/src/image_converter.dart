import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/src/encoder_decoder.dart';

Future<AsciiImage> convertImageToAscii(
  ui.Image image, {
  bool dark = false,
  bool color = false,
}) async {
  final ByteData bd =
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final Uint8List rgba = bd.buffer.asUint8List();

  final en = Encoder(
    dark: dark,
    color: color,
    width: image.width,
    height: image.height,
  );

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final i = (y * image.width + x) << 2;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
      int? pixelColor;
      if (color) {
        final rVal = (r * 8 / 256).floor();
        final gVal = (g * 8 / 256).floor();
        final bVal = (b * 4 / 256).floor();

        pixelColor = (rVal << 5) | (gVal << 2) | bVal;
      }
      en.addPixel(gray, colorVal: pixelColor);
    }
  }

  return AsciiImage(
    version: 1,
    data: en.encode(),
    color: color,
    dark: dark,
    width: image.width,
    height: image.height,
  );
}
