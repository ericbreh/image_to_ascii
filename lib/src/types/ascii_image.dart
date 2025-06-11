import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_to_ascii/src/encoder_decoder.dart';

int crc16Ibm(Uint8List data, {int offset = 0, int length = -1}) {
  int polynomial = 0x8005;
  int crc = 0x0000; // Initial value for CRC-16-IBM

  if (length == -1) {
    length = data.length - offset;
  }

  for (int i = offset; i < offset + length; i++) {
    crc ^= (data[i] << 8);
    for (int j = 0; j < 8; j++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ polynomial) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc;
}

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
    _decoder = Decoder(ascii: this);
  }

  late final Decoder _decoder;

  static AsciiImage unsupportedVersion() {
    return AsciiImage(
      color: false,
      dark: true,
      data: Uint8List.fromList([]),
      version: 0xFF,
    );
  }

  static AsciiImage fromSimpleString(String string) {
    return AsciiImage(
      version: 0,
      data: utf8.encode(string),
      dark: true,
      color: false,
    );
  }

  // 1 Byte version
  // 1 Byte bools
  //   lsb: dark
  //   lsb + 1: color
  // 2 Bytes width
  // 2 Bytes height
  String toStorableString() {
    final header = Uint8List(8);
    final bd = ByteData.view(header.buffer);

    bd.setUint8(0, version);

    int bools = 0;
    if (dark) bools |= 1;
    if (color) bools |= 1 << 1;
    bd.setUint8(1, bools);

    bd.setUint16(2, width!, Endian.big);
    bd.setUint16(4, height!, Endian.big);

    // checksum placeholder at bytes 6,7
    bd.setUint16(6, 0, Endian.big);

    // Combine header + data
    final combined = Uint8List(header.length + data.length);
    combined.setRange(0, header.length, header);
    combined.setRange(header.length, combined.length, data);

    // Calculate checksum on first 6 bytes (version to height)
    final checksum = crc16Ibm(combined, length: 6);

    // Write checksum into combined bytes at position 6 and 7
    combined[6] = (checksum >> 8) & 0xFF;
    combined[7] = checksum & 0xFF;

    return base64Encode(combined);
  }

  static AsciiImage fromStorableString(String string) {
    try {
      final bytes = base64Decode(string);
      if (bytes[0] > 1) {
        return AsciiImage.unsupportedVersion();
      }
      final expectedChecksum = (bytes[6] << 8) | bytes[7];
      final calculatedChecksum = crc16Ibm(bytes, length: 6);
      // assume basic string
      if (expectedChecksum != calculatedChecksum) {
        return AsciiImage.fromSimpleString(string);
      }
      final version = bytes[0];
      final bools = bytes[1];
      final dark = (bools & 1) == 1;
      final color = ((bools >> 1) & 1) == 1;
      final width = (bytes[2] << 8) | bytes[3];
      final height = (bytes[4] << 8) | bytes[5];
      return AsciiImage(
        version: version,
        dark: dark,
        color: color,
        width: width,
        height: height,
        data: bytes.sublist(8),
      );
    } catch (_) {}
    return AsciiImage.fromSimpleString(string);
  }

  String toDisplayString() {
    if (version <= 1) {
      return _decoder.convertToString();
    }
    return super.toString();
  }

  List<InlineSpan> toTextSpans() {
    return _decoder.convertToTextSpans();
  }

  @override
  String toString() {
    return 'version: $version width: $width, height: $height, color: $color, dark: $dark\n${toDisplayString()}';
  }
}
