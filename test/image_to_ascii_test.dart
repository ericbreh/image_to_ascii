import 'package:flutter_test/flutter_test.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/image_to_ascii_platform_interface.dart';
import 'package:image_to_ascii/image_to_ascii_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockImageToAsciiPlatform
    with MockPlatformInterfaceMixin
    implements ImageToAsciiPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ImageToAsciiPlatform initialPlatform = ImageToAsciiPlatform.instance;

  test('$MethodChannelImageToAscii is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImageToAscii>());
  });

  test('getPlatformVersion', () async {
    ImageToAscii imageToAsciiPlugin = ImageToAscii();
    MockImageToAsciiPlatform fakePlatform = MockImageToAsciiPlatform();
    ImageToAsciiPlatform.instance = fakePlatform;

    expect(await imageToAsciiPlugin.getPlatformVersion(), '42');
  });
}
