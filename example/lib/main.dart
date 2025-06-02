import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_ascii/image_to_ascii.dart';

void main() =>
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: const MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _asciiArt = '';
  String _loadingTime = '';
  bool _isLoading = false;

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

    final ascii = await convertImageToAscii(picked.path);

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
                  : SizedBox(
                    width: 300,
                    height: 500,
                    child: AsciiImageWidget(ascii: _asciiArt),
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
    body: SizedBox(width: 300, child: AsciiImageWidget(ascii: _frame)),
  );
}
