import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:image_to_ascii/image_to_ascii.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _imageToAsciiPlugin = ImageToAscii();

  String _platformVersion = 'Unknown';

  String _asciiArt = '';
  String _loadingTime = '';
  String _conversionTime = '';
  img.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _imageToAsciiPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _loadConvertImage() async {
    final stopwatch = Stopwatch()..start();

    // Load asset
    final byteData = await rootBundle.load('assets/eko.png');
    final bytes = byteData.buffer.asUint8List();

    // Decode image using image package
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Image decode failed');

    stopwatch.stop();
    final loadTime = stopwatch.elapsedMilliseconds;

    setState(() {
      _decodedImage = image;
      _loadingTime = 'Loading time: ${loadTime}ms';
    });

    stopwatch.reset();
    stopwatch.start();

    // Convert to ASCII
    final ascii = _imageToAsciiPlugin.convertImageToAscii(_decodedImage!);

    stopwatch.stop();
    final convertTime = stopwatch.elapsedMilliseconds;

    if (!mounted) return;
    setState(() {
      _asciiArt = ascii;
      _conversionTime = 'Conversion time: ${convertTime}ms';
    });
  }

  void _clearAll() {
    setState(() {
      _asciiArt = '';
      _loadingTime = '';
      _conversionTime = '';
      _decodedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ASCII Image Converter')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(15),
              child: FittedBox(
                fit: BoxFit.contain,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Text(
                    _asciiArt,
                    style: GoogleFonts.martianMono(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontSize: 25,
                        height: 1.0,
                      ),
                    ),
                    softWrap: false,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
            if (_loadingTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _loadingTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            if (_conversionTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _conversionTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadConvertImage,
                  child: const Text('Load & Convert'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearAll,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Running on: $_platformVersion\n'),
          ],
        ),
      ),
    );
  }
}
