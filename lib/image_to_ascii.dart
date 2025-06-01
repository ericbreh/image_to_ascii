import 'image_to_ascii_platform_interface.dart';
import 'src/image_to_ascii_dart.dart';

class ImageToAscii {
  Future<String?> getPlatformVersion() {
    return ImageToAsciiPlatform.instance.getPlatformVersion();
  }

  /// Converts an image to ASCII art
  Future<String> convertImageToAscii(
    String path, {
    int? width,
    int? height,
    bool darkMode = false,
    bool color = false,
  }) async {
    return await convertImageToAsciiDart(
      path,
      width: width,
      height: height,
      darkMode: darkMode,
      color: color,
    );
  }
}
