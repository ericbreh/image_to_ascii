import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final baseTextStyle = GoogleFonts.martianMono(
      textStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: textColor,
        fontSize: 25,
        height: 1.0,
      ),
    );

    return SizedBox(
      height: height,
      width: width,
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: ColoredBox(
            color: backgroundColor,
            child:
                (ascii.color)
                    ? Text.rich(
                      TextSpan(
                        style: baseTextStyle,
                        children: ascii.toTextSpans(),
                      ),
                      softWrap: false,
                    )
                    : Text(
                      ascii.toDisplayString(),
                      style: baseTextStyle,
                      softWrap: false,
                    ),
          ),
        ),
      ),
    );
  }
}
