import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/src/encoder_decoder.dart';

Future<AsciiImage> convertImagePathToAscii(
  String path, {
  int? width,
  int? height,
  bool dark = false,
  bool color = false,
  double charAspectRatio = 0.75,
}) async {
  final swAll = Stopwatch()..start();

  // Read file
  final swRead = Stopwatch()..start();
  final Uint8List bytes = await File(path).readAsBytes();
  swRead.stop();

  // Determine dimensions
  int? targetWidth;
  int? targetHeight;

  final descriptor = await ui.ImageDescriptor.encoded(
    await ui.ImmutableBuffer.fromUint8List(bytes),
  );

  targetWidth = width;
  targetHeight = height;
  if ((width == null) || (height == null)) {
    final w = descriptor.width;
    final h = descriptor.height;
    final currentAspectRatio = (w / h) / charAspectRatio;
    if (height != null) {
      targetWidth = (height * currentAspectRatio).round();
    } else {
      targetWidth = width ?? 150;
      targetHeight = (targetWidth / currentAspectRatio).round();
    }
  }

  // Decode
  final swDecode = Stopwatch()..start();
  final ui.Codec codec = await descriptor.instantiateCodec(
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final ui.FrameInfo frame = await codec.getNextFrame();
  final ui.Image img = frame.image;
  swDecode.stop();

  final res = await convertImageToAscii(img, dark: dark, color: color);

  swAll.stop();

  debugPrint('read   : ${swRead.elapsedMilliseconds} ms');
  debugPrint('decode : ${swDecode.elapsedMilliseconds} ms');
  debugPrint('TOTAL  : ${swAll.elapsedMilliseconds} ms');

  return res;
}

Future<AsciiImage> convertImageToAscii(
  ui.Image image, {
  bool dark = false,
  bool color = false,
}) async {
  final swAll = Stopwatch()..start();

  // Get RGBA
  final swCopy = Stopwatch()..start();
  final ByteData bd =
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final Uint8List rgba = bd.buffer.asUint8List();
  swCopy.stop();

  // ASCII conversion
  final swAscii = Stopwatch()..start();
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
        int rVal = (r * 8 / 256).floor();
        int gVal = (g * 8 / 256).floor();
        int bVal = (b * 4 / 256).floor();

        pixelColor = (rVal << 5) | (gVal << 2) | bVal;
      }
      en.addPixel(gray, colorVal: pixelColor);
    }
  }
  swAscii.stop();

  swAll.stop();
  debugPrint('copy   : ${swCopy.elapsedMilliseconds} ms');
  debugPrint('ASCII  : ${swAscii.elapsedMilliseconds} ms');
  debugPrint('TOTAL  : ${swAll.elapsedMilliseconds} ms');

  return AsciiImage(
    version: 1,
    data: en.encode(),
    color: color,
    dark: dark,
    width: image.width,
    height: image.height,
  );
}
