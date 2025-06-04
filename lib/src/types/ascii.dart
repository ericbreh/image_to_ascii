import 'dart:convert';

class AsciiImage {
  final int version;
  final String data;
  final int? height;
  final int? width;
  final bool dark;
  final bool color;
  AsciiImage({
    required this.version,
    required this.data,
    this.height,
    this.width,
    required this.dark,
    required this.color,
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

  static AsciiImage fromJsonV1(Map<String, dynamic> json) {
    final data = json['data'];
    return AsciiImage(
      version: 1,
      data: data,
      dark: json['dark'] ?? true,
      color: json['color'],
      width: json['width'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'data': data,
      'color': color,
      'dark': dark,
      'width': width,
      'height': height,
    };
  }

  static AsciiImage fromString(String string) {
    final json = _parseJson(string);
    if (json == null) {
      return AsciiImage(version: 0, data: string, dark: true, color: false);
    }
    return AsciiImage.fromJsonV1(json);
  }
}
