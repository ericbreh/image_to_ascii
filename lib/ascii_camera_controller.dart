import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';

class AsciiCameraController {
  AsciiCameraController({
    this.asciiWidth = 150,
    this.asciiHeight = 75,
    this.preset = ResolutionPreset.low,
  });

  final int asciiWidth, asciiHeight;
  final ResolutionPreset preset;

  late CameraController _cam;
  late Isolate _worker;
  late SendPort _workerSend;
  final _asciiStreamCtrl = StreamController<String>.broadcast();
  bool _workerBusy = false;

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

    // spawn the worker once
    final recvMain = ReceivePort();
    _worker = await Isolate.spawn(_workerEntry, recvMain.sendPort);
    _workerSend = await recvMain.first as SendPort;

    // start stream
    await _cam.startImageStream(_onFrame);
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
      asciiWidth,
      asciiHeight,
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
  const _Payload(this.y, this.srcW, this.srcH, this.outW, this.outH);
}

void _workerEntry(SendPort mainSend) {
  final recv = ReceivePort();
  mainSend.send(recv.sendPort);

  const chars = '@%#*+=-:. ';
  final sb = StringBuffer();

  recv.listen((msg) {
    final _Payload p = msg[0] as _Payload;
    final SendPort ret = msg[1] as SendPort;

    final stepX = p.srcW / p.outW;
    final stepY = p.srcH / p.outH;
    sb.clear();

    for (int ay = 0; ay < p.outH; ay++) {
      final y = (ay * stepY).floor();
      final row = y * p.srcW;
      for (int ax = 0; ax < p.outW; ax++) {
        final x = (ax * stepX).floor();
        final lum = p.y[row + x]; // 0–255
        sb.write(chars[(lum * (chars.length - 1)) >> 8]);
      }
      sb.writeln();
    }
    ret.send(sb.toString());
  });
}
