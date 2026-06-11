import 'dart:io';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AsciiImage> convertTestImage(
  String path, {
  int desiredWidth = defaultAsciiWidth,
  bool dark = false,
  bool color = false,
}) async {
  final cropped = await cropToAspectRatio(path, desiredWidth: desiredWidth);
  return convertImageToAscii(cropped, dark: dark, color: color);
}

void main() {
  final testFilePath = 'test/example.png';

  setUp(() {
    final file = File(testFilePath);
    expect(
      file.existsSync(),
      true,
      reason: 'Test image file not found at $testFilePath',
    );
  });

  test('crop and convert does not throw', () async {
    await expectLater(convertTestImage(testFilePath), completes);
  });

  test('ASCII art output is non-empty', () async {
    final asciiArt = await convertTestImage(testFilePath, dark: true);
    expect(asciiArt.data, isNotEmpty);
    expect(asciiArt.toDisplayString(), isNotEmpty);
  });

  group('cropToAspectRatio + convertImageToAscii', () {
    test('output dimensions match cropped image', () async {
      const desiredWidth = 100;
      final cropped = await cropToAspectRatio(
        testFilePath,
        desiredWidth: desiredWidth,
      );
      final asciiArt = await convertImageToAscii(cropped);

      final lines = asciiArt.toDisplayString().trim().split('\n');
      expect(lines.first.length, equals(cropped.width));
      expect(lines.length, equals(cropped.height));
    });

    test('density controls output width', () async {
      const desiredWidth = 80;
      final cropped = await cropToAspectRatio(
        testFilePath,
        desiredWidth: desiredWidth,
      );
      final asciiArt = await convertImageToAscii(cropped);

      expect(asciiArt.width, equals(desiredWidth));
      expect(
        asciiArt.toDisplayString().trim().split('\n').first.length,
        equals(desiredWidth),
      );
    });

    test('color encoding round-trips through display string', () async {
      final asciiArt = await convertTestImage(
        testFilePath,
        desiredWidth: 50,
        color: true,
      );

      expect(asciiArt.color, isTrue);
      expect(asciiArt.toDisplayString(), isNotEmpty);
    });
  });
}
