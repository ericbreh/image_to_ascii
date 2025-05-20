
import 'image_to_ascii_platform_interface.dart';

class ImageToAscii {
  Future<String?> getPlatformVersion() {
    return ImageToAsciiPlatform.instance.getPlatformVersion();
  }
}
