import 'dart:io';
import 'package:image/image.dart';

void convertImageToAscii(String imagePath) {
  try {
    // Load the image
    final bytes = File(imagePath).readAsBytesSync();
    final image = decodeImage(bytes);

    if (image == null) {
      print('Could not decode image');
      return;
    }

    // Resize image
    final resizedImage = copyResize(image, width: 100);

    // ASCII character set from darkest to lightest
    final asciiChars = '@%#*+=-:. ';

    // Convert each pixel to an ASCII character
    for (int y = 0; y < resizedImage.height; y++) {
      String line = '';
      for (int x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Calculate grayscale value
        final grayscale =
            (getRed(pixel) + getGreen(pixel) + getBlue(pixel)) ~/ 3;

        // Map grayscale value to ASCII character
        final index = ((grayscale / 255) * (asciiChars.length - 1)).round();
        line += asciiChars[index];
      }
      print(line);
    }
  } catch (e) {
    print('Error: $e');
  }
}
