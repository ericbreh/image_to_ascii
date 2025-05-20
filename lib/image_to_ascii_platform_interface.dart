import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_to_ascii_method_channel.dart';

abstract class ImageToAsciiPlatform extends PlatformInterface {
  /// Constructs a ImageToAsciiPlatform.
  ImageToAsciiPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImageToAsciiPlatform _instance = MethodChannelImageToAscii();

  /// The default instance of [ImageToAsciiPlatform] to use.
  ///
  /// Defaults to [MethodChannelImageToAscii].
  static ImageToAsciiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImageToAsciiPlatform] when
  /// they register themselves.
  static set instance(ImageToAsciiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
