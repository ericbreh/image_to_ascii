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

  for (int y = 0; y < targetHeight!; y++) {
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

Future<String> convertImageToAsciiFromImage(
  ui.Image image, {
  bool darkMode = false,
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
  final chars = (darkMode) ? ' .:-=+*#%@' : '@%#*+=-:. ';
  final sb = StringBuffer();

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final i = (y * image.width + x) << 2;
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

  debugPrint('copy   : ${swCopy.elapsedMilliseconds} ms');
  debugPrint('ASCII  : ${swAscii.elapsedMilliseconds} ms');
  debugPrint('TOTAL  : ${swAll.elapsedMilliseconds} ms');

  return sb.toString();
}
