import 'package:flutter/material.dart';
import 'dart:math';

// --- SPEEDOMETER WIDGET ---
class Speedometer extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeed;
  final String unit;

  const Speedometer({
    super.key,
    required this.currentSpeed,
    this.maxSpeed = 60.0,
    this.unit = 'km/h',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: currentSpeed),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedSpeed, child) {
        return SizedBox(
          width: 280, 
          height: 280,
          child: CustomPaint(
            painter: SpeedGaugePainter(
              currentSpeed: animatedSpeed,
              maxSpeed: maxSpeed,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animatedSpeed.toStringAsFixed(1), 
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- SPEED O METER PAINTER ---
class SpeedGaugePainter extends CustomPainter {
  final double currentSpeed;
  final double maxSpeed;

  SpeedGaugePainter({required this.currentSpeed, required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 
      ..strokeCap = StrokeCap.round; 

    const startAngle = 135 * (pi / 180); 
    const sweepAngle = 270 * (pi / 180); 

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    final percent = (currentSpeed / maxSpeed).clamp(0.0, 1.0);
    final activeSweepAngle = sweepAngle * percent;

    final activeColor = Color.lerp(
      const Color(0xFF00E5FF), 
      const Color(0xFFFF1744), 
      percent,
    )!;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    if (percent > 0) {
      canvas.drawArc(rect, startAngle, activeSweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedGaugePainter oldDelegate) {
    return oldDelegate.currentSpeed != currentSpeed;
  }
}