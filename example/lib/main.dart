import 'package:flutter/material.dart';
import 'camera_page.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(surface: Colors.black),
    ),
    home: const CameraPage(),
  ),
);
