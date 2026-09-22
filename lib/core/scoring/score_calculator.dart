import '../database/app_database.dart';

class CategoryScore {
  final String categoryId;
  final int points;
  final int streak;
  final int bestStreak;
  final bool doneToday;

  const CategoryScore({
    required this.categoryId,
    required this.points,
    required this.streak,
    required this.bestStreak,
    required this.doneToday,
  });
}

class ScoreResult {
  final Map<String, CategoryScore> byCategory;
  const ScoreResult(this.byCategory);

  int get total =>
      byCategory.values.fold(0, (sum, c) => sum + c.points);

  int pointsOf(String categoryId) =>
      byCategory[categoryId]?.points ?? 0;

  int get doneTodayCount =>
      byCategory.values.where((c) => c.doneToday).length;

  static const empty = ScoreResult({});
}

class ScoreCalculator {
  static const int basePoints = 10;
  static const int missPenalty = 5;
  static const int perfectDayBonus = 0;

  static double multiplier(int streak) {
    if (streak >= 30) return 2.0;
    if (streak >= 14) return 1.5;
    if (streak >= 7) return 1.25;
    return 1.0;
  }

  static String tierOf(int points) {
    if (points >= 10000) return 'Diamond';
    if (points >= 4000) return 'Platinum';
    if (points >= 1500) return 'Gold';
    if (points >= 500) return 'Silver';
    return 'Bronze';
  }

  static int nextTierAt(int points) {
    for (final step in [500, 1500, 4000, 10000]) {
      if (points < step) return step;
    }
    return 10000;
  }

  static ScoreResult compute({
    required List<Habit> habits,
    required List<HabitLog> logs,
    required DateTime today,
    List<String> categoryIds = scoredCategoryIds,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final habitCategory = <String, String>{
      for (final h in habits)
        if (h.deletedAt == null) h.id: h.categoryId,
    };

    final doneDays = <String, Set<int>>{
      for (final id in categoryIds) id: <int>{},
    };

    for (final log in logs) {
      if (log.deletedAt != null || !log.isDone) continue;
      final cat = habitCategory[log.habitId];
      if (cat == null) continue;
      final bucket = doneDays[cat];
      if (bucket == null) continue;
      final d = DateTime(
          log.loggedDate.year, log.loggedDate.month, log.loggedDate.day);
      if (d.isAfter(day)) continue;
      bucket.add(_key(d));
    }

    final result = <String, CategoryScore>{};
    for (final id in categoryIds) {
      result[id] = _scoreCategory(id, doneDays[id] ?? <int>{}, day);
    }
    return ScoreResult(result);
  }

  static CategoryScore _scoreCategory(
      String categoryId, Set<int> done, DateTime today) {
    if (done.isEmpty) {
      return CategoryScore(
        categoryId: categoryId,
        points: 0,
        streak: 0,
        bestStreak: 0,
        doneToday: false,
      );
    }

    final first = _fromKey(done.reduce((a, b) => a < b ? a : b));
    var points = 0;
    var streak = 0;
    var best = 0;

    for (var d = first;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      if (done.contains(_key(d))) {
        streak++;
        if (streak > best) best = streak;
        points += (basePoints * multiplier(streak)).round();
      } else if (d.isBefore(today)) {
        points -= missPenalty;
        streak = 0;
      }
      if (points < 0) points = 0;
    }

    return CategoryScore(
      categoryId: categoryId,
      points: points,
      streak: streak,
      bestStreak: best,
      doneToday: done.contains(_key(today)),
    );
  }

  static int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime _fromKey(int k) =>
      DateTime(k ~/ 10000, (k ~/ 100) % 100, k % 100);
}
