import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'edit_page.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InnerCameraPage(
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }
}

class InnerCameraPage extends StatefulWidget {
  final bool isDark;
  const InnerCameraPage({super.key, required this.isDark});

  @override
  State<InnerCameraPage> createState() => _InnerCameraPageState();
}

class _InnerCameraPageState extends State<InnerCameraPage> {
  late final AsciiCameraController _ctrl;
  bool cameraAvailable = false;
  String? cameraError;

  @override
  void initState() {
    super.initState();
    _ctrl = AsciiCameraController(darkMode: widget.isDark);
    _ctrl
        .initialize()
        .then((_) {
          if (mounted) setState(() => cameraAvailable = true);
        })
        .catchError((Object e) {
          debugPrint('Camera initialization failed: $e');
          if (mounted) {
            setState(() {
              cameraError = 'Camera unavailable.';
            });
          }
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
          if (Platform.isAndroid || Platform.isIOS)
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
                    return Align(
                      child: AsciiImageWidget(
                        ascii: AsciiImage.fromSimpleString(snapshot.data!),
                      ),
                    );
                  }
                  if (cameraError != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(cameraError!, textAlign: TextAlign.center),
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
