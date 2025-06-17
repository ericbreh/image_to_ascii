import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/src/bit_buffer.dart';
import 'package:image_to_ascii/src/encoder_decoder.dart';

Future<ui.Image> decodeImageFromPixelsAsync(
  Uint8List pixels,
  int width,
  int height,
) {
  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    (ui.Image img) => completer.complete(img),
  );

  return completer.future;
}

class _RenderParams {
  final AsciiImage ascii;
  final int pixelWidth;
  final int pixelHeight;

  _RenderParams({
    required this.pixelWidth,
    required this.pixelHeight,
    required this.ascii,
  });
}

Uint8List _asciiToImage(_RenderParams params) {
  final ascii = params.ascii;
  final pixelWidth = params.pixelWidth;
  final pixelHeight = params.pixelHeight;
  assert(ascii.version == 1);
  final outWidth = ascii.width! * pixelWidth;
  final outHeight = ascii.height! * pixelHeight;
  final bytes = Uint8List(outWidth * outHeight * 4);
  final bitArray = BitArray(ascii.data);
  final totalPixels = pixelHeight * pixelWidth;
  final backgroundColor = ascii.dark ? 0x00 : 0xFF;
  int color = bitArray.readBits(8);
  int char = bitArray.readBits(4);
  int fillTarget = (((char - 1) / 10) * totalPixels).round();
  int r, g, b;
  (r, g, b) = colorsFromByte(color);
  for (int y = 0; y < ascii.height!; y++) {
    for (int x = 0; x < ascii.width!; x++) {
      // check if change bit happened
      if (bitArray.readBit() == 1) {
        final didColorChange = bitArray.readBit() == 1;
        final didCharChange = bitArray.readBit() == 1;

        //Color Changed
        if (didColorChange) {
          color = bitArray.readBits(8);
          (r, g, b) = colorsFromByte(color);
        }
        // Char Changed
        if (didCharChange) {
          char = bitArray.readBits(4);
          fillTarget = (((char - 1) / 10) * totalPixels).round();
        }
      }

      int filled = 0;
      for (int py = 0; py < pixelHeight; py++) {
        for (int px = 0; px < pixelWidth; px++) {
          final dx = x * pixelWidth + px;
          final dy = y * pixelHeight + py;
          final offset = (dy * outWidth + dx) * 4;
          final shouldColor = filled < fillTarget;

          bytes[offset + 0] = shouldColor ? r : backgroundColor;
          bytes[offset + 1] = shouldColor ? g : backgroundColor;
          bytes[offset + 2] = shouldColor ? b : backgroundColor;
          bytes[offset + 3] = 255;
          filled++;
        }
      }
    }
  }
  return bytes;
}

class RenderWorker {
  static Future<RenderWorker>? _instance;
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  static Future<RenderWorker> getInstance() {
    _instance ??= _spawn();
    return _instance!;
  }

  Future<ui.Image> render({
    required AsciiImage ascii,
    int pixelWidth = 5,
    int pixelHeight = 7,
  }) async {
    final completer = Completer<Uint8List>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((
      id,
      _RenderParams(
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight,
        ascii: ascii,
      ),
    ));
    return await decodeImageFromPixelsAsync(
      await completer.future,
      ascii.width! * pixelWidth,
      ascii.height! * pixelHeight,
    );
  }

  static Future<RenderWorker> _spawn() async {
    // Create a receive port and add its initial message handler
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return RenderWorker._(receivePort, sendPort);
  }

  RenderWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Uint8List response) = message as (int, Uint8List);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (int id, _RenderParams params) = message as (int, _RenderParams);
      try {
        final result = _asciiToImage(params);
        sendPort.send((id, result));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }
}
