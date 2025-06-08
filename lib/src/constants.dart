import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const charAspectRatio = 0.7;
const charHeight = 1.0;
const charWidth = charHeight * charAspectRatio;

final defaultTextStyle = GoogleFonts.martianMono(
  textStyle: TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: charHeight,
  ),
);
