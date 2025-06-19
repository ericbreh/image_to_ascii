import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_to_ascii/src/constants.dart';
import 'package:image_to_ascii/src/render_isolate.dart';
import 'package:image_to_ascii/src/types/ascii_image.dart';

class AsciiImageWidget extends StatelessWidget {
  final AsciiImage ascii;
  final double? height;
  final double? width;
  final TextStyle? textStyle;
  final bool forceCanvas;
  final double charAspectRatio;

  const AsciiImageWidget({
    super.key,
    this.width,
    this.height,
    this.textStyle,
    this.forceCanvas = false,
    this.charAspectRatio = 0.7,
    required this.ascii,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ascii.dark ? Colors.white : Colors.black;
    final backgroundColor = ascii.dark ? Colors.black : Colors.white;

    final baseTextStyle =
        textStyle ?? defaultTextStyle.copyWith(color: textColor);

    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
          child: FittedBox(
            fit: BoxFit.contain,
            child:
                (ascii.version > 1)
                    ? Text('Image not supported. Check for updates')
                    //web does not support isolates
                    : (ascii.version == 0 || forceCanvas || kIsWeb)
                    ? _AsciiWidget(ascii: ascii, style: baseTextStyle)
                    : _FastAsciiWidget(
                      ascii: ascii,
                      style: baseTextStyle,
                      charAspectRatio: charAspectRatio,
                    ),
          ),
        ),
      ),
    );
  }
}

class _AsciiWidget extends StatefulWidget {
  final AsciiImage ascii;
  final TextStyle style;
  const _AsciiWidget({required this.ascii, required this.style});

  @override
  State<_AsciiWidget> createState() => _AsciiWidgetState();
}

class _AsciiWidgetState extends State<_AsciiWidget> {
  late TextPainter tp;

  void _initTextPainter() {
    final span = TextSpan(
      style: widget.style,
      children: widget.ascii.toTextSpans(),
    );
    tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    tp.layout();
  }

  @override
  void initState() {
    super.initState();
    _initTextPainter();
  }

  @override
  void didUpdateWidget(covariant _AsciiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ascii != oldWidget.ascii) {
      _initTextPainter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tp.width,
      height: tp.height,
      child: CustomPaint(
        painter: _AsciiPainter(tp: tp),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _AsciiPainter extends CustomPainter {
  final TextPainter tp;

  _AsciiPainter({required this.tp});

  @override
  void paint(Canvas canvas, Size size) {
    tp.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _AsciiPainter oldDelegate) {
    return oldDelegate.tp != tp;
  }
}

class _FastAsciiWidget extends StatefulWidget {
  final AsciiImage ascii;
  final TextStyle style;
  final double charAspectRatio;
  const _FastAsciiWidget({
    required this.ascii,
    required this.style,
    required this.charAspectRatio,
  });

  @override
  State<_FastAsciiWidget> createState() => _FastAsciiWidgetState();
}

class _FastAsciiWidgetState extends State<_FastAsciiWidget> {
  Future<ui.Image>? image;
  ui.Image? currentImage;

  @override
  void initState() {
    super.initState();
    image = RenderWorker.getInstance(
      style: widget.style,
      charAspectRatio: widget.charAspectRatio,
    ).then((iso) => iso.render(ascii: widget.ascii));
    image?.then((img) {
      if (!mounted) {
        img.dispose();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FastAsciiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ascii != oldWidget.ascii) {
      currentImage?.dispose();
      currentImage = null;
      image = RenderWorker.getInstance(
        style: widget.style,
        charAspectRatio: widget.charAspectRatio,
      ).then((iso) => iso.render(ascii: widget.ascii));
      image?.then((img) {
        if (!mounted) {
          img.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    currentImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: image,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          currentImage = snapshot.data;
          return RawImage(image: snapshot.data);
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return SizedBox(
            //goofy
            width: 900,
            child: AspectRatio(
              aspectRatio: widget.ascii.width! / widget.ascii.height!,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
      },
    );
  }
}
