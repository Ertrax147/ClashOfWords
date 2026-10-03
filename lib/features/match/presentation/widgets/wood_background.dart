import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo de mesa de madera, dibujado en código para no depender de una
/// imagen.
class WoodBackground extends StatelessWidget {
  /// Crea el fondo con [child] encima.
  const WoodBackground({super.key, required this.child});

  /// Contenido que va sobre la mesa.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WoodPainter(), child: child);
  }
}

class _WoodPainter extends CustomPainter {
  static const _base = Color(0xFF9A6A3E);
  static const _dark = Color(0xFF6F4626);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_base, _dark],
        ).createShader(rect),
    );

    // Vetas: líneas onduladas suaves, siempre iguales (semilla fija).
    final random = Random(7);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 70; i++) {
      final y = random.nextDouble() * size.height;
      final amplitude = 2 + random.nextDouble() * 6;
      final wavelength = 180 + random.nextDouble() * 260;
      final phase = random.nextDouble() * pi * 2;
      grain.color = (random.nextBool() ? Colors.black : Colors.white)
          .withValues(alpha: 0.04 + random.nextDouble() * 0.05);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 12) {
        path.lineTo(x, y + sin(x / wavelength * pi * 2 + phase) * amplitude);
      }
      canvas.drawPath(path, grain);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
