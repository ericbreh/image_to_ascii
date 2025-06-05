import 'dart:convert';
import 'dart:typed_data';

import 'package:image_to_ascii/src/encoder_decoder.dart';

class AsciiImage {
  final int version;
  final Uint8List data;
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
  }) {
    assert(!(version == 1 && (width == null || height == null)));
    if (version == 1) {
      _decoder = Decoder(
        dark: dark,
        color: color,
        width: width!,
        height: height!,
      );
    }
  }

  late final Decoder _decoder;

  static Map<String, dynamic>? _parseJson(String s) {
    try {
      final obj = json.decode(s);
      if (obj is Map<String, dynamic>) {
        return obj;
      }
    } catch (_) {}
    return null;
  }

  static AsciiImage fromV1Json(Map<String, dynamic> json) {
    final data = base64Decode(json['data'] ?? '');
    return AsciiImage(
      version: json['version'],
      data: data,
      dark: json['dark'] ?? true,
      color: json['color'],
      width: json['width'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'color': color,
      'dark': dark,
      'width': width,
      'height': height,
      'data': base64Encode(data),
    };
  }

  static AsciiImage fromV0String(String string) {
    return AsciiImage(
      version: 0,
      data: utf8.encode(string),
      dark: true,
      color: false,
    );
  }

  static AsciiImage fromString(String string) {
    final json = _parseJson(string);
    if (json == null) {
      return AsciiImage.fromV0String(string);
    }
    return AsciiImage.fromV1Json(json);
  }

  @override
  String toString() {
    if (version == 0) {
      return utf8.decode(data);
    }
    if (version == 1) {
      return _decoder.convertToString(data);
    }
    return super.toString();
  }
}
