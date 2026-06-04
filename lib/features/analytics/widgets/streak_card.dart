import 'package:flutter/material.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../habits/models/habit_icons.dart';

class StreakCard extends StatelessWidget {
  final HabitStats stats;
  const StreakCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.parseHex(stats.habit.colorHex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(HabitIcons.fromCode(stats.habit.iconCode),
                      color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(stats.habit.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _StreakBadge(
                    value: stats.currentStreak, label: 'streak', color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                    label: 'streak ปัจจุบัน',
                    value: '${stats.currentStreak} วัน',
                    icon: Icons.local_fire_department,
                    color: Colors.orange),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'ยาวที่สุด',
                    value: '${stats.longestStreak} วัน',
                    icon: Icons.emoji_events,
                    color: Colors.amber),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'สัปดาห์นี้',
                    value: '${(stats.weeklyRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.bar_chart,
                    color: color),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.weeklyRate,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StreakBadge(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.orange, size: 14),
          const SizedBox(width: 2),
          Text('$value',
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
