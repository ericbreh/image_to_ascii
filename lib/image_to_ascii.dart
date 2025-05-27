import 'image_to_ascii_platform_interface.dart';
import 'src/image_to_ascii_dart.dart';

class ImageToAscii {
  Future<String?> getPlatformVersion() {
    return ImageToAsciiPlatform.instance.getPlatformVersion();
  }

  Future<String> convertImageToAscii(String path) async {
    /// Dart-based fallback
    return await convertImageToAsciiDart(path);
  }
}
