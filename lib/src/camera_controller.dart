import 'dart:async';
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
  final _asciiStreamCtrl = StreamController<String>.broadcast();
  bool _workerBusy = false;

  // Calculated dimensions
  late int _targetWidth;
  late int _targetHeight;

  // ───────────────────────── public stream ──────────────────────────
  Stream<String> get stream => _asciiStreamCtrl.stream;

  // ───────────────────── lifecycle helpers ─────────────────────────
  Future<void> initialize() async {
    final cams = await availableCameras();
    _cam = CameraController(
      cams.first,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cam.initialize();

    // Calculate dimensions based on camera aspect ratio
    _calculateDimensions();

    // spawn the worker once
    final recvMain = ReceivePort();
    _worker = await Isolate.spawn(_workerEntry, recvMain.sendPort);
    _workerSend = await recvMain.first as SendPort;

    // start stream
    await _cam.startImageStream(_onFrame);
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
    await _cam.stopImageStream();
    await _cam.dispose();
    _worker.kill(priority: Isolate.immediate);
    await _asciiStreamCtrl.close();
  }

  // ───────────────────── frame handler (UI isolate) ───────────────────
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
    );

    final reply = ReceivePort();
    _workerSend.send([payload, reply.sendPort]);
    reply.first.then((ascii) {
      _workerBusy = false;
      _asciiStreamCtrl.add(ascii as String);
    });
  }
}

// ────────────────────────── Worker isolate ────────────────────────────
class _Payload {
  final Uint8List y;
  final int srcW, srcH, outW, outH;
  final bool darkMode;
  final int bytesPerRow;

  const _Payload(
    this.y,
    this.srcW,
    this.srcH,
    this.outW,
    this.outH,
    this.darkMode,
    this.bytesPerRow,
  );
}

// void _workerEntry(SendPort mainSend) {
//   final recv = ReceivePort();
//   mainSend.send(recv.sendPort);

//   final sb = StringBuffer();

//   recv.listen((msg) {
//     final _Payload p = msg[0] as _Payload;
//     final SendPort ret = msg[1] as SendPort;

//     final chars = p.darkMode ? ' .:-=+*#%@' : '@%#*+=-:. ';

//     final stepX = p.srcH / p.outW;
//     final stepY = p.srcW / p.outH;
//     sb.clear();

//     for (int ay = 0; ay < p.outH; ay++) {
//       for (int ax = 0; ax < p.outW; ax++) {
//         final y = p.srcH - (ax * stepX).floor() - 1;
//         final x = (ay * stepY).floor();

//         // Ensure we don't access outside the array bounds
//         if (y >= 0 && y < p.srcH && x >= 0 && x < p.srcW) {
//           final lum = p.y[y * p.srcW + x];
//           sb.write(chars[(lum * (chars.length - 1)) ~/ 255]);
//         } else {
//           sb.write(' ');
//         }
//       }
//       sb.writeln();
//     }
//     ret.send(sb.toString());
//   });
// }

void _workerEntry(SendPort mainSend) {
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
            final charIndex = (lum * (chars.length - 1)) ~/ 255;
            sb.write(chars[charIndex]);
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