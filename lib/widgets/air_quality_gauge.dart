import 'dart:math' as math;
import 'package:flutter/material.dart';

class AirQualityGauge extends StatelessWidget {
  final double pm25;
  final double pm10;
  final double progress;

  const AirQualityGauge({
    super.key,
    required this.pm25,
    required this.pm10,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: CustomPaint(
        painter: _GaugePainter(progress: progress),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'OUTDOOR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 30),
                _Reading(label: 'PM2.5', value: pm25),
                const SizedBox(height: 9),
                _Reading(label: 'PM10', value: pm10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  final String label;
  final double value;

  const _Reading({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;

  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    const start = math.pi * 1.15;
    const sweep = math.pi * 0.70;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.14
      ..color = Colors.grey.shade300;

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.07
      ..color = Colors.grey.shade200;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.14
      ..color = Colors.green.shade700;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      base,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.84),
      start,
      sweep,
      false,
      inner,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * progress.clamp(0, 1),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress;
}
