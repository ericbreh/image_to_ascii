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
    return SizedBox(
      height: height,
      width: width,
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Text(
            ascii.toString(),
            style: GoogleFonts.martianMono(
              textStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                fontSize: 25,
                height: 1.0,
              ),
            ),
            softWrap: false,
          ),
        ),
      ),
    );
  }
}

// String stripColorCodes(String ascii) {
//   final regex = RegExp(r'\[#([0-9A-Fa-f]{6})\]');
//   return ascii.replaceAll(regex, '');
// }

// List<InlineSpan> parseAsciiWithColors(String asciiString, TextStyle baseStyle) {
//   final spans = <InlineSpan>[];

//   final regex = RegExp(r'\[#([0-9A-Fa-f]{6})\](.)');
//   final lines = asciiString.split('\n');

//   for (var line in lines) {
//     int i = 0;
//     while (i < line.length) {
//       final match = regex.matchAsPrefix(line, i);
//       if (match != null) {
//         final colorHex = match.group(1)!;
//         final char = match.group(2)!;
//         final color = Color(int.parse('0xFF$colorHex'));

//         spans.add(
//           TextSpan(text: char, style: baseStyle.copyWith(color: color)),
//         );
//         i += match.group(0)!.length;
//       } else {
//         spans.add(TextSpan(text: line[i], style: baseStyle));
//         i++;
//       }
//     }
//     spans.add(const TextSpan(text: '\n'));
//   }

//   return spans;
// }

// class AsciiImageWidget extends StatelessWidget {
//   final String ascii;
//   final double width;

//   const AsciiImageWidget({super.key, required this.ascii, required this.width});

//   @override
//   Widget build(BuildContext context) {
//     final stripped = stripColorCodes(ascii);
//     final lines = stripped.trimRight().split('\n');

//     final int rows = lines.length;
//     final int cols =
//         lines.isEmpty
//             ? 1
//             : lines.map((l) => l.length).reduce((a, b) => a > b ? a : b);

//     // Calculate the font size based on fixed width and number of columns
//     final double fontSize = width / cols;

//     // Typical monospace font height ≈ 1.6 × font size for line height
//     final double height = fontSize * rows * 1.0;

//     final isLight = Theme.of(context).brightness == Brightness.light;
//     final baseColor = isLight ? Colors.black : Colors.white;

//     final textStyle = GoogleFonts.martianMono(
//       textStyle: TextStyle(
//         fontSize: fontSize,
//         height: 1.0,
//         fontWeight: FontWeight.w600,
//         color: baseColor,
//       ),
//     );

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: SizedBox(
//         width: width,
//         height: height,
//         child: Text.rich(
//           TextSpan(children: parseAsciiWithColors(ascii, textStyle)),
//           softWrap: false,
//           overflow: TextOverflow.clip,
//           style: textStyle,
//         ),
//       ),
//     );
//   }
// }
