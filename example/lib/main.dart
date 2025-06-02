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
  late final AsciiCameraController _ctrl;
  String frame = 'Starting camera …';
  XFile? selectedImage;
  String? asciiArt;
  String? loadingTime;
  bool isLoading = false;
  bool isDarkMode = true;

  void clearAll() => setState(() {
    asciiArt = null;
    loadingTime = null;
  });

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      selectedImage = picked;
    });

    await convertImage();
  }

  Future<void> convertImage() async {
    if (selectedImage == null) return;

    setState(() {
      isLoading = true;
    });

    final sw = Stopwatch()..start();

    final ascii = await convertImageToAscii(
      selectedImage!.path,
      darkMode: isDarkMode,
      color: false,
    );

    sw.stop();

    setState(() {
      asciiArt = ascii;
      loadingTime = 'Load & Convert: ${sw.elapsedMilliseconds} ms';
      isLoading = false;
    });
  }

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    convertImage();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AsciiCameraController(darkMode: false);
    _ctrl.initialize().then((_) {
      _ctrl.stream.listen((ascii) => setState(() => frame = ascii));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASCII Image Converter')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : asciiArt != null
                      ? Column(
                        children: [
                          SizedBox(
                            width: 500,
                            height: 600,
                            child: AsciiImageWidget(ascii: asciiArt!),
                          ),
                          if (loadingTime != null)
                            Text(
                              loadingTime!,
                              style: const TextStyle(fontSize: 16),
                            ),
                        ],
                      )
                      : SizedBox(
                        width: 500,
                        height: 600,
                        child: AsciiImageWidget(ascii: frame),
                      ),
            ),
          ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: pickImage,
                      icon: Icon(
                        Icons.perm_media,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (asciiArt != null) ...[
                      IconButton(
                        onPressed: toggleDarkMode,
                        icon: Icon(
                          (isDarkMode) ? Icons.dark_mode : Icons.light_mode,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: clearAll,
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
