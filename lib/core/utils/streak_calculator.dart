import 'dart:convert';
import '../../core/database/app_database.dart';

class StreakCalculator {
  /// คำนวณ current streak และ longest streak ของ habit
  static Map<String, int> calculate({
    required Habit habit,
    required List<HabitLog> logs,
  }) {
    if (logs.isEmpty) return {'current': 0, 'longest': 0};

    final doneDates = logs
        .where((l) => l.isDone)
        .map((l) => _normalizeDate(l.loggedDate))
        .toSet();

    final targetDaysList = _parseTargetDays(habit.targetDays);
    final today = _normalizeDate(DateTime.now());

    int current = 0;
    int longest = 0;
    int streak = 0;
    bool counting = true;

    // วนย้อนหลังจากวันนี้
    DateTime cursor = today;
    for (int i = 0; i < 365; i++) {
      final isTarget = _isTargetDay(cursor, habit.frequencyType, targetDaysList);
      if (!isTarget) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (doneDates.contains(cursor)) {
        streak++;
        if (counting) current = streak;
        longest = streak > longest ? streak : longest;
      } else {
        // วันแรก (วันนี้) ยังไม่ได้ log ก็ยังไม่ถือว่าขาด
        if (i == 0) {
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        counting = false;
        streak = 0;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return {'current': current, 'longest': longest};
  }

  /// completion rate รายสัปดาห์ (0.0 - 1.0)
  static double weeklyCompletionRate({
    required Habit habit,
    required List<HabitLog> logsThisWeek,
    required DateTime weekStart,
  }) {
    final targetDaysList = _parseTargetDays(habit.targetDays);
    int targetCount = 0;
    int doneCount = 0;
    final today = _normalizeDate(DateTime.now());

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final normalized = _normalizeDate(day);
      if (normalized.isAfter(today)) break;
      if (_isTargetDay(normalized, habit.frequencyType, targetDaysList)) {
        targetCount++;
        final done = logsThisWeek.any(
          (l) => _normalizeDate(l.loggedDate) == normalized && l.isDone,
        );
        if (done) doneCount++;
      }
    }
    if (targetCount == 0) return 0.0;
    return doneCount / targetCount;
  }

  static bool _isTargetDay(
      DateTime date, String frequencyType, List<int> targetDays) {
    if (frequencyType == 'daily') return true;
    if (frequencyType == 'specific_days') {
      return targetDays.contains(date.weekday); // Mon=1, Sun=7
    }
    return true;
  }

  static List<int> _parseTargetDays(String json) {
    try {
      return List<int>.from(jsonDecode(json));
    } catch (_) {
      return [1, 2, 3, 4, 5, 6, 7];
    }
  }

  static DateTime _normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
