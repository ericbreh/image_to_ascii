import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

Future<String> convertImageToAsciiDart(
  String path, {
  int targetWidth = 150,
  int targetHeight = 75,
}) async {
  // Read file
  final Uint8List bytes = await File(path).readAsBytes();

  // Decode
  final ui.Codec codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final ui.FrameInfo frame = await codec.getNextFrame();
  final ui.Image img = frame.image;

  // Copy RGBA bytes once
  final ByteData bd =
      (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final Uint8List rgba = bd.buffer.asUint8List();

  // Loop in background isolate
  return compute(_rgbaToAscii, _AsciiPayload(rgba, img.width, img.height));
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
