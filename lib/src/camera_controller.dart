import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class AsciiCameraController {
  AsciiCameraController({
    this.width = 150,
    this.height,
    this.preset = ResolutionPreset.low,
    this.darkMode = false,
  });

  final int? width;
  final int? height;
  final ResolutionPreset preset;
  final bool darkMode;

  late CameraController _cam;
  late Isolate _worker;
  late SendPort _workerSend;
  late final List<CameraDescription> _cameras;
  final List<int> _frontCameras = [];
  final List<int> _backCameras = [];
  int _currentCameraIndex = 0;
  bool _isStreamActive = false;
  final _asciiStreamCtrl = StreamController<String>.broadcast();
  bool _workerBusy = false;
  // Calculated dimensions
  late int _targetWidth;
  late int _targetHeight;

  // Public stream
  Stream<String> get stream => _asciiStreamCtrl.stream;
  List<CameraDescription> get cameras => _cameras;

  int get currentCameraIndex => _currentCameraIndex;

  List<int> get backCameras => _backCameras;
  List<int> get frontCameras => _frontCameras;

  Future<XFile?> takePicture() async {
    if (!_cam.value.isInitialized) {
      return null;
    }
    try {
      return await _cam.takePicture();
    } catch (_) {}
    return null;
  }

  Future<void> _populateCameraLists() async {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        _frontCameras.add(i);
      } else {
        _backCameras.add(i);
      }
    }
  }

  Future<void> initialize() async {
    _cameras = await availableCameras();
    _populateCameraLists();
    _currentCameraIndex = _backCameras.first;
    _cam = CameraController(
      _cameras[_currentCameraIndex],
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cam.initialize();

    // Calculate dimensions based on camera aspect ratio
    _calculateDimensions();

    // spawn the worker
    final recvMain = ReceivePort();
    if (Platform.isIOS) {
      _worker = await Isolate.spawn(_workerIOS, recvMain.sendPort);
    } else {
      _worker = await Isolate.spawn(_workerAndroid, recvMain.sendPort);
    }
    _workerSend = await recvMain.first as SendPort;

    // start stream
    await _cam.startImageStream(_onFrame);
    _isStreamActive = true;
  }

  Future<void> switchToBack() async {
    await switchToCamera(_backCameras.first);
  }

  Future<void> switchToFront() async {
    await switchToCamera(_frontCameras.first);
  }

  Future<void> switchToCamera(int cameraIndex) async {
    if (cameraIndex < 0 || cameraIndex >= _cameras.length) {
      return;
    }

    if (cameraIndex == _currentCameraIndex) {
      return;
    }

    try {
      // Stop the current image stream
      if (_isStreamActive) {
        await _cam.stopImageStream();
        _isStreamActive = false;
      }

      // Dispose current controller
      await _cam.dispose();

      // Switch to specified camera
      _currentCameraIndex = cameraIndex;

      // Create new controller with the specified camera
      _cam = CameraController(
        _cameras[_currentCameraIndex],
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Initialize the new camera
      await _cam.initialize();

      // Recalculate dimensions for the new camera
      _calculateDimensions();

      // Restart the image stream
      await _cam.startImageStream(_onFrame);
      _isStreamActive = true;
    } catch (e) {
      // don't throw
    }
  }

  void _calculateDimensions() {
    final previewSize = _cam.value.previewSize;
    if (previewSize == null) {
      // Fallback if preview size is unavailable
      _targetWidth = width ?? 150;
      _targetHeight = height ?? 75;
      return;
    }

    final double aspectRatio = previewSize.width / previewSize.height;

    if (width != null && height != null) {
      _targetWidth = width!;
      _targetHeight = height!;
    } else if (width != null) {
      _targetWidth = width!;
      _targetHeight = (_targetWidth / aspectRatio).round();
    } else if (height != null) {
      _targetHeight = height!;
      _targetWidth = (_targetHeight * aspectRatio).round();
    } else {
      _targetWidth = 150;
      _targetHeight = (_targetWidth / aspectRatio).round();
    }
  }

  Future<void> dispose() async {
    if (_isStreamActive) {
      await _cam.stopImageStream();
      _isStreamActive = false;
    }
    await _cam.dispose();
    _worker.kill(priority: Isolate.immediate);
    await _asciiStreamCtrl.close();
  }

  // Frame handler (UI isolate)
  void _onFrame(CameraImage img) {
    if (_workerBusy) return; // drop if still processing
    _workerBusy = true;

    final payload = _Payload(
      img.planes[0].bytes, // Y plane
      img.width,
      img.height,
      _targetWidth,
      _targetHeight,
      darkMode,
      img.planes[0].bytesPerRow,
      cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front,
    );

    final reply = ReceivePort();
    _workerSend.send([payload, reply.sendPort]);
    reply.first.then((ascii) {
      _workerBusy = false;
      _asciiStreamCtrl.add(ascii as String);
    });
  }
}

// Worker isolate
class _Payload {
  final Uint8List y;
  final int srcW, srcH, outW, outH;
  final bool darkMode;
  final int bytesPerRow;
  final bool isFrontFacing;

  const _Payload(
    this.y,
    this.srcW,
    this.srcH,
    this.outW,
    this.outH,
    this.darkMode,
    this.bytesPerRow,
    this.isFrontFacing,
  );
}

// android

void _androidInnerLoop(
  _Payload p,
  double stepX,
  double stepY,
  String chars,
  StringBuffer sb,
  int ay,
) {
  for (int ax = 0; ax < p.outW; ax++) {
    final y = p.srcH - (ax * stepX).floor() - 1;
    final x = (ay * stepY).floor();

    // Ensure we don't access outside the array bounds
    if (y >= 0 && y < p.srcH && x >= 0 && x < p.srcW) {
      final lum = p.y[y * p.srcW + x];
      sb.write(chars[(lum * (chars.length - 1)) ~/ 255]);
    } else {
      sb.write(' ');
    }
  }
  sb.writeln();
}

void _workerAndroid(SendPort mainSend) {
  final recv = ReceivePort();
  mainSend.send(recv.sendPort);

  final sb = StringBuffer();

  recv.listen((msg) {
    final _Payload p = msg[0] as _Payload;
    final SendPort ret = msg[1] as SendPort;

    final chars = p.darkMode ? ' .:-=+*#%@' : '@%#*+=-:. ';

    final stepX = p.srcH / p.outW;
    final stepY = p.srcW / p.outH;
    sb.clear();

    if (p.isFrontFacing) {
      for (int ay = p.outH - 1; ay >= 0; ay--) {
        _androidInnerLoop(p, stepX, stepY, chars, sb, ay);
      }
    } else {
      for (int ay = 0; ay < p.outH; ay++) {
        _androidInnerLoop(p, stepX, stepY, chars, sb, ay);
      }
    }

    ret.send(sb.toString());
  });
}

//ios
void _workerIOS(SendPort mainSend) {
  final recv = ReceivePort();
  mainSend.send(recv.sendPort);

  final sb = StringBuffer();

  recv.listen((msg) {
    final _Payload p = msg[0] as _Payload;
    final SendPort ret = msg[1] as SendPort;

    final chars = p.darkMode ? ' .:-=+*#%@' : '@%#*+=-:. ';

    final stepX = p.srcW / p.outW;
    final stepY = p.srcH / p.outH;
    sb.clear();

    final yStride = p.bytesPerRow;

    for (int y = 0; y < p.outH; y++) {
      for (int x = 0; x < p.outW; x++) {
        final srcX = (x * stepX).floor();
        final srcY = (y * stepY).floor();

        if (srcX >= 0 && srcX < p.srcW && srcY >= 0 && srcY < p.srcH) {
          final index = srcY * yStride + srcX;

          if (index >= 0 && index < p.y.length) {
            final lum = p.y[index];
            sb.write(chars[(lum * (chars.length - 1)) ~/ 255]);
          }
        } else {
          sb.write(' ');
        }
      }
      sb.writeln();
    }
    ret.send(sb.toString());
  });
}
