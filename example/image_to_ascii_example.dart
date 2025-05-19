import 'package:image_to_ascii/image_to_ascii.dart';

void main() {
  String ascii = convertImageToAscii("../test/eko.png");
  print(ascii);
}
