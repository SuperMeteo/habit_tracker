import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

// ─── Database provider ─────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── Categories ────────────────────────────────────────────────────────────

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchAllCategories();
});

// ─── Active habits ─────────────────────────────────────────────────────────

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(databaseProvider).watchActiveHabits();
});

// ─── Logs for selected date ────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final logsForDateProvider = StreamProvider<List<HabitLog>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchLogsForDate(date);
});

// ─── Combined habit + log for dashboard ───────────────────────────────────

class HabitWithLog {
  final Habit habit;
  final HabitLog? log;
  const HabitWithLog({required this.habit, this.log});
}

final dashboardProvider = Provider<AsyncValue<List<HabitWithLog>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final logsAsync = ref.watch(logsForDateProvider);
  final date = ref.watch(selectedDateProvider);

  return habitsAsync.when(
    data: (habits) => logsAsync.when(
      data: (logs) {
        final activeHabits = habits.where((h) => _isTargetDay(h, date)).toList();
        return AsyncData(activeHabits.map((habit) {
          final log = logs.cast<HabitLog?>().firstWhere(
            (l) => l?.habitId == habit.id,
            orElse: () => null,
          );
          return HabitWithLog(habit: habit, log: log);
        }).toList());
      },
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
    ),
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

bool _isTargetDay(Habit habit, DateTime date) {
  if (habit.frequencyType == 'daily') return true;
  if (habit.frequencyType == 'specific_days') {
    final days = List<int>.from(jsonDecode(habit.targetDays));
    return days.contains(date.weekday);
  }
  return true;
}

// ─── Habit mutations ────────────────────────────────────────────────────────

final habitActionsProvider = Provider<HabitActions>((ref) {
  return HabitActions(ref.watch(databaseProvider));
});

class HabitActions {
  final AppDatabase _db;
  HabitActions(this._db);

  Future<void> addHabit(HabitsCompanion companion) =>
      _db.insertHabit(companion);

  Future<void> updateHabit(HabitsCompanion companion) =>
      _db.updateHabit(companion);

  Future<void> deleteHabit(String id) => _db.deleteHabit(id);

  Future<void> toggleHabit(String habitId, DateTime date, bool? currentDone) async {
    final existing = await _db.getLogForHabitAndDate(habitId, date);
    if (existing != null) {
      await _db.upsertLog(HabitLogsCompanion(
        id: Value(existing.id),
        habitId: Value(habitId),
        loggedDate: Value(date),
        isDone: Value(!(existing.isDone)),
      ));
    } else {
      await _db.upsertLog(HabitLogsCompanion(
        habitId: Value(habitId),
        loggedDate: Value(date),
        isDone: const Value(true),
      ));
    }
  }

  Future<void> logNumericValue(
      String habitId, DateTime date, double value) async {
    final existing = await _db.getLogForHabitAndDate(habitId, date);
    await _db.upsertLog(HabitLogsCompanion(
      id: existing != null ? Value(existing.id) : const Value.absent(),
      habitId: Value(habitId),
      loggedDate: Value(date),
      isDone: Value(value > 0),
      value: Value(value),
    ));
  }
}
