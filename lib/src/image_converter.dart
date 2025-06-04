import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

Future<String> convertImageToAscii(
  String path, {
  int? width,
  int? height,
  bool darkMode = false,
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

  if (width != null && height != null) {
    targetWidth = width;
    targetHeight = height;
  } else {
    if (height != null) {
      targetHeight = height;
    } else {
      targetWidth = width ?? 150;
    }
    final ui.Codec preCodec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final ui.FrameInfo frame = await preCodec.getNextFrame();
    final ui.Image preImg = frame.image;
    if (targetHeight == null) {
      targetHeight = (preImg.height * charAspectRatio).round();
    } else {
      targetWidth = (preImg.width / charAspectRatio).round();
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

  // Get RGBA
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
    for (int x = 0; x < targetWidth!; x++) {
      final i = (y * targetWidth + x) << 2;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
      final ch = chars[(gray * (chars.length - 1)) ~/ 255];

      if (color) {
        final hex =
            r.toRadixString(16).padLeft(2, '0') +
            g.toRadixString(16).padLeft(2, '0') +
            b.toRadixString(16).padLeft(2, '0');
        sb.write('[#${hex.toUpperCase()}]$ch');
      } else {
        sb.write(ch);
      }
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
