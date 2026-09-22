import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';

class WeeklyBarChart extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;

  const WeeklyBarChart({super.key, required this.habit, required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.parseHex(habit.colorHex);
    final today = HabitDateUtils.today();

    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = days.map((day) {
      final log = logs.firstWhere(
        (l) => HabitDateUtils.isSameDay(l.loggedDate, day),
        orElse: () => HabitLog(
          id: '', habitId: habit.id,
          loggedDate: day, isDone: false,
          value: null, note: null,
          createdAt: day,
          pointsAwarded: 0,
          updatedAt: day,
          syncStatus: 'synced',
        ),
      );
      return log.value ?? (log.isDone ? (habit.targetValue ?? 1) : 0.0);
    }).toList();

    final maxVal = [
      ...values,
      habit.targetValue ?? 1,
    ].reduce((a, b) => a > b ? a : b);

    final todayIndex = days.indexWhere((d) => HabitDateUtils.isSameDay(d, today));
    final todayValue = todayIndex >= 0 ? values[todayIndex] : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(habit.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (todayValue > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'วันนี้ ${_fmt(todayValue)} ${habit.unit ?? ''}'.trim(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: color, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text('7 วันล่าสุด',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.3,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxVal / 4,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (x, _) {
                        final day = days[x.toInt()];
                        final isToday =
                            HabitDateUtils.isSameDay(day, today);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            HabitDateUtils.dayName(day.weekday),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isToday
                                  ? color
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: habit.targetValue != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: habit.targetValue!,
                          color: color.withValues(alpha: 0.4),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 4, bottom: 2),
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            labelResolver: (_) =>
                                'เป้า ${habit.targetValue!.toStringAsFixed(habit.targetValue! % 1 == 0 ? 0 : 1)}',
                          ),
                        )
                      ])
                    : null,
                barGroups: List.generate(days.length, (i) {
                  final val = values[i];
                  final isToday = HabitDateUtils.isSameDay(days[i], today);
                  final reached =
                      habit.targetValue == null || val >= (habit.targetValue ?? 0);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val == 0 ? 0 : val,
                        color: reached
                            ? color
                            : color.withValues(alpha: 0.4),
                        width: isToday ? 18 : 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal * 1.3,
                          color: color.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: const [],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.inverseSurface,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    getTooltipItem: (group, _, rod, __) {
                      final val = rod.toY;
                      return BarTooltipItem(
                        '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)} ${habit.unit ?? ''}',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
