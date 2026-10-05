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

/// A small hand-drawn bee mark used as the Kosh Finance logo, so the app
/// doesn't depend on any bundled image asset.
class BeeLogo extends StatelessWidget {
  final double size;
  const BeeLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BeePainter()),
    );
  }
}

class _BeePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + h * 0.05);

    final wingPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final wingOutline = Paint()
      ..color = kBrandDark.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Wings
    final leftWing = Rect.fromCenter(
        center: center.translate(-w * 0.22, -h * 0.18), width: w * 0.42, height: h * 0.3);
    final rightWing = Rect.fromCenter(
        center: center.translate(w * 0.22, -h * 0.18), width: w * 0.42, height: h * 0.3);
    canvas.drawOval(leftWing, wingPaint);
    canvas.drawOval(leftWing, wingOutline);
    canvas.drawOval(rightWing, wingPaint);
    canvas.drawOval(rightWing, wingOutline);

    // Body
    final bodyRect = Rect.fromCenter(center: center, width: w * 0.56, height: h * 0.62);
    final bodyPath = Path()..addOval(bodyRect);
    canvas.drawPath(bodyPath, Paint()..color = kHoneyLight);

    // Stripes
    final stripePaint = Paint()..color = kBrandDark;
    canvas.save();
    canvas.clipPath(bodyPath);
    for (final dy in [-0.18, 0.02, 0.22]) {
      final stripeRect = Rect.fromCenter(
        center: center.translate(0, h * dy),
        width: w * 0.6,
        height: h * 0.09,
      );
      canvas.drawRect(stripeRect, stripePaint);
    }
    canvas.restore();
    canvas.drawOval(bodyRect, Paint()
      ..color = kBrandDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Eyes
    final eyePaint = Paint()..color = kBrandDark;
    canvas.drawCircle(center.translate(-w * 0.08, -h * 0.26), w * 0.035, eyePaint);
    canvas.drawCircle(center.translate(w * 0.08, -h * 0.26), w * 0.035, eyePaint);

    // Antennae
    final antennaPaint = Paint()
      ..color = kBrandDark
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final base = center.translate(0, -h * 0.3);
    canvas.drawLine(base, base.translate(-w * 0.1, -h * 0.16), antennaPaint);
    canvas.drawLine(base, base.translate(w * 0.1, -h * 0.16), antennaPaint);
  }

  @override
  bool shouldRepaint(covariant _BeePainter oldDelegate) => false;
}
