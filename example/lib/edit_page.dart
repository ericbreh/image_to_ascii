import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
  int density = defaultAsciiWidth;
  bool densityControllVisible = false;
  bool downloading = false;
  GlobalKey imageKey = GlobalKey();
  bool isLoading = false;

  Future<void> convert() async {
    setState(() => isLoading = true);
    final cropped = await cropToAspectRatio(
      widget.imagePath,
      desiredWidth: density,
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

  void toggleDarkMode() {
    setState(() => isDark = !isDark);
    convert();
  }

  void toggleColor() {
    setState(() => isColor = !isColor);
    convert();
  }

  void changeDensity(int newDensity) {
    setState(() => density = newDensity);
    convert();
  }

  double mapDensityToSlider(int densityValue) {
    return ((densityValue - 10) / 190) * 100;
  }

  int mapSliderToDensity(double sliderValue) {
    return (sliderValue / 100 * 190 + 10).round();
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
                            Align(child: AsciiImageWidget(ascii: asciiPicture!)),
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
                        value: mapDensityToSlider(density),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: mapDensityToSlider(density).toInt().toString(),
                        onChanged: (value) {
                          setState(() => density = mapSliderToDensity(value));
                        },
                        onChangeEnd: (value) {
                          changeDensity(mapSliderToDensity(value));
                        },
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
                  onPressed: toggleDarkMode,
                  icon: Icon(
                    size: 35,
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: toggleColor,
                  icon: Icon(
                    size: 35,
                    isColor ? Icons.palette : Icons.filter_b_and_w,
                    color: Theme.of(context).colorScheme.onSurface,
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
                    color: densityControllVisible
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
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
