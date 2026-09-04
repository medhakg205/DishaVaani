// compass_needle.dart — compass dial label + rotating needle painter
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CompassLabel extends StatelessWidget {
  final String label;
  const CompassLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CompassNeedle extends StatelessWidget {
  final double size;
  const CompassNeedle({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeedlePainter()),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tipLength = size.height / 2;
    final halfWidth = size.width / 6;

    final northPaint = Paint()..color = AppColors.maroon;
    final southPaint = Paint()..color = Colors.black26;

    final northPath = Path()
      ..moveTo(center.dx, center.dy - tipLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..close();

    final southPath = Path()
      ..moveTo(center.dx, center.dy + tipLength)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..close();

    canvas.drawPath(southPath, southPaint);
    canvas.drawPath(northPath, northPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
