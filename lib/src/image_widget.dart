import 'package:flutter/material.dart';
import 'package:image_to_ascii/src/constants.dart';
import 'package:image_to_ascii/src/types/ascii_image.dart';

class AsciiImageWidget extends StatelessWidget {
  final AsciiImage ascii;
  final double? height;
  final double? width;

  const AsciiImageWidget({
    super.key,
    this.width,
    this.height,
    required this.ascii,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ascii.dark ? Colors.white : Colors.black;
    final backgroundColor = ascii.dark ? Colors.black : Colors.white;

    final baseTextStyle = defaultTextStyle.copyWith(color: textColor);

    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
          child: FittedBox(
            fit: BoxFit.contain,
            child: _AsciiWidget(ascii: ascii, style: baseTextStyle),
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
