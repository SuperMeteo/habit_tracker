import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'tables/categories_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

@DriftDatabase(tables: [Categories, Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _insertDefaultCategories();
        },
        // v1 (int PK) → v2 (UUID PK + sync fields): โครงสร้าง PK เปลี่ยนระดับ
        // ราก จึงสร้างใหม่ทั้งหมด (ยอมรับได้ในช่วง dev ที่ข้อมูลยังน้อย)
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.deleteTable(habitLogs.actualTableName);
            await m.deleteTable(habits.actualTableName);
            await m.deleteTable(categories.actualTableName);
            await m.createAll();
            await _insertDefaultCategories();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _insertDefaultCategories() async {
    final defaults = [
      ('สุขภาพ', '#EF4444', 0xe3a3),
      ('ผลิตภาพ', '#8B5CF6', 0xe8d5),
      ('การเงิน', '#10B981', 0xe8e5),
      ('การเรียนรู้', '#F59E0B', 0xe865),
      ('อื่นๆ', '#6366F1', 0xe7f7),
    ];
    for (final (name, color, icon) in defaults) {
      await into(categories).insert(CategoriesCompanion(
        id: Value(_uuid.v4()),
        name: Value(name),
        colorHex: Value(color),
        iconCode: Value(icon),
        syncStatus: const Value('synced'),
      ));
    }
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..where((c) => c.deletedAt.isNull())).watch();

  Future<List<Category>> getAllCategories() =>
      (select(categories)..where((c) => c.deletedAt.isNull())).get();

  // ─── Habits ───────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchActiveHabits() => (select(habits)
        ..where((h) => h.isActive.equals(true) & h.deletedAt.isNull()))
      .watch();

  Future<List<Habit>> getActiveHabits() => (select(habits)
        ..where((h) => h.isActive.equals(true) & h.deletedAt.isNull()))
      .get();

  /// สร้าง habit ใหม่ — gen UUID ให้ถ้ายังไม่มี id + ตั้ง sync fields
  Future<void> insertHabit(HabitsCompanion habit) async {
    final ready = habit.copyWith(
      id: habit.id.present ? habit.id : Value(_uuid.v4()),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
    );
    await into(habits).insert(ready);
  }

  Future<bool> updateHabit(HabitsCompanion habit) {
    final ready = habit.copyWith(
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
    );
    return update(habits).replace(ready);
  }

  /// soft delete — เก็บ deletedAt ไว้เพื่อ sync การลบข้ามเครื่อง
  Future<int> deleteHabit(String id) => (update(habits)
        ..where((h) => h.id.equals(id)))
      .write(HabitsCompanion(
        deletedAt: Value(DateTime.now()),
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ));

  // ─── Habit Logs ───────────────────────────────────────────────────────────

  Stream<List<HabitLog>> watchLogsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(habitLogs)
          ..where((l) =>
              l.loggedDate.isBiggerOrEqualValue(dayStart) &
              l.loggedDate.isSmallerThanValue(dayEnd) &
              l.deletedAt.isNull()))
        .watch();
  }

  Future<List<HabitLog>> getLogsForDateRange(
      DateTime start, DateTime end) {
    return (select(habitLogs)
          ..where((l) =>
              l.loggedDate.isBiggerOrEqualValue(start) &
              l.loggedDate.isSmallerThanValue(end) &
              l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.asc(l.loggedDate)]))
        .get();
  }

  Future<HabitLog?> getLogForHabitAndDate(
      String habitId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final results = await (select(habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.loggedDate.isBiggerOrEqualValue(dayStart) &
              l.loggedDate.isSmallerThanValue(dayEnd) &
              l.deletedAt.isNull()))
        .get();
    return results.isEmpty ? null : results.first;
  }

  /// upsert log — gen UUID ถ้ายังไม่มี id + ตั้ง sync fields
  Future<void> upsertLog(HabitLogsCompanion log) async {
    final ready = log.copyWith(
      id: log.id.present ? log.id : Value(_uuid.v4()),
      updatedAt: Value(DateTime.now()),
      deletedAt: const Value(null), // re-activate ถ้าเคยถูก soft-delete
      syncStatus: const Value('pending'),
    );
    await into(habitLogs).insertOnConflictUpdate(ready);
  }

  Future<int> deleteLog(String id) => (update(habitLogs)
        ..where((l) => l.id.equals(id)))
      .write(HabitLogsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ));

  Future<List<HabitLog>> getAllLogsForHabit(String habitId) =>
      (select(habitLogs)
            ..where((l) => l.habitId.equals(habitId) & l.deletedAt.isNull())
            ..orderBy([(l) => OrderingTerm.asc(l.loggedDate)]))
          .get();

  // ─── Sync support ─────────────────────────────────────────────────────────

  /// แถวที่ยังไม่ได้ push ขึ้น server (รวมแถวที่ถูก soft-delete ด้วย)
  Future<List<Habit>> getPendingHabits() =>
      (select(habits)..where((h) => h.syncStatus.equals('pending'))).get();

  Future<List<HabitLog>> getPendingLogs() =>
      (select(habitLogs)..where((l) => l.syncStatus.equals('pending'))).get();

  Future<void> markHabitsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(habits)..where((h) => h.id.isIn(ids)))
        .write(const HabitsCompanion(syncStatus: Value('synced')));
  }

  Future<void> markLogsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(habitLogs)..where((l) => l.id.isIn(ids)))
        .write(const HabitLogsCompanion(syncStatus: Value('synced')));
  }

  /// ผูกข้อมูลที่สร้างตอนเป็น guest (userId = null) เข้ากับบัญชีที่เพิ่ง login
  Future<void> claimGuestData(String userId) async {
    await (update(habits)..where((h) => h.userId.isNull())).write(
      HabitsCompanion(
        userId: Value(userId),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(habitLogs)..where((l) => l.userId.isNull())).write(
      HabitLogsCompanion(
        userId: Value(userId),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// เขียนข้อมูลที่ pull มาจาก server ลง local (last-write-wins ด้วย updatedAt)
  Future<void> applyRemoteHabit(HabitsCompanion row) =>
      into(habits).insertOnConflictUpdate(row);

  Future<void> applyRemoteLog(HabitLogsCompanion row) =>
      into(habitLogs).insertOnConflictUpdate(row);

  Future<Habit?> findHabitById(String id) =>
      (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<HabitLog?> findLogById(String id) =>
      (select(habitLogs)..where((l) => l.id.equals(id))).getSingleOrNull();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'habit_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
