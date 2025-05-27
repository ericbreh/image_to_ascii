import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

Future<String> convertImageToAsciiDart({
  required String path,
  int width = 150,
  int height = 75,
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

  // Copy RGBA bytes once
  final swCopy = Stopwatch()..start();
  final ByteData bd =
      (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final Uint8List rgba = bd.buffer.asUint8List();
  swCopy.stop();

  // ASCII conversion
  // return compute(_rgbaToAscii, _AsciiPayload(rgba, img.width, img.height));
  final swAscii = Stopwatch()..start();
  final ascii = _rgbaToAscii(_AsciiPayload(rgba, img.width, img.height));
  swAscii.stop();

  swAll.stop();

  debugPrint('read   : ${swRead.elapsedMilliseconds} ms');
  debugPrint('decode : ${swDecode.elapsedMilliseconds} ms');
  debugPrint('copy   : ${swCopy.elapsedMilliseconds} ms');
  debugPrint('ASCII  : ${swAscii.elapsedMilliseconds} ms');
  debugPrint('TOTAL  : ${swAll.elapsedMilliseconds} ms');

  return ascii;
}

class _AsciiPayload {
  final Uint8List buf;
  final int w, h;
  const _AsciiPayload(this.buf, this.w, this.h);
}

String _rgbaToAscii(_AsciiPayload p) {
  const chars = '@%#*+=-:. ';
  final sb = StringBuffer();

  for (int y = 0; y < p.h; y++) {
    for (int x = 0; x < p.w; x++) {
      final i = (y * p.w + x) << 2; // 4 bytes per pixel
      final r = p.buf[i];
      final g = p.buf[i + 1];
      final b = p.buf[i + 2];
      final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
      sb.write(chars[(gray * (chars.length - 1)) ~/ 255]);
    }
    sb.writeln();
  }
  return sb.toString();
}
