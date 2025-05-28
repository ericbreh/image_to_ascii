import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

Future<String> convertImageToAsciiDart({
  required String path,
  int width = 150,
  int height = 75,
  bool darkMode = false,
}) async {
  final swAll = Stopwatch()..start();

  // Read file
  final swRead = Stopwatch()..start();
  final Uint8List bytes = await File(path).readAsBytes();
  swRead.stop();

  // Decode
  final swDecode = Stopwatch()..start();
  final ui.Codec codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: width,
    targetHeight: height,
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

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final i = (y * width + x) << 2; // 4 bytes per pixel
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
