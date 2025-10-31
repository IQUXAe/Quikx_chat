import 'package:flutter/material.dart';

class ModernBackButton extends StatelessWidget {
  const ModernBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: CustomPaint(
        size: const Size(24, 24),
        painter: _BackArrowPainter(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

class _BackArrowPainter extends CustomPainter {
  final Color color;

  _BackArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.65, size.height * 0.25)
      ..lineTo(size.width * 0.35, size.height * 0.5)
      ..lineTo(size.width * 0.65, size.height * 0.75);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BackArrowPainter oldDelegate) => color != oldDelegate.color;
}
