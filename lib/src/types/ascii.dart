import 'dart:convert';

class Ascii {
  final int version;
  final String data;
  final int? height;
  final int? width;
  final bool dark;
  final bool hasColor;
  Ascii({
    required this.version,
    required this.data,
    this.height,
    this.width,
    required this.dark,
    required this.hasColor,
  });

  static Map<String, dynamic>? _parseJson(String s) {
    try {
      final obj = json.decode(s);
      if (obj is Map<String, dynamic>) {
        return obj;
      }
    } catch (_) {}
    return null;
  }

  static Ascii fromJsonV1(Map<String, dynamic> json) {
    final data = json['data'];
    return Ascii(
      version: 1,
      data: data,
      dark: json['dark'] ?? true,
      hasColor: json['hasColor'],
      width: json['width'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'data': data,
      'hasColor': hasColor,
      'dark': dark,
      'width': width,
      'height': height,
    };
  }

  static Ascii fromString(String string) {
    final json = _parseJson(string);
    if (json == null) {
      return Ascii(version: 0, data: string, dark: true, hasColor: false);
    }
    return Ascii.fromJsonV1(json);
  }
}
