import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testFilePath = 'test/example.png';

  setUp(() {
    // Ensure test file exists
    final file = File(testFilePath);
    expect(
      file.existsSync(),
      true,
      reason: 'Test image file not found at $testFilePath',
    );
  });

  test('Basic Dart conversion does not throw', () async {
    await expectLater(
      convertImageToAscii(testFilePath, width: 150, height: 75),
      completes,
    );
  });

  test('Print ASCII art output', () async {
    // Get and print the ASCII art
    final asciiArt = await convertImageToAscii(testFilePath, dark: true);
    print(asciiArt);

    // Basic validation
    expect(asciiArt, isNotEmpty);
  });

  group('Aspect ratio preservation tests', () {
    late double originalAspectRatio;

    setUpAll(() async {
      // Get the original image's aspect ratio for comparison
      final bytes = await File(testFilePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      originalAspectRatio = img.width / img.height;

      print('Original image aspect ratio: $originalAspectRatio');
    });

    test(
      'Both width and height provided (no aspect ratio preservation)',
      () async {
        const int width = 80;
        const int height = 40;

        final asciiArt = await convertImageToAscii(
          testFilePath,
          width: width,
          height: height,
        );

        // Count width (characters in first line) and height (number of lines)
        final lines = asciiArt.trim().split('\n');
        final actualHeight = lines.length;
        final actualWidth = lines.first.length;

        expect(
          actualWidth,
          equals(width),
          reason: 'ASCII art width should match specified width',
        );
        expect(
          actualHeight,
          equals(height),
          reason: 'ASCII art height should match specified height',
        );

        // Calculate actual aspect ratio in the ASCII art
        final asciiAspectRatio = actualWidth / actualHeight;
        print('ASCII aspect ratio with both params: $asciiAspectRatio');

        // When both dimensions are specified, aspect ratio can be different
        expect(
          asciiAspectRatio,
          isNot(closeTo(originalAspectRatio, 0.1)),
          reason:
              'Aspect ratio should not be preserved when both dimensions are specified',
        );
      },
    );

    test('Only width provided (height calculated from aspect ratio)', () async {
      const int width = 100;

      final asciiArt = await convertImageToAscii(testFilePath, width: width);

      final lines = asciiArt.trim().split('\n');
      final actualHeight = lines.length;
      final actualWidth = lines.first.length;

      expect(
        actualWidth,
        equals(width),
        reason: 'ASCII art width should match specified width',
      );

      // Expected height based on original aspect ratio
      final expectedHeight = (width / originalAspectRatio).round();
      expect(
        actualHeight,
        equals(expectedHeight),
        reason: 'ASCII art height should be calculated from aspect ratio',
      );

      // Verify aspect ratio is preserved
      final asciiAspectRatio = actualWidth / actualHeight;
      print('ASCII aspect ratio with only width: $asciiAspectRatio');
      expect(
        asciiAspectRatio,
        closeTo(originalAspectRatio, 0.1),
        reason: 'Aspect ratio should be preserved when only width is specified',
      );
    });

    test('Only height provided (width calculated from aspect ratio)', () async {
      const int height = 50;

      final asciiArt = await convertImageToAscii(testFilePath, height: height);

      final lines = asciiArt.trim().split('\n');
      final actualHeight = lines.length;
      final actualWidth = lines.first.length;

      expect(
        actualHeight,
        equals(height),
        reason: 'ASCII art height should match specified height',
      );

      // Expected width based on original aspect ratio
      final expectedWidth = (height * originalAspectRatio).round();
      expect(
        actualWidth,
        equals(expectedWidth),
        reason: 'ASCII art width should be calculated from aspect ratio',
      );

      // Verify aspect ratio is preserved
      final asciiAspectRatio = actualWidth / actualHeight;
      print('ASCII aspect ratio with only height: $asciiAspectRatio');
      expect(
        asciiAspectRatio,
        closeTo(originalAspectRatio, 0.1),
        reason:
            'Aspect ratio should be preserved when only height is specified',
      );
    });

    test(
      'Neither width nor height provided (default width with aspect ratio)',
      () async {
        final asciiArt = await convertImageToAscii(testFilePath);

        final lines = asciiArt.trim().split('\n');
        final actualHeight = lines.length;
        final actualWidth = lines.first.length;

        expect(
          actualWidth,
          equals(150),
          reason: 'ASCII art should use default width of 150',
        );

        // Expected height based on original aspect ratio
        final expectedHeight = (150 / originalAspectRatio).round();
        expect(
          actualHeight,
          equals(expectedHeight),
          reason: 'ASCII art height should be calculated from aspect ratio',
        );

        // Verify aspect ratio is preserved
        final asciiAspectRatio = actualWidth / actualHeight;
        print('ASCII aspect ratio with default params: $asciiAspectRatio');
        expect(
          asciiAspectRatio,
          closeTo(originalAspectRatio, 0.1),
          reason: 'Aspect ratio should be preserved with default parameters',
        );
      },
    );
  });
}
