import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_to_ascii/image_to_ascii.dart';
import 'package:image_to_ascii/src/bit_buffer.dart';
import 'package:image_to_ascii/src/char_set.dart';
import 'package:image_to_ascii/src/encoder_decoder.dart';

// if the pixel height is less then or equal to this boxes will be drawn instead of glyphs to reduce artifacting
const int _boxThreshold = 8;

// this chache lives in the isolate and provides alpha maps of the CharSet
class _GlyphCache {
  static final Map<int, List<Uint8List>> _glyphCache = {};
  static Uint8List get({required int size, required int value}) {
    // return garbage since it won't be used. this is to error on !
    if (size <= _boxThreshold) {
      return Uint8List(0);
    }
    return _glyphCache[size]![value];
  }

  static void add({required int size, required List<Uint8List> glyphs}) {
    _glyphCache[size] = glyphs;
  }
}

// this gets the closest power of 2 to the ideal char height. the upper limit on the clamp avoid caching too much. the lower limit isn't really required since values less then 8 are ignored.
int _getGlyphHeight(int requestedHeight, int asciiHeight) {
  final charHeight = (requestedHeight / asciiHeight).round();
  final lower = 1 << (charHeight.bitLength - 1); // Largest power of 2 <= x
  final upper = lower << 1; // Smallest power of 2 > x

  return ((charHeight - lower < upper - charHeight) ? lower : upper).clamp(
    1,
    64,
  );
}

// this just wraps the decode to make it awaitable
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

// payload that the isolate expects typically
class _RenderParams {
  final AsciiImage ascii;
  final int pixelHeight;
  // this is only needed for box approximation
  final double charAspectRatio;

  const _RenderParams(this.ascii, this.pixelHeight, this.charAspectRatio);
}

//typical response formk isolate
class _Response {
  final Uint8List bytes;
  final int width;
  final int height;
  const _Response(this.bytes, this.width, this.height);
}

int _applyAlpha(int color, int alpha, bool dark) {
  final a = alpha / 255.0;
  if (dark) {
    return (color * a).round();
  } else {
    return ((color * a) + (255 * (1 - a))).round();
  }
}

// the main worker function
_Response _asciiToImage(_RenderParams params) {
  final ascii = params.ascii;
  final bool useBoxes = params.pixelHeight <= _boxThreshold;
  // 7 is a good number for MartianMono since 5/7 ~= 0.7
  final pixelHeight = useBoxes ? 7 : params.pixelHeight;
  final pixelWidth =
      useBoxes
          ? (pixelHeight * params.charAspectRatio).round()
          // infer width from height and lenght
          : _GlyphCache.get(size: params.pixelHeight, value: 0).length ~/
              pixelHeight;
  //size of final image in pixels
  final outWidth = ascii.width! * pixelWidth;
  final outHeight = ascii.height! * pixelHeight;
  // final image. the *4 is because rgba
  final bytes = Uint8List(outWidth * outHeight * 4);
  final bitArray = BitArray(ascii.data);
  // these are useful for black and white pictures
  final int foreground = ascii.dark ? 0xFF : 0x00;
  final int background = ascii.dark ? 0x00 : 0xFF;
  // initialize colors for black and white images
  int r, g, b;
  (r, g, b) = (foreground, foreground, foreground);
  if (ascii.color) {
    (r, g, b) = colorsFromByte(bitArray.readBits(8));
  }
  int char = bitArray.readBits(4);
  Uint8List glyph = _GlyphCache.get(size: params.pixelHeight, value: char - 1);
  for (int y = 0; y < ascii.height!; y++) {
    for (int x = 0; x < ascii.width!; x++) {
      // check if change bit happened
      if (bitArray.readBit() == 1) {
        if (ascii.color) {
          final didColorChange = bitArray.readBit() == 1;
          final didCharChange = bitArray.readBit() == 1;

          //Color Changed
          if (didColorChange) {
            (r, g, b) = colorsFromByte(bitArray.readBits(8));
          }
          // Char Changed
          if (didCharChange) {
            char = bitArray.readBits(4);
            glyph = _GlyphCache.get(size: params.pixelHeight, value: char - 1);
          }
        } else {
          char = bitArray.readBits(4);
          glyph = _GlyphCache.get(size: params.pixelHeight, value: char - 1);
        }
      }
      // this case is when the pixes are too small to be worth drawing a character
      // this loop traveses the "pixel" in a box spiral pattern
      if (useBoxes) {
        int filled = 0;
        // how much of the box should be filled. the 0.75 is to correct for characters being less dense then pixels
        final int targetFilled =
            ((pixelHeight * pixelWidth) * ((char - 1) / 10) * 0.75).round();

        final cx = pixelWidth ~/ 2;
        final cy = pixelHeight ~/ 2;

        // Directions: right, down, left, up
        const directions = [(1, 0), (0, 1), (-1, 0), (0, -1)];

        int xOffset = 0;
        int yOffset = 0;
        int steps = 1;
        int directionIndex = 0;

        //keep track of visited pixels to not write twice
        final visited = <(int, int)>{};

        while (filled < pixelHeight * pixelWidth &&
            visited.length < pixelWidth * pixelHeight) {
          for (int side = 0; side < 2; side++) {
            for (int i = 0; i < steps; i++) {
              final px = cx + xOffset;
              final py = cy + yOffset;

              // Bounds check
              if (px >= 0 && px < pixelWidth && py >= 0 && py < pixelHeight) {
                final key = (px, py);
                if (!visited.contains(key)) {
                  visited.add(key);
                  // check if more pixels still need to be filled
                  final shouldFill = filled < targetFilled;
                  final dx = x * pixelWidth + px;
                  final dy = y * pixelHeight + py;
                  final offset = (dy * outWidth + dx) * 4;

                  bytes[offset + 0] = shouldFill ? r : background;
                  bytes[offset + 1] = shouldFill ? g : background;
                  bytes[offset + 2] = shouldFill ? b : background;
                  bytes[offset + 3] = 255;

                  filled++;
                }
              }

              // Advance in current direction
              xOffset += directions[directionIndex].$1;
              yOffset += directions[directionIndex].$2;
            }

            directionIndex = (directionIndex + 1) % 4;
          }

          // Every two sides, increase the step size
          steps++;
        }
      } else {
        for (int py = 0; py < pixelHeight; py++) {
          for (int px = 0; px < pixelWidth; px++) {
            final dx = x * pixelWidth + px;
            final dy = y * pixelHeight + py;
            final offset = (dy * outWidth + dx) * 4;
            final alpha = glyph[(pixelWidth * py) + px];

            // could use literal alpha here, I chose to blend with background color
            bytes[offset + 0] = _applyAlpha(r, alpha, ascii.dark);
            bytes[offset + 1] = _applyAlpha(g, alpha, ascii.dark);
            bytes[offset + 2] = _applyAlpha(b, alpha, ascii.dark);
            bytes[offset + 3] = 255;
          }
        }
      }
    }
  }
  return _Response(bytes, outWidth, outHeight);
}

