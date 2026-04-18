import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_ascii/image_to_ascii.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(surface: Colors.black),
    ),
    home: const CameraPage(),
  ),
);

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late final AsciiCameraController _ctrl;
  String frame = '';
  bool cameraAvailable = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AsciiCameraController(darkMode: true, width: 150, height: 150);
    _ctrl.initialize().then((_) {
      setState(() => cameraAvailable = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditPage(imagePath: picked.path)),
    );
  }

  Future<void> captureFrame() async {
    final picture = await _ctrl.takePicture();
    if (picture == null) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditPage(imagePath: picture.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASCII Camera')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder(
                stream: _ctrl.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Center(
                      child: AsciiImageWidget(
                        ascii: AsciiImage.fromSimpleString(snapshot.data!),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: pickImage,
                  icon: Icon(
                    size: 35,
                    Icons.perm_media,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: captureFrame,
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (_ctrl.backCameras.contains(_ctrl.currentCameraIndex)) {
                      await _ctrl.switchToFront();
                    } else {
                      await _ctrl.switchToBack();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.autorenew,
                    size: 35,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditPage extends StatefulWidget {
  final String imagePath;
  const EditPage({super.key, required this.imagePath});
  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  AsciiImage? asciiPicture;
  bool isDark = true;
  bool isColor = false;
  int density = 150;
  bool densityControllVisible = false;
  bool downloading = false;
  GlobalKey imageKey = GlobalKey();
  bool isLoading = false;

  Future<void> convert() async {
    setState(() => isLoading = true);
    final cropped = await cropToAspectRatio(
      widget.imagePath,
      desiredWidth: density,
      vScale: 0.75,
    );
    final img = await convertImageToAscii(
      cropped,
      dark: isDark,
      color: isColor,
    );
    setState(() {
      asciiPicture = img;
      isLoading = false;
    });
  }

  @override
  void initState() {
    convert();
    super.initState();
  }

  void copyPressed() {
    if (asciiPicture != null) {
      Clipboard.setData(ClipboardData(text: asciiPicture!.toDisplayString()));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void downloadPressed() async {
    if (downloading || asciiPicture == null) return;
    downloading = true;

    final boundary =
        imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded ${pngBytes.length} bytes')),
    );
    downloading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: copyPressed,
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  onPressed: downloadPressed,
                  icon: const Icon(Icons.download),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  asciiPicture == null
                      ? const Center(child: CircularProgressIndicator())
                      : RepaintBoundary(
                        key: imageKey,
                        child: Stack(
                          children: [
                            Center(
                              child: AsciiImageWidget(ascii: asciiPicture!),
                            ),
                            if (isLoading)
                              SizedBox.expand(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                          ],
                        ),
                      ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: densityControllVisible ? 60 : 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: ((density - 10) / 190) * 100,
                        min: 0,
                        max: 100,
                        onChanged: (v) {
                          setState(
                            () => density = (v / 100 * 190 + 10).round(),
                          );
                        },
                        onChangeEnd: (v) => convert(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => isDark = !isDark);
                    convert();
                  },
                  icon: Icon(
                    size: 35,
                    isDark ? Icons.dark_mode : Icons.light_mode,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => isColor = !isColor);
                    convert();
                  },
                  icon: Icon(
                    size: 35,
                    isColor ? Icons.palette : Icons.filter_b_and_w,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(
                      () => densityControllVisible = !densityControllVisible,
                    );
                  },
                  icon: Icon(
                    size: 35,
                    Icons.tune,
                    color:
                        densityControllVisible
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
