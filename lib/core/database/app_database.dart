import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables/categories_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _insertDefaultCategories();
        },
      );

  Future<void> _insertDefaultCategories() async {
    final defaults = [
      CategoriesCompanion(
          name: const Value('สุขภาพ'),
          colorHex: const Value('#EF4444'),
          iconCode: const Value(0xe3a3)),
      CategoriesCompanion(
          name: const Value('ผลิตภาพ'),
          colorHex: const Value('#8B5CF6'),
          iconCode: const Value(0xe8d5)),
      CategoriesCompanion(
          name: const Value('การเงิน'),
          colorHex: const Value('#10B981'),
          iconCode: const Value(0xe8e5)),
      CategoriesCompanion(
          name: const Value('การเรียนรู้'),
          colorHex: const Value('#F59E0B'),
          iconCode: const Value(0xe865)),
      CategoriesCompanion(
          name: const Value('อื่นๆ'),
          colorHex: const Value('#6366F1'),
          iconCode: const Value(0xe7f7)),
    ];
    for (final cat in defaults) {
      await into(categories).insert(cat);
    }
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Stream<List<Category>> watchAllCategories() =>
      select(categories).watch();

  Future<List<Category>> getAllCategories() =>
      select(categories).get();

  // ─── Habits ───────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchActiveHabits() =>
      (select(habits)..where((h) => h.isActive.equals(true))).watch();

  Future<List<Habit>> getActiveHabits() =>
      (select(habits)..where((h) => h.isActive.equals(true))).get();

  Future<int> insertHabit(HabitsCompanion habit) =>
      into(habits).insert(habit);

  Future<bool> updateHabit(HabitsCompanion habit) =>
      update(habits).replace(habit);

  Future<int> deleteHabit(int id) =>
      (delete(habits)..where((h) => h.id.equals(id))).go();

  // ─── Habit Logs ───────────────────────────────────────────────────────────

  Stream<List<HabitLog>> watchLogsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(habitLogs)
          ..where((l) =>
              l.loggedDate.isBiggerOrEqualValue(dayStart) &
              l.loggedDate.isSmallerThanValue(dayEnd)))
        .watch();
  }

  Future<List<HabitLog>> getLogsForDateRange(
      DateTime start, DateTime end) {
    return (select(habitLogs)
          ..where((l) =>
              l.loggedDate.isBiggerOrEqualValue(start) &
              l.loggedDate.isSmallerThanValue(end))
          ..orderBy([(l) => OrderingTerm.asc(l.loggedDate)]))
        .get();
  }

  Future<HabitLog?> getLogForHabitAndDate(
      int habitId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final results = await (select(habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.loggedDate.isBiggerOrEqualValue(dayStart) &
              l.loggedDate.isSmallerThanValue(dayEnd)))
        .get();
    return results.isEmpty ? null : results.first;
  }

  Future<int> upsertLog(HabitLogsCompanion log) =>
      into(habitLogs).insertOnConflictUpdate(log);

  Future<int> deleteLog(int id) =>
      (delete(habitLogs)..where((l) => l.id.equals(id))).go();

  Future<List<HabitLog>> getAllLogsForHabit(int habitId) =>
      (select(habitLogs)
            ..where((l) => l.habitId.equals(habitId))
            ..orderBy([(l) => OrderingTerm.asc(l.loggedDate)]))
          .get();
}
