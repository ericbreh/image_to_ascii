import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_to_ascii_platform_interface.dart';

/// An implementation of [ImageToAsciiPlatform] that uses method channels.
class MethodChannelImageToAscii extends ImageToAsciiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_to_ascii');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
