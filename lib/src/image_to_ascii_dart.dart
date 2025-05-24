import 'package:image/image.dart';

// String convertImageToAsciiDart(
//   Image image, {
//   int width = 150,
//   int height = 75,
// }) {
//   // Resize image
//   final resizedImage = copyResize(image, width: width, height: height);

//   // ASCII character set from darkest to lightest
//   final asciiChars = '@%#*+=-:. ';

//   final buffer = StringBuffer();
//   final lineBuffer = StringBuffer();

//   // Convert each pixel to an ASCII character
//   for (int y = 0; y < resizedImage.height; y++) {
//     lineBuffer.clear();
//     for (int x = 0; x < resizedImage.width; x++) {
//       final pixel = resizedImage.getPixel(x, y);

//       // Calculate grayscale value
//       final grayscale = (getRed(pixel) + getGreen(pixel) + getBlue(pixel)) ~/ 3;

//       // Map grayscale value to ASCII character
//       final index = ((grayscale / 255) * (asciiChars.length - 1)).round();
//       lineBuffer.write(asciiChars[index]);
//     }
//     buffer.writeln(lineBuffer.toString());
//   }
//   return buffer.toString();
// }

String convertImageToAsciiDart(
  Image image, {
  int width = 150,
  int height = 75,
}) {
  final targetWidth = width;
  final targetHeight = height;

  const asciiChars = '@%#*+=-:. ';
  final numChars = asciiChars.length - 1;

  final buffer = StringBuffer();
  final lineBuffer = StringBuffer();

  // Calculate scaling factors
  final xStep = image.width / targetWidth;
  final yStep = image.height / targetHeight;

  for (int y = 0; y < targetHeight; y++) {
    lineBuffer.clear();
    final srcY = (y * yStep).round().clamp(0, image.height - 1);

    for (int x = 0; x < targetWidth; x++) {
      final srcX = (x * xStep).round().clamp(0, image.width - 1);

      final pixel = image.getPixel(srcX, srcY);

      // Calculate grayscale value
      final grayscale =
          (0.299 * getRed(pixel) +
                  0.587 * getGreen(pixel) +
                  0.114 * getBlue(pixel))
              .round();

      // Map grayscale value to ASCII character
      final index = ((grayscale * numChars) ~/ 255);
      lineBuffer.write(asciiChars[index]);
    }
    buffer.writeln(lineBuffer.toString());
  }
  return buffer.toString();
}
