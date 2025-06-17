class CharSet {
  static final _darkSet = ' .:-=+*#%@';
  static final _lightSet = '@%#*+=-:. ';

  static int get length => _darkSet.length;
  static String get lightMode => _lightSet;
  static String get darkMode => _darkSet;

  // static Future<List<ui.Image>>? _glyphCache;

  // static Future<List<ui.Image>> getGlyphCache({TextStyle? style}) {
  //   _glyphCache ??= _generateGlyphCache(
  //     _darkSet.split(''),
  //     style ?? defaultTextStyle,
  //   );
  //   return _glyphCache!;
  // }
  //
  // static Future<List<ui.Image>> _generateGlyphCache(
  //   List<String> chars,
  //   TextStyle style,
  // ) async {
  //   final cache = <ui.Image>[];
  //   for (final char in chars) {
  //     final recorder = ui.PictureRecorder();
  //     final canvas = Canvas(recorder);
  //     final tp = TextPainter(
  //       text: TextSpan(text: char, style: style.copyWith(color: Colors.white)),
  //       textDirection: TextDirection.ltr,
  //     )..layout();
  //
  //     tp.paint(canvas, Offset.zero);
  //     final picture = recorder.endRecording();
  //     final img = await picture.toImage(tp.width.ceil(), tp.height.ceil());
  //     cache.add(img);
  //   }
  //   return cache;
  // }

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
