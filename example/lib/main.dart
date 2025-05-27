import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/ascii_camera_controller.dart';

void main() =>
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: const MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _imageToAsciiPlugin = ImageToAscii();

  String _asciiArt = '';
  String _loadingTime = '';
  bool _isLoading = false;
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPlatform();
  }

  Future<void> _initPlatform() async {
    try {
      _platformVersion =
          await _imageToAsciiPlugin.getPlatformVersion() ?? 'Unknown platform';
    } on PlatformException {
      _platformVersion = 'Failed to get platform version.';
    }
    if (mounted) setState(() {});
  }

  void _clearAll() => setState(() {
    _asciiArt = '';
    _loadingTime = '';
  });

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);
    final sw = Stopwatch()..start();

    final ascii = await _imageToAsciiPlugin.convertImageToAscii(picked.path);

    sw.stop();
    setState(() {
      _asciiArt = ascii;
      _loadingTime = 'Load & Convert: ${sw.elapsedMilliseconds} ms';
      _isLoading = false;
    });
  }

  void _openCamera() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AsciiCameraPage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ASCII Image Converter')),
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child:
              _isLoading
                  ? const Text('Loading …')
                  : FittedBox(
                    fit: BoxFit.contain,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Text(
                        _asciiArt,
                        style: GoogleFonts.martianMono(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: Colors.black,
                        ),
                        softWrap: false,
                      ),
                    ),
                  ),
        ),
        if (_loadingTime.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _loadingTime,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _openCamera, child: const Text('Camera')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _selectImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(width: 12),

            ElevatedButton(onPressed: _clearAll, child: const Text('Clear')),
          ],
        ),
        const SizedBox(height: 20),
        Text('Running on: $_platformVersion'),
      ],
    ),
  );
}

class AsciiCameraPage extends StatefulWidget {
  const AsciiCameraPage({super.key});
  @override
  State<AsciiCameraPage> createState() => _AsciiCameraPageState();
}

class _AsciiCameraPageState extends State<AsciiCameraPage> {
  late final AsciiCameraController _ctrl;
  String _frame = 'Starting camera …';

  @override
  void initState() {
    super.initState();
    _ctrl = AsciiCameraController();
    _ctrl.initialize().then((_) {
      _ctrl.stream.listen((ascii) => setState(() => _frame = ascii));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live ASCII Camera')),
    body: SingleChildScrollView(
      child: Text(
        _frame,
        style: GoogleFonts.martianMono(
          fontSize: 6,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: Colors.black,
        ),
        softWrap: false,
      ),
    ),
  );
}
