import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

Future<String> convertImageToAsciiDart(
  String path, {
  int? width,
  int? height,
  bool darkMode = false,
}) async {
  final swAll = Stopwatch()..start();

  // Read file
  final swRead = Stopwatch()..start();
  final Uint8List bytes = await File(path).readAsBytes();
  swRead.stop();

  // Calculate dimensions based on parameters
  int targetWidth;
  int targetHeight;

  if (width != null && height != null) {
    // Both dimensions provided - use as is without calculating aspect ratio
    targetWidth = width;
    targetHeight = height;
  } else {
    // Need to calculate aspect ratio for the remaining cases
    final swOrigDims = Stopwatch()..start();
    final ui.Codec infoCodec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo infoFrame = await infoCodec.getNextFrame();
    final ui.Image infoImg = infoFrame.image;
    final double aspectRatio = infoImg.width / infoImg.height;
    swOrigDims.stop();
    debugPrint('get dims: ${swOrigDims.elapsedMilliseconds} ms');

    if (width != null) {
      // Only width provided - calculate height from aspect ratio
      targetWidth = width;
      targetHeight = (targetWidth / aspectRatio).round();
    } else if (height != null) {
      // Only height provided - calculate width from aspect ratio
      targetHeight = height;
      targetWidth = (targetHeight * aspectRatio).round();
    } else {
      // Neither provided - default to width=150 and calculate height
      targetWidth = 150;
      targetHeight = (targetWidth / aspectRatio).round();
    }
  }

  // Decode
  final swDecode = Stopwatch()..start();
  final ui.Codec codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final ui.FrameInfo frame = await codec.getNextFrame();
  final ui.Image img = frame.image;
  swDecode.stop();

  // Copy RGBA bytes
  final swCopy = Stopwatch()..start();
  final ByteData bd =
      (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final Uint8List rgba = bd.buffer.asUint8List();
  swCopy.stop();

  // ASCII conversion
  final swAscii = Stopwatch()..start();
  final chars = (darkMode) ? ' .:-=+*#%@' : '@%#*+=-:. ';
  final sb = StringBuffer();

  for (int y = 0; y < targetHeight; y++) {
    for (int x = 0; x < targetWidth; x++) {
      final i = (y * targetWidth + x) << 2; // 4 bytes per pixel
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
      sb.write(chars[(gray * (chars.length - 1)) ~/ 255]);
    }
    sb.writeln();
  }
  swAscii.stop();

  swAll.stop();

  debugPrint('read   : ${swRead.elapsedMilliseconds} ms');
  debugPrint('decode : ${swDecode.elapsedMilliseconds} ms');
  debugPrint('copy   : ${swCopy.elapsedMilliseconds} ms');
  debugPrint('ASCII  : ${swAscii.elapsedMilliseconds} ms');
  debugPrint('TOTAL  : ${swAll.elapsedMilliseconds} ms');

  return sb.toString();
}
