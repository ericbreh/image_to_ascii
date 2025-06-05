import 'dart:typed_data';

class CharSet {
  static final _darkSet = ' .:-=+*#%@';
  static final _lightSet = '@%#*+=-:. ';

  static int get length => _darkSet.length;
  static String get lightMode => _lightSet;
  static String get darkMode => _darkSet;

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
  final bool dark;
  final bool color;
  final int width;
  final int height;
  Decoder({
    required this.dark,
    required this.color,
    required this.width,
    required this.height,
  });

  String convertToString(Uint8List data) {
    int currentWidth = 0;
    int colorBit = 0;
    final buf = StringBuffer();
    for (final int in data) {
      if (color) {
        if (colorBit == 0 || colorBit == 1) {
          colorBit++;
          continue;
        } else {
          colorBit = 0;
        }
      }

      buf.write(CharSet.decode(int >> 4));
      currentWidth++;
      if (currentWidth == width) {
        buf.writeln();
        currentWidth = 0;
      }
      if (int & 15 != 0) {
        buf.write(CharSet.decode(int & 15));
        currentWidth++;
        if (currentWidth == width) {
          buf.writeln();
          currentWidth = 0;
        }
      }
    }
    return buf.toString();
  }
}
