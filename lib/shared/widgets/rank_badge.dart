import 'dart:math' as math;
import 'package:flutter/material.dart';

class RankTier {
  final String name;
  final String label;
  final List<Color> gradient;
  final Color ring;
  final int stars;
  const RankTier(this.name, this.label, this.gradient, this.ring, this.stars);
}

const rankTiers = <String, RankTier>{
  'Bronze': RankTier('Bronze', 'บรอนซ์',
      [Color(0xFFD9A066), Color(0xFF8B5A2B)], Color(0xFFE8C39E), 1),
  'Silver': RankTier('Silver', 'ซิลเวอร์',
      [Color(0xFFE3E8EE), Color(0xFF8A97A8)], Color(0xFFF1F5F9), 2),
  'Gold': RankTier('Gold', 'โกลด์',
      [Color(0xFFFFD75E), Color(0xFFD29200)], Color(0xFFFFE9A8), 3),
  'Platinum': RankTier('Platinum', 'แพลตินัม',
      [Color(0xFF9FE8E0), Color(0xFF2E8B8B)], Color(0xFFCDF3EE), 4),
  'Diamond': RankTier('Diamond', 'ไดมอนด์',
      [Color(0xFFB8D8FF), Color(0xFF3C6FE0)], Color(0xFFDCEBFF), 5),
};

RankTier tierInfo(String name) => rankTiers[name] ?? rankTiers['Bronze']!;

class RankBadge extends StatelessWidget {
  final String tier;
  final double size;
  final bool showStars;

  const RankBadge({
    super.key,
    required this.tier,
    this.size = 56,
    this.showStars = true,
  });

  @override
  Widget build(BuildContext context) {
    final info = tierInfo(tier);
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(
        painter: _BadgePainter(info, showStars),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.16),
            child: Icon(
              Icons.bolt_rounded,
              size: size * 0.38,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final RankTier tier;
  final bool showStars;
  _BadgePainter(this.tier, this.showStars);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shieldH = h * 0.86;
    final path = _shield(w, shieldH);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 3, false);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: tier.gradient,
      ).createShader(Rect.fromLTWH(0, 0, w, shieldH));
    canvas.drawPath(path, fill);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..color = tier.ring;
    canvas.drawPath(path, edge);

    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, shieldH * 0.55));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, shieldH * 0.55), gloss);
    canvas.restore();

    if (!showStars) return;
    final count = tier.stars;
    final starSize = w * 0.11;
    final gap = starSize * 1.55;
    final totalW = gap * (count - 1);
    final cy = h - starSize * 1.1;
    for (var i = 0; i < count; i++) {
      final cx = w / 2 - totalW / 2 + gap * i;
      _star(canvas, Offset(cx, cy), starSize, tier.ring);
    }
  }

  Path _shield(double w, double h) {
    final p = Path();
    final inset = w * 0.06;
    p.moveTo(inset, h * 0.12);
    p.lineTo(w / 2, 0);
    p.lineTo(w - inset, h * 0.12);
    p.lineTo(w - inset, h * 0.52);
    p.quadraticBezierTo(w - inset, h * 0.88, w / 2, h);
    p.quadraticBezierTo(inset, h * 0.88, inset, h * 0.52);
    p.close();
    return p;
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final x = c.dx + radius * math.cos(angle);
      final y = c.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.tier.name != tier.name || old.showStars != showStars;
}
