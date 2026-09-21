import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double value;
  final Color color;
  final Color? trackColor;
  final double size;
  final double stroke;
  final Widget? child;
  final bool animate;

  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.trackColor,
    this.size = 72,
    this.stroke = 7,
    this.child,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final track = trackColor ?? color.withValues(alpha: 0.18);

    if (!animate) {
      return _paint(target, track);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => _paint(v, track),
    );
  }

  Widget _paint(double v, Color track) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value: v, color: color, track: track, stroke: stroke),
          child: child == null ? null : Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    if (value <= 0) return;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}
