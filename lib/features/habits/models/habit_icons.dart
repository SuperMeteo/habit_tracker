import 'package:flutter/material.dart';

class HabitIcons {
  static const List<IconData> available = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.self_improvement,
    Icons.restaurant,
    Icons.water_drop,
    Icons.bedtime,
    Icons.book,
    Icons.code,
    Icons.work,
    Icons.attach_money,
    Icons.savings,
    Icons.music_note,
    Icons.brush,
    Icons.favorite,
    Icons.emoji_emotions,
    Icons.local_hospital,
    Icons.school,
    Icons.language,
    Icons.psychology,
    Icons.spa,
    Icons.hiking,
    Icons.directions_bike,
    Icons.sports_tennis,
    Icons.sports_soccer,
    Icons.laptop,
    Icons.timer,
    Icons.checklist,
    Icons.pool,
    Icons.monitor_weight,
    Icons.eco,
    Icons.no_food,
    Icons.edit_note,
    Icons.headphones,
    Icons.star,
  ];

  static IconData fromCode(int code) {
    return available.firstWhere(
      (icon) => icon.codePoint == code,
      orElse: () => Icons.star,
    );
  }

  static int defaultCode = Icons.star.codePoint;
}
