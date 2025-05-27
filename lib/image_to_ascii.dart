import 'image_to_ascii_platform_interface.dart';
import 'src/image_to_ascii_dart.dart';

class ImageToAscii {
  Future<String?> getPlatformVersion() {
    return ImageToAsciiPlatform.instance.getPlatformVersion();
  }

  /// Converts an image to ASCII art
  Future<String> convertImageToAscii(
    String path, {
    int width = 150,
    int height = 75,
  }) async {
    return await convertImageToAsciiDart(
      path: path,
      width: width,
      height: height,
    );
  }
}
