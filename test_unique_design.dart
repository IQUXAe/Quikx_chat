import 'package:flutter/material.dart';
import 'lib/pages/unique_design_demo.dart';

void main() {
  runApp(const UniqueDesignTestApp());
}

class UniqueDesignTestApp extends StatelessWidget {
  const UniqueDesignTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuikxChat - Unique Design',
      debugShowCheckedModeBanner: false,
      home: const UniqueDesignDemo(),
    );
  }
}
