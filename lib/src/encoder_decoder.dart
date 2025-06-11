import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/src/bit_buffer.dart';
import 'package:image_to_ascii/src/char_set.dart';

int _getListLenght(int wh, bool color) {
  if (!color) {
    return wh * 5;
  } else {
    return wh * 15;
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
    _bitBuffer = BitBuffer(_getListLenght(width * height, color));
  }

  late final BitBuffer _bitBuffer;
  int? _prevChar;
  int? _prevColor;

  void addPixel(int grayVal, {int? colorVal}) {
    assert(
      !color || colorVal != null,
      'Color must be provided when encoding a color image',
    );

    //both of these will be null so no point in checking both
    //this should only happed for the first pixel
    if (_prevChar == null) {
      if (color) {
        _prevColor = colorVal!;
        _bitBuffer.addBits(colorVal, 8);
      }
      _prevChar = CharSet.encode(grayVal, dark);
      _bitBuffer.addBits(_prevChar!, 4);
      //first pixel will always be 0
      _bitBuffer.addBit(0);
      // print(bitsAdded);
      return;
    }

    // both colors will be null in black and white
    final didColorChange = _prevColor != colorVal;
    final didCharChange = _prevChar != CharSet.encode(grayVal, dark);
    if (didColorChange || didCharChange) {
      // notifiy of change
      _bitBuffer.addBit(1);

      //if not color just add the new char
      if (!color) {
        _prevChar = CharSet.encode(grayVal, dark);
        _bitBuffer.addBits(_prevChar!, 4);
        return;
      }

      // add two bit to tell what changed
      _bitBuffer.addBit(didColorChange ? 1 : 0);
      _bitBuffer.addBit(didCharChange ? 1 : 0);

      if (didColorChange) {
        _prevColor = colorVal!;
        _bitBuffer.addBits(colorVal, 8);
      }
      if (didCharChange) {
        _prevChar = CharSet.encode(grayVal, dark);
        _bitBuffer.addBits(_prevChar!, 4);
      }

      // print(bitsAdded);
      return;
    }
    //if nothing changed just add a 0
    _bitBuffer.addBit(0);
  }

  Uint8List encode() {
    final list = _bitBuffer.toUint8List();
    return list;
  }
}

class Decoder {
  final AsciiImage ascii;
  Decoder({required this.ascii});

  String convertToString() {
    if (ascii.version == 0) {
      return utf8.decode(ascii.data);
    }
    final bitArray = BitArray(ascii.data);
    final buf = StringBuffer();
    if (ascii.color) {
      bitArray.readBits(8);
    }

    String lastChar = CharSet.decode(bitArray.readBits(4));
    for (int j = 0; j < ascii.height!; j++) {
      for (int i = 0; i < ascii.width!; i++) {
        if (bitArray.readBit() == 1) {
          if (ascii.color) {
            final flags = bitArray.readBits(2);
            if (flags == 2) {
              bitArray.readBits(8);
              buf.write(lastChar);
              continue;
            }
            if (flags == 3) {
              bitArray.readBits(8);
            }
            lastChar = CharSet.decode(bitArray.readBits(4));
            buf.write(lastChar);
          } else {
            lastChar = CharSet.decode(bitArray.readBits(4));
            buf.write(lastChar);
          }
        } else {
          buf.write(lastChar);
        }
      }
      buf.writeln();
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

  List<InlineSpan> convertToTextSpans() {
    if (!ascii.color || ascii.version == 0) {
      return [TextSpan(text: ascii.toDisplayString())];
    }

    final bitArray = BitArray(ascii.data);

    final buf = StringBuffer();
    int lastColor = bitArray.readBits(8);
    String lastChar = CharSet.decode(bitArray.readBits(4));
    final List<InlineSpan> spans = [];

    for (int j = 0; j < ascii.height!; j++) {
      for (int i = 0; i < ascii.width!; i++) {
        // check if change bit happened
        if (bitArray.readBit() == 1) {
          final didColorChange = bitArray.readBit() == 1;
          final didCharChange = bitArray.readBit() == 1;

          //Color Changed
          if (didColorChange) {
            spans.add(
              TextSpan(
                text: buf.toString(),
                style: TextStyle(color: colorFromByte(lastColor)),
              ),
            );
            lastColor = bitArray.readBits(8);
            buf.clear();
          }
          // Char Changed
          if (didCharChange) {
            lastChar = CharSet.decode(bitArray.readBits(4));
          }
        }
        buf.write(lastChar);
      }
      buf.writeln();
    }

    if (buf.length != 0) {
      spans.add(
        TextSpan(
          text: buf.toString(),
          style: TextStyle(color: colorFromByte(lastColor)),
        ),
      );
    }
    return spans;
  }
}
