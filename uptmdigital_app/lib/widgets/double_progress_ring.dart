import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'dart:math' as math;

class DoubleProgressRing extends StatelessWidget {
  final double careerProgress; // 0.0 to 1.0
  final double periodProgress; // 0.0 to 1.0

  const DoubleProgressRing({
    super.key,
    required this.careerProgress,
    required this.periodProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: 180,
      padding: const EdgeInsets.all(10),
      child: CustomPaint(
        painter: _DoubleRingPainter(
          careerProgress: careerProgress,
          periodProgress: periodProgress,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(careerProgress * 100).toInt()}%",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const Text(
                "Total",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoubleRingPainter extends CustomPainter {
  final double careerProgress;
  final double periodProgress;

  _DoubleRingPainter({required this.careerProgress, required this.periodProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // 1. Career Progress (Outer Ring)
    final outerPaintBase = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final outerPaintProgress = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, outerPaintBase);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * careerProgress,
      false,
      outerPaintProgress,
    );

    // 2. Period Progress (Inner Ring)
    final innerRadius = radius - strokeWidth - 8;
    final innerPaintBase = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final innerPaintProgress = Paint()
      ..color = AppTheme.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, innerRadius - strokeWidth / 2, innerPaintBase);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * periodProgress,
      false,
      innerPaintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
