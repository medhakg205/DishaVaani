// compass_needle.dart — compass dial label + rotating needle painter
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CompassLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isDark;
  const CompassLabel(this.label, {super.key, this.color, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    Color textColor = color ?? (isDark ? Colors.white.withOpacity(0.5) : Colors.black45);
    if (label == 'N') {
      textColor = isDark ? const Color(0xFFE5A17D) : AppColors.maroon;
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: label == 'N' ? 17 : 15,
          color: textColor,
          fontWeight: FontWeight.bold,
          shadows: isDark && label == 'N'
              ? [
                  Shadow(
                    color: const Color(0xFFE5A17D).withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class CompassNeedle extends StatelessWidget {
  final double size;
  final bool isDark;
  const CompassNeedle({super.key, this.size = 70, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _NeedlePainter(isDark: isDark),
          ),
          Container(
            width: size * 0.16,
            height: size * 0.16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF281E24) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFFE5A17D) : AppColors.terracotta,
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final bool isDark;
  _NeedlePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tipLength = size.height * 0.48;
    final halfWidth = size.width * 0.11;

    // North Needle (with subtle bevel / gradient shading)
    final northPaintLeft = Paint()
      ..color = isDark ? const Color(0xFFE5A17D) : AppColors.maroon;
    final northPaintRight = Paint()
      ..color = isDark ? const Color(0xFF8B2B3A) : const Color(0xFF531720);

    final northLeftPath = Path()
      ..moveTo(center.dx, center.dy - tipLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final northRightPath = Path()
      ..moveTo(center.dx, center.dy - tipLength)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    // South Needle (matte dark metal / silver)
    final southPaintLeft = Paint()
      ..color = isDark ? const Color(0xFF635F6A) : Colors.black38;
    final southPaintRight = Paint()
      ..color = isDark ? const Color(0xFF38353D) : Colors.black26;

    final southLeftPath = Path()
      ..moveTo(center.dx, center.dy + tipLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final southRightPath = Path()
      ..moveTo(center.dx, center.dy + tipLength)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(southLeftPath, southPaintLeft);
    canvas.drawPath(southRightPath, southPaintRight);
    canvas.drawPath(northLeftPath, northPaintLeft);
    canvas.drawPath(northRightPath, northPaintRight);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
