import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:image/image.dart';
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
  String _asciiArt = 'Loading...';
  String _platformVersion = 'Unknown';
  final _imageToAsciiPlugin = ImageToAscii();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _loadAndConvertImage();
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

  Future<void> _loadAndConvertImage() async {
    try {
      // Load asset
      final byteData = await rootBundle.load('assets/eko.png');
      final bytes = byteData.buffer.asUint8List();

      // Decode image using image package
      final image = decodeImage(bytes);
      if (image == null) throw Exception('Image decode failed');

      // Convert to ASCII
      final ascii = _imageToAsciiPlugin.convertImageToAscii(image);

      if (!mounted) return;
      setState(() => _asciiArt = ascii);
    } catch (e) {
      setState(() => _asciiArt = 'Error: $e');
    }
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
                    // textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Text('Running on: $_platformVersion\n'),
          ],
        ),
      ),
    );
  }
}
