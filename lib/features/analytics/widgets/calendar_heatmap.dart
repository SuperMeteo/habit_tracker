import 'package:flutter/material.dart';

class CalendarHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final int maxValue;

  const CalendarHeatmap({
    super.key,
    required this.data,
    this.maxValue = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 364));

    // align to Monday
    final startMonday =
        start.subtract(Duration(days: start.weekday - 1));

    final weeks = <List<DateTime?>>[];
    var cursor = startMonday;
    while (!cursor.isAfter(today)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = cursor.add(Duration(days: d));
        week.add(day.isAfter(today) ? null : day);
      }
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Activity ย้อนหลัง 1 ปี',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks.map((week) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Column(
                  children: week.map((day) {
                    if (day == null) {
                      return const SizedBox(width: 12, height: 15);
                    }
                    final key = DateTime(day.year, day.month, day.day);
                    final count = data[key] ?? 0;
                    final intensity =
                        maxValue == 0 ? 0.0 : (count / maxValue).clamp(0.0, 1.0);
                    return Tooltip(
                      message:
                          '${day.day}/${day.month}: $count habit${count != 1 ? 's' : ''}',
                      child: Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: count == 0
                              ? color.withValues(alpha: 0.07)
                              : color.withValues(
                                  alpha: 0.2 + intensity * 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('น้อย',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final alpha = 0.1 + (i / 4) * 0.9;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: alpha),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text('มาก',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      ],
    );
  }
}
