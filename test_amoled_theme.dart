import 'package:flutter/material.dart';
import 'lib/pages/amoled_theme_demo.dart';

void main() {
  runApp(const AmoledTestApp());
}

class AmoledTestApp extends StatelessWidget {
  const AmoledTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuikxChat - AMOLED Theme',
      debugShowCheckedModeBanner: false,
      home: const AmoledThemeDemo(),
    );
  }
}
