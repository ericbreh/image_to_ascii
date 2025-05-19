import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:test/test.dart';

void main() {
  test('Basic conversion does not throw', () {
    expect(() => convertImageToAscii("eko.png"), returnsNormally);
  });
}
