import 'dart:math';

import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  static const double _width = 600;
  const EmptyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final width = min(MediaQuery.sizeOf(context).width, EmptyPage._width) / 1.5;
    final theme = Theme.of(context);
    return Scaffold(
      // Add invisible appbar to make status bar on Android tablets bright.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        alignment: Alignment.center,
        child: Opacity(
          opacity: 0.3,
          child: Image.asset(
            'assets/logo2.png',
            width: width,
            height: width,
          ),
        ),
      ),
    );
  }
}
