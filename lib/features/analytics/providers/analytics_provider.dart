import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../core/utils/date_utils.dart';
import '../../habits/providers/habits_provider.dart';

class HabitStats {
  final Habit habit;
  final int currentStreak;
  final int longestStreak;
  final double weeklyRate;
  final List<HabitLog> recentLogs;

  const HabitStats({
    required this.habit,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyRate,
    required this.recentLogs,
  });
}

final analyticsProvider =
    FutureProvider.autoDispose<List<HabitStats>>((ref) async {
  final db = ref.watch(databaseProvider);
  final habitsAsync = ref.watch(habitsProvider);

  final habits = habitsAsync.valueOrNull ?? [];
  final results = <HabitStats>[];

  final now = DateTime.now();
  final weekStart = HabitDateUtils.startOfWeek(
      DateTime(now.year, now.month, now.day));
  final weekEnd = weekStart.add(const Duration(days: 7));

  for (final habit in habits) {
    final allLogs = await db.getAllLogsForHabit(habit.id);
    final weekLogs = await db.getLogsForDateRange(weekStart, weekEnd);
    final habitWeekLogs = weekLogs.where((l) => l.habitId == habit.id).toList();

    final streaks = StreakCalculator.calculate(habit: habit, logs: allLogs);
    final weeklyRate = StreakCalculator.weeklyCompletionRate(
      habit: habit,
      logsThisWeek: habitWeekLogs,
      weekStart: weekStart,
    );

    results.add(HabitStats(
      habit: habit,
      currentStreak: streaks['current'] ?? 0,
      longestStreak: streaks['longest'] ?? 0,
      weeklyRate: weeklyRate,
      recentLogs: allLogs.reversed.take(30).toList(),
    ));
  }

  return results;
});

// heatmap: date → completion count across all habits
final heatmapProvider =
    FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final yearAgo = now.subtract(const Duration(days: 365));
  final logs = await db.getLogsForDateRange(yearAgo, now);

  final map = <DateTime, int>{};
  for (final log in logs) {
    if (!log.isDone) continue;
    final key = DateTime(
        log.loggedDate.year, log.loggedDate.month, log.loggedDate.day);
    map[key] = (map[key] ?? 0) + 1;
  }
  return map;
});
