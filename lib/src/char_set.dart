import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CharSet {
  static final _darkSet = ' .:-=+*#%@';
  static final _lightSet = '@%#*+=-:. ';

  static int get length => _darkSet.length;
  static String get lightMode => _lightSet;
  static String get darkMode => _darkSet;

  static Future<List<Uint8List>> generateGlyphCache(
    int height,
    TextStyle style,
  ) async {
    final List<Uint8List> alphaMasks = [];

    for (final char in _darkSet.split('')) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Set a fixed height and compute font size proportionally
      final tp = TextPainter(
        text: TextSpan(
          text: char,
          style: style.copyWith(color: Colors.white, fontSize: height * 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Determine width/height for image
      final width = tp.width.ceil();

      tp.paint(canvas, Offset(0, ((height - tp.height) / 2.0)));
      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);

      final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) continue;

      final Uint8List rgba = byteData.buffer.asUint8List();
      final Uint8List alphaOnly = Uint8List(width * height);

      for (int i = 0; i < alphaOnly.length; i++) {
        alphaOnly[i] = rgba[i * 4 + 3]; // extract alpha channel
      }

      alphaMasks.add(alphaOnly);
    }

    return alphaMasks;
  }

  // takes an 8 bit grayscale value and converts to a 4 bit value suitible to bit pack.
  // output integer is the index of the character in the dark set + 1
  static int encode(int val, bool dark) {
    // fix dark/light
    final int value = (dark ? val : 255 - val).clamp(0, 255);
    return ((value * (length - 1)) ~/ 255) + 1;
  }

  static String decode(int val) {
    return _darkSet[val - 1];
  }
}
