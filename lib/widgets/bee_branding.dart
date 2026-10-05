import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Tiled honeycomb pattern used as a subtle decorative background. Drawn
/// in code so the app ships with no external image assets.
class HoneycombBackground extends StatelessWidget {
  final Widget child;
  final Color hexColor;
  final Color backgroundColor;
  final double opacity;
  final double hexRadius;

  const HoneycombBackground({
    super.key,
    required this.child,
    this.hexColor = kBrandColor,
    this.backgroundColor = kCreamBackground,
    this.opacity = 0.12,
    this.hexRadius = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _HoneycombPainter(
              color: hexColor.withValues(alpha: opacity),
              radius: hexRadius,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HoneycombPainter extends CustomPainter {
  final Color color;
  final double radius;
  _HoneycombPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final hexWidth = radius * math.sqrt(3);
    final hexHeight = radius * 2;
    final vertSpacing = hexHeight * 0.75;

    var row = 0;
    for (double y = -hexHeight; y < size.height + hexHeight; y += vertSpacing) {
      final xOffset = (row.isOdd) ? hexWidth / 2 : 0.0;
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth) {
        _drawHexagon(canvas, paint, Offset(x + xOffset, y), radius);
      }
      row++;
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HoneycombPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// The Beezy Finance bee mark (trimmed from the brand logo, background
/// keyed to transparent) — see assets/branding/.
class BeeLogo extends StatelessWidget {
  final double size;
  const BeeLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/bee_transparent.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}
