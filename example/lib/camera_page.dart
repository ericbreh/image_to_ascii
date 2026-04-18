import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'edit_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late final AsciiCameraController _ctrl;
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
      appBar: AppBar(
        title: const Text('ASCII Camera'),
        actions: [
          IconButton(
            onPressed:
                !cameraAvailable
                    ? null
                    : () async {
                      if (_ctrl.flashIsAuto()) {
                        await _ctrl.flashOff();
                      } else {
                        await _ctrl.flashAuto();
                      }
                      setState(() {});
                    },
            icon: Icon(
              _ctrl.flashIsAuto() ? Icons.flash_auto : Icons.flash_off,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder(
                stream: _ctrl.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AsciiImageWidget(
                      ascii: AsciiImage.fromSimpleString(snapshot.data!),
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
