import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter that draws a wheat plant at various growth stages.
///
/// [progress] ranges from 0.0 (seed) to 1.0 (fully grown golden wheat).
///
/// 5 visual stages:
/// 1. Seed (0–5%): Brown seed in soil
/// 2. Sprout (6–20%): Short green stem with tiny leaves
/// 3. Young plant (21–50%): Taller stem, 3-4 leaves
/// 4. Maturing (51–80%): Full stem, grain head forming
/// 5. Full wheat (81–100%): Golden wheat stalk with full grain head
class WheatGrowthPainter extends CustomPainter {
  WheatGrowthPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground / soil
    final soilHeight = h * 0.30;
    final soilTop = h - soilHeight;

    _drawSoil(canvas, size, soilTop, soilHeight);

    if (progress <= 0.05) {
      _drawSeed(canvas, w, soilTop);
    } else if (progress <= 0.20) {
      final t = (progress - 0.05) / 0.15; // 0→1 within stage
      _drawSprout(canvas, w, h, soilTop, t);
    } else if (progress <= 0.50) {
      final t = (progress - 0.20) / 0.30;
      _drawYoungPlant(canvas, w, h, soilTop, t);
    } else if (progress <= 0.80) {
      final t = (progress - 0.50) / 0.30;
      _drawMaturingPlant(canvas, w, h, soilTop, t);
    } else {
      final t = (progress - 0.80) / 0.20;
      _drawFullWheat(canvas, w, h, soilTop, t);
    }
  }

  void _drawSoil(Canvas canvas, Size size, double soilTop, double soilHeight) {
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5D4037).withValues(alpha: 0.6),
          const Color(0xFF3E2723).withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, soilTop, size.width, soilHeight));

    final soilPath = Path()
      ..moveTo(0, soilTop + 6)
      ..quadraticBezierTo(
        size.width * 0.25,
        soilTop - 2,
        size.width * 0.5,
        soilTop + 4,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        soilTop + 10,
        size.width,
        soilTop + 4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(soilPath, soilPaint);
  }

  void _drawSeed(Canvas canvas, double w, double soilTop) {
    final seedPaint = Paint()..color = const Color(0xFF8D6E63);
    final seedCenter = Offset(w / 2, soilTop + 8);
    canvas.drawOval(
      Rect.fromCenter(center: seedCenter, width: 14, height: 10),
      seedPaint,
    );
    // Seed highlight
    final highlightPaint = Paint()
      ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: seedCenter + const Offset(-2, -1),
        width: 5,
        height: 3,
      ),
      highlightPaint,
    );
  }

  void _drawSprout(
    Canvas canvas,
    double w,
    double h,
    double soilTop,
    double t,
  ) {
    final cx = w / 2;
    final stemHeight = 20 + t * 30;
    final stemTop = soilTop - stemHeight;

    // Stem
    final stemPaint = Paint()
      ..color = Color.lerp(const Color(0xFF81C784), const Color(0xFF4CAF50), t)!
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path()
      ..moveTo(cx, soilTop)
      ..quadraticBezierTo(cx - 2, soilTop - stemHeight * 0.5, cx, stemTop);
    canvas.drawPath(stemPath, stemPaint);

    // Small leaf (appears as t increases)
    if (t > 0.3) {
      _drawLeaf(
        canvas,
        cx,
        stemTop + stemHeight * 0.3,
        12 * t,
        -0.4,
        const Color(0xFF66BB6A),
      );
    }
    if (t > 0.7) {
      _drawLeaf(
        canvas,
        cx,
        stemTop + stemHeight * 0.5,
        10 * t,
        0.5,
        const Color(0xFF81C784),
      );
    }
  }

  void _drawYoungPlant(
    Canvas canvas,
    double w,
    double h,
    double soilTop,
    double t,
  ) {
    final cx = w / 2;
    final stemHeight = 50 + t * 40;
    final stemTop = soilTop - stemHeight;

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path()
      ..moveTo(cx, soilTop)
      ..cubicTo(
        cx - 3,
        soilTop - stemHeight * 0.3,
        cx + 2,
        soilTop - stemHeight * 0.7,
        cx,
        stemTop,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Roots (subtle, below soil)
    final rootPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx, soilTop + 2),
      Offset(cx - 10, soilTop + 14),
      rootPaint,
    );
    canvas.drawLine(
      Offset(cx, soilTop + 2),
      Offset(cx + 8, soilTop + 12),
      rootPaint,
    );

    // Leaves
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.2,
      18,
      -0.5,
      const Color(0xFF66BB6A),
    );
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.35,
      16,
      0.6,
      const Color(0xFF4CAF50),
    );
    if (t > 0.3) {
      _drawLeaf(
        canvas,
        cx,
        stemTop + stemHeight * 0.5,
        14 * t,
        -0.4,
        const Color(0xFF81C784),
      );
    }
    if (t > 0.6) {
      _drawLeaf(
        canvas,
        cx,
        stemTop + stemHeight * 0.65,
        12 * t,
        0.3,
        const Color(0xFF66BB6A),
      );
    }
  }

  void _drawMaturingPlant(
    Canvas canvas,
    double w,
    double h,
    double soilTop,
    double t,
  ) {
    final cx = w / 2;
    final stemHeight = 90 + t * 30;
    final stemTop = soilTop - stemHeight;

    // Stem (thicker)
    final stemPaint = Paint()
      ..color = Color.lerp(const Color(0xFF43A047), const Color(0xFF7CB342), t)!
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path()
      ..moveTo(cx, soilTop)
      ..cubicTo(
        cx - 4,
        soilTop - stemHeight * 0.3,
        cx + 3,
        soilTop - stemHeight * 0.6,
        cx - 1,
        stemTop,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Roots
    final rootPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, soilTop + 2),
      Offset(cx - 12, soilTop + 16),
      rootPaint,
    );
    canvas.drawLine(
      Offset(cx, soilTop + 2),
      Offset(cx + 10, soilTop + 14),
      rootPaint,
    );
    canvas.drawLine(
      Offset(cx, soilTop + 5),
      Offset(cx - 6, soilTop + 18),
      rootPaint,
    );

    // Leaves
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.15,
      22,
      -0.5,
      const Color(0xFF66BB6A),
    );
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.25,
      20,
      0.6,
      const Color(0xFF4CAF50),
    );
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.40,
      18,
      -0.4,
      const Color(0xFF81C784),
    );
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.55,
      16,
      0.5,
      const Color(0xFF66BB6A),
    );
    _drawLeaf(
      canvas,
      cx,
      stemTop + stemHeight * 0.70,
      14,
      -0.3,
      const Color(0xFF4CAF50),
    );

    // Grain head forming
    if (t > 0.2) {
      _drawGrainHead(canvas, cx - 1, stemTop, t * 0.6, isGolden: false);
    }
  }

  void _drawFullWheat(
    Canvas canvas,
    double w,
    double h,
    double soilTop,
    double t,
  ) {
    final cx = w / 2;
    final stemHeight = 120.0;
    final stemTop = soilTop - stemHeight;

    // Golden color transition
    final stemColor = Color.lerp(
      const Color(0xFF7CB342),
      const Color(0xFFCDDC39),
      t,
    )!;

    // Stem
    final stemPaint = Paint()
      ..color = stemColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path()
      ..moveTo(cx, soilTop)
      ..cubicTo(
        cx - 4,
        soilTop - stemHeight * 0.3,
        cx + 3,
        soilTop - stemHeight * 0.6,
        cx - 1,
        stemTop + 20,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Roots
    final rootPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, soilTop + 2),
      Offset(cx - 14, soilTop + 18),
      rootPaint,
    );
    canvas.drawLine(
      Offset(cx, soilTop + 2),
      Offset(cx + 12, soilTop + 16),
      rootPaint,
    );
    canvas.drawLine(
      Offset(cx, soilTop + 5),
      Offset(cx - 8, soilTop + 20),
      rootPaint,
    );

    // Leaves (transitioning to golden)
    final leafColor = Color.lerp(
      const Color(0xFF66BB6A),
      const Color(0xFFC0CA33),
      t,
    )!;
    _drawLeaf(canvas, cx, stemTop + stemHeight * 0.25, 22, -0.5, leafColor);
    _drawLeaf(canvas, cx, stemTop + stemHeight * 0.35, 20, 0.6, leafColor);
    _drawLeaf(canvas, cx, stemTop + stemHeight * 0.50, 18, -0.4, leafColor);
    _drawLeaf(canvas, cx, stemTop + stemHeight * 0.65, 16, 0.5, leafColor);
    _drawLeaf(canvas, cx, stemTop + stemHeight * 0.78, 14, -0.3, leafColor);

    // Full grain head
    _drawGrainHead(canvas, cx - 1, stemTop + 20, 1.0, isGolden: true);
  }

  void _drawLeaf(
    Canvas canvas,
    double stemX,
    double y,
    double length,
    double angle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(stemX, y);
    canvas.rotate(angle);

    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.4, -5, length, -1)
      ..quadraticBezierTo(length * 0.4, 3, 0, 0);

    canvas.drawPath(leafPath, paint);

    // Leaf vein
    final veinPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(length * 0.85, -0.5), veinPaint);

    canvas.restore();
  }

  void _drawGrainHead(
    Canvas canvas,
    double cx,
    double topY,
    double maturity, {
    required bool isGolden,
  }) {
    final grainColor = isGolden
        ? Color.lerp(
            const Color(0xFFCDDC39),
            const Color(0xFFFFD54F),
            maturity,
          )!
        : const Color(0xFF9CCC65);

    final paint = Paint()
      ..color = grainColor
      ..style = PaintingStyle.fill;

    final grainCount = (5 * maturity).round().clamp(1, 5);
    final headHeight = 25.0 * maturity;

    for (int i = 0; i < grainCount; i++) {
      final progress = i / max(grainCount - 1, 1);
      final y = topY - headHeight + headHeight * progress;
      final xOffset = (i.isEven ? -1 : 1) * 4.0 * maturity;
      final grainAngle = (i.isEven ? -0.3 : 0.3) * maturity;

      canvas.save();
      canvas.translate(cx + xOffset, y);
      canvas.rotate(grainAngle);

      // Individual grain kernel (oval)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 6 * maturity,
          height: 10 * maturity,
        ),
        paint,
      );

      // Awn (whisker) on each grain
      if (maturity > 0.4) {
        final awnPaint = Paint()
          ..color = grainColor.withValues(alpha: 0.7)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(0, -5 * maturity),
          Offset(xOffset * 0.8, -12 * maturity),
          awnPaint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WheatGrowthPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
