import 'package:flutter/material.dart';
import 'package:sakasama/core/constants/app_colors.dart';

/// CustomPainter that draws a green rectangular scan guide frame
/// over the camera preview area.
class ScanOverlayPainter extends CustomPainter {
  ScanOverlayPainter({
    this.borderColor = AppColors.primaryGreen,
    this.borderWidth = 3.0,
    this.cornerLength = 30.0,
    this.cornerRadius = 8.0,
    this.overlayColor,
  });

  final Color borderColor;
  final double borderWidth;
  final double cornerLength;
  final double cornerRadius;
  final Color? overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.45,
    );

    // ── Dim overlay outside scan area ─────────────────────────────────
    final dimColor = overlayColor ?? Colors.black.withValues(alpha: 0.5);
    final dimPaint = Paint()..color = dimColor;

    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, scanRect.top), dimPaint);
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        scanRect.bottom,
        size.width,
        size.height - scanRect.bottom,
      ),
      dimPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height),
      dimPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(
        scanRect.right,
        scanRect.top,
        size.width - scanRect.right,
        scanRect.height,
      ),
      dimPaint,
    );

    // ── Corner brackets ───────────────────────────────────────────────
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + cornerLength),
      Offset(scanRect.left, scanRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left + cornerLength, scanRect.top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.top),
      Offset(scanRect.right, scanRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right, scanRect.top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      Offset(scanRect.left, scanRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ScanOverlayPainter oldDelegate) {
    return borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}
