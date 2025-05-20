import 'package:image/image.dart';
import 'image_to_ascii_platform_interface.dart';
import 'src/image_to_ascii_base.dart';

class ImageToAscii {
  Future<String?> getPlatformVersion() {
    return ImageToAsciiPlatform.instance.getPlatformVersion();
  }

  /// Use Dart-based fallback for now.
  String convertImageToAscii(Image image) {
    // You can swap this with platform call later
    return convertImageToAsciiDart(image);
  }
}