class RenderWorker {
  static Future<RenderWorker>? _instance;
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  // this is a sort of rough copy of the glyph cache so that the main thread can remember what it has sent over.
  final Set<int> _sentGlyphSizes = {};
  final double charAspectRatio;
  final TextStyle style;
  int _idCounter = 0;

  // spawn an isolate if one has not been created else return the current one.
  // note that the parameters only take effect if the isolate has not been created.
  static Future<RenderWorker> getInstance({
    required TextStyle style,
    required double charAspectRatio,
  }) {
    _instance ??= _spawn(style, charAspectRatio);
    return _instance!;
  }

  Future<ui.Image> render({
    required AsciiImage ascii,
    int requestedImageHeight = 1024,
  }) async {
    final glyphHeight = _getGlyphHeight(requestedImageHeight, ascii.height!);

    // if this glyphSize hasn't been created send it to the isolate. don't send it if it is too small
    if (glyphHeight > _boxThreshold && !_sentGlyphSizes.contains(glyphHeight)) {
      _sentGlyphSizes.add(glyphHeight);
      _commands.send((
        // the string type tells the isolate this is a glyphSet not a task. could make this an enum if more tasks are needed
        'g',
        (glyphHeight, await CharSet.generateGlyphCache(glyphHeight, style)),
      ));
    }
    final completer = Completer<_Response>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, _RenderParams(ascii, glyphHeight, charAspectRatio)));
    final res = await completer.future;
    return await decodeImageFromPixelsAsync(res.bytes, res.width, res.height);
  }

  // crate the isolate
  static Future<RenderWorker> _spawn(
    TextStyle style,
    double charAspectRatio,
  ) async {
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

    return RenderWorker._(receivePort, sendPort, style, charAspectRatio);
  }

  RenderWorker._(
    this._responses,
    this._commands,
    this.style,
    this.charAspectRatio,
  ) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  // just recives messages from the isolate and passes them along. could use more error handling probably
  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, _Response response) = message as (int, _Response);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
      debugPrint(response.toString());
    } else {
      completer.complete(response);
    }
  }

  // this is the isolate. it has access to the main glyph cache and can inturpret incoming messages
  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    receivePort.listen((message) async {
      // unused stop trigger
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      // glyph cache update
      if ((message as (dynamic, dynamic)).$1 is String) {
        final (int size, List<Uint8List> glyphs) =
            message.$2 as (int, List<Uint8List>);
        _GlyphCache.add(size: size, glyphs: glyphs);
        return;
      }
      // work
      final (int id, _RenderParams params) = message as (int, _RenderParams);
      try {
        final result = _asciiToImage(params);
        sendPort.send((id, result));
      } catch (e) {
        debugPrint(e.toString());
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
