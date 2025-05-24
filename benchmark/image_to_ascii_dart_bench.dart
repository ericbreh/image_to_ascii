import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:image/image.dart';
import 'package:image_to_ascii/src/image_to_ascii_dart.dart';

class AsciiBench extends BenchmarkBase {
  AsciiBench() : super('convertImageToAscii');

  late Image _img;

  @override
  void setup() {
    // Load a sample image once.
    final bytes = File('assets/eko.png').readAsBytesSync();
    _img = decodeImage(bytes)!;
  }

  @override
  void run() {
    // The harness calls this in a tight loop and averages the time.
    convertImageToAsciiDart(_img);
  }
}

void main() => AsciiBench().report();
