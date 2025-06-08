import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/src/char_set.dart';

int _getListLenght(int wh, bool color) {
  if (!color) {
    return (wh + 1) ~/ 2;
  } else {
    // no need for comment
    return (((((wh * 3) + 1) ~/ 2) + 2) ~/ 3) * 3;
  }
}

class Encoder {
  final bool dark;
  final bool color;
  final int width;
  final int height;
  Encoder({
    required this.dark,
    required this.color,
    required this.width,
    required this.height,
  }) {
    _list = Uint8List(_getListLenght(width * height, color));
  }

  late final Uint8List _list;
  int _listPos = 0;

  _addToList(int item) {
    _list[_listPos++] = item;
  }

  // = Uint8List(_getListLenght(width * height, color));
  int? _pixel;

  void addPixel(int grayVal, {int? colorVal}) {
    assert(
      !color || colorVal != null,
      'Color must be provided when encoding a color image',
    );

    if (color) {
      _addToList(colorVal!);
    }

    if (_pixel == null) {
      _pixel = CharSet.encode(grayVal, dark);
    } else {
      _addToList(_pixel! << 4 | CharSet.encode(grayVal, dark));
      _pixel = null;
    }
  }

  Uint8List encode() {
    if (_pixel != null) {
      if (color) {
        //null color
        _addToList(0);
      }
      _addToList(_pixel! << 4);
    }
    return _list;
  }

  void reset() {
    _pixel = null;
    _list.clear();
    _listPos = 0;
  }
}

class Decoder {
  final AsciiImage ascii;
  Decoder({required this.ascii});

  String convertToString(Uint8List data) {
    int currentWidth = 0;
    int colorBit = 0;
    final buf = StringBuffer();
    for (final int in data) {
      if (ascii.color) {
        if (colorBit == 0 || colorBit == 1) {
          colorBit++;
          continue;
        } else {
          colorBit = 0;
        }
      }

      buf.write(CharSet.decode(int >> 4));
      currentWidth++;
      if (currentWidth == ascii.width) {
        buf.writeln();
        currentWidth = 0;
      }
      if (int & 15 != 0) {
        buf.write(CharSet.decode(int & 15));
        currentWidth++;
        if (currentWidth == ascii.width) {
          buf.writeln();
          currentWidth = 0;
        }
      }
    }
    return buf.toString();
  }

  Color colorFromByte(int byte) {
    // Extract color components from packed byte
    int rVal = (byte >> 5) & 0x7;
    int gVal = (byte >> 2) & 0x7;
    int bVal = byte & 0x3;

    // Scale back to 0-255 range
    int r = (rVal * 255 / 7).round();
    int g = (gVal * 255 / 7).round();
    int b = (bVal * 255 / 3).round();

    return Color.fromARGB(255, r, g, b);
  }

  List<InlineSpan> convertToTextSpans(Uint8List data) {
    if (!ascii.color || ascii.version == 0) {
      return [TextSpan(text: ascii.toDisplayString())];
    }
    int currentWidth = 0;
    int colorBit = 0;
    final spans = <InlineSpan>[];
    Color? color1, color2;

    StringBuffer buffer = StringBuffer();
    Color? lastColor;

    void flushBuffer(Color? color) {
      if (buffer.isNotEmpty) {
        spans.add(
          TextSpan(text: buffer.toString(), style: TextStyle(color: color)),
        );
        buffer.clear();
      }
    }

    for (final byte in data) {
      if (colorBit == 0) {
        colorBit++;
        color1 = colorFromByte(byte);
        continue;
      } else if (colorBit == 1) {
        colorBit++;
        color2 = colorFromByte(byte);
        continue;
      } else {
        colorBit = 0;
      }

      // High nibble
      final highChar = CharSet.decode(byte >> 4);
      if (lastColor != color1) {
        flushBuffer(lastColor);
        lastColor = color1;
      }
      buffer.write(highChar);
      currentWidth++;
      if (currentWidth == ascii.width) {
        flushBuffer(lastColor);
        spans.add(const TextSpan(text: '\n'));
        currentWidth = 0;
      }

      // Low nibble (only if not 0)
      final lowNibble = byte & 0x0F;
      if (lowNibble != 0) {
        final lowChar = CharSet.decode(lowNibble);
        if (lastColor != color2) {
          flushBuffer(lastColor);
          lastColor = color2;
        }
        buffer.write(lowChar);
        currentWidth++;
        if (currentWidth == ascii.width) {
          flushBuffer(lastColor);
          spans.add(const TextSpan(text: '\n'));
          currentWidth = 0;
        }
      }
    }

    flushBuffer(lastColor);
    return spans;
  }
}
