import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_to_ascii/image_to_ascii.dart';

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
