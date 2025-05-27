import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:image_to_ascii/src/image_to_ascii_dart.dart';

class AsciiBench extends BenchmarkBase {
  AsciiBench() : super('convertImageToAscii');

  late String _imagePath;

  @override
  void setup() {
    // Set the path to the test image
    _imagePath = 'assets/eko.png';

    // Verify the file exists
    final file = File(_imagePath);
    if (!file.existsSync()) {
      throw Exception('Test image not found at $_imagePath');
    }
  }

  @override
  Future<void> run() async {
    // The harness calls this in a tight loop and averages the time
    await convertImageToAsciiDart(path: _imagePath);
  }
}

void main() => AsciiBench().report();
