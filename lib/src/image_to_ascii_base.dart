import 'package:image/image.dart';

String convertImageToAsciiDart(Image image) {
  // Resize image
  final resizedImage = copyResize(image, width: 150, height: 75);

  // ASCII character set from darkest to lightest
  final asciiChars = '@%#*+=-:. ';

  final buffer = StringBuffer();

  // Convert each pixel to an ASCII character
  for (int y = 0; y < resizedImage.height; y++) {
    String line = '';
    for (int x = 0; x < resizedImage.width; x++) {
      final pixel = resizedImage.getPixel(x, y);

      // Calculate grayscale value
      final grayscale = (getRed(pixel) + getGreen(pixel) + getBlue(pixel)) ~/ 3;

      // Map grayscale value to ASCII character
      final index = ((grayscale / 255) * (asciiChars.length - 1)).round();
      line += asciiChars[index];
    }
    buffer.writeln(line);
  }
  return buffer.toString();
}
