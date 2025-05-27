import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

  bool _isLoadingImage = false;

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

  void _clearAll() {
    setState(() {
      _asciiArt = '';
      _loadingTime = '';
      _conversionTime = '';
    });
  }

  Future<void> _selectImagePressed() async {
    // Select image
    final ImagePicker picker = ImagePicker();
    final XFile? imageLocal = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (imageLocal == null) return;

    setState(() => _isLoadingImage = true);
    final stopwatch = Stopwatch()..start();

    final ascii = await _imageToAsciiPlugin.convertImageToAscii(
      imageLocal.path,
    );

    stopwatch.stop();
    setState(() {
      _isLoadingImage = false;
      _asciiArt = ascii;
      _loadingTime = 'Load & Convert time: ${stopwatch.elapsedMilliseconds} ms';
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
              child:
                  (_isLoadingImage)
                      ? const Text("Loading...")
                      : FittedBox(
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
                  onPressed: _selectImagePressed,
                  child: const Text('Select Image'),
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
