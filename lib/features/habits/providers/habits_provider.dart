import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/sync/sync_service.dart';

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

final categoryHabitCountsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).watchHabitCountsByCategory();
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

final logsForSelectedWeekProvider = StreamProvider<List<HabitLog>>((ref) {
  final weekStart = ref.watch(
      selectedDateProvider.select((d) => HabitDateUtils.startOfWeek(d)));
  return ref
      .watch(databaseProvider)
      .watchLogsForDateRange(weekStart, weekStart.add(const Duration(days: 7)));
});

// ─── Combined habit + log for dashboard ───────────────────────────────────

class HabitWithLog {
  final Habit habit;
  final HabitLog? log;
  final int weekDoneCount;
  const HabitWithLog({required this.habit, this.log, this.weekDoneCount = 0});
}

final dashboardProvider = Provider<AsyncValue<List<HabitWithLog>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final logsAsync = ref.watch(logsForDateProvider);
  final weekLogsAsync = ref.watch(logsForSelectedWeekProvider);
  final date = ref.watch(selectedDateProvider);
  final weekStart = HabitDateUtils.startOfWeek(date);

  return habitsAsync.when(
    data: (habits) => logsAsync.when(
      data: (logs) => weekLogsAsync.when(
        data: (weekLogs) {
          final activeHabits =
              habits.where((h) => _isTargetDay(h, date)).toList();
          return AsyncData(activeHabits.map((habit) {
            final log = logs.cast<HabitLog?>().firstWhere(
              (l) => l?.habitId == habit.id,
              orElse: () => null,
            );
            final weekDoneCount = habit.frequencyType == 'times_per_week'
                ? StreakCalculator.weeklyDoneCount(
                    logs: weekLogs.where((l) => l.habitId == habit.id).toList(),
                    weekStart: weekStart,
                  )
                : 0;
            return HabitWithLog(
                habit: habit, log: log, weekDoneCount: weekDoneCount);
          }).toList());
        },
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
      ),
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
  return HabitActions(ref.watch(databaseProvider), ref);
});

class HabitActions {
  final AppDatabase _db;
  final Ref _ref;
  HabitActions(this._db, this._ref);

  void _scheduleSync() =>
      _ref.read(syncServiceProvider.notifier).scheduleSync();

  Future<void> addHabit(HabitsCompanion companion) async {
    final id = await _db.insertHabit(companion);
    await _syncReminder(id);
    _scheduleSync();
  }

  Future<void> updateHabit(HabitsCompanion companion) async {
    await _db.updateHabit(companion);
    await _syncReminder(companion.id.value);
    _scheduleSync();
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
    await NotificationService.instance.cancelForHabit(id);
    _scheduleSync();
  }

  Future<void> _syncReminder(String id) async {
    final habit = await _db.getHabit(id);
    if (habit == null) {
      await NotificationService.instance.cancelForHabit(id);
    } else {
      await NotificationService.instance.scheduleForHabit(habit);
    }
  }

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
    _scheduleSync();
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
    _scheduleSync();
  }
}
