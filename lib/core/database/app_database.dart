import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection/connection.dart';
import 'tables/categories_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

const defaultCategoryIds = {
  'สุขภาพ': '11111111-1111-4111-8111-111111111101',
  'ผลิตภาพ': '11111111-1111-4111-8111-111111111102',
  'การเงิน': '11111111-1111-4111-8111-111111111103',
  'การเรียนรู้': '11111111-1111-4111-8111-111111111104',
  'อื่นๆ': '11111111-1111-4111-8111-111111111105',
};

@DriftDatabase(tables: [Categories, Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _insertDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _migrateIntIdsToUuid(m);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _migrateIntIdsToUuid(Migrator m) async {
    final oldCategories =
        await customSelect('SELECT * FROM categories').get();
    final oldHabits = await customSelect('SELECT * FROM habits').get();
    final oldLogs = await customSelect('SELECT * FROM habit_logs').get();

    await m.deleteTable('habit_logs');
    await m.deleteTable('habits');
    await m.deleteTable('categories');
    await m.createAll();

    if (oldCategories.isEmpty) {
      await _insertDefaultCategories();
      return;
    }

    final categoryIds = <int, String>{};
    final usedIds = <String>{};
    for (final row in oldCategories) {
      final fixedId = defaultCategoryIds[row.read<String>('name')];
      final newId =
          fixedId != null && usedIds.add(fixedId) ? fixedId : _uuid.v4();
      categoryIds[row.read<int>('id')] = newId;
      await into(categories).insert(CategoriesCompanion.insert(
        id: newId,
        name: row.read<String>('name'),
        colorHex: Value(row.read<String>('color_hex')),
        iconCode: Value(row.read<int>('icon_code')),
        createdAt: Value(row.read<DateTime>('created_at')),
        syncStatus: const Value('pending'),
      ));
    }

    final habitIds = <int, String>{};
    for (final row in oldHabits) {
      final oldCategoryId = row.read<int>('category_id');
      final newCategoryId = categoryIds[oldCategoryId];
      if (newCategoryId == null) continue;

      final newId = _uuid.v4();
      habitIds[row.read<int>('id')] = newId;
      await into(habits).insert(HabitsCompanion.insert(
        id: newId,
        categoryId: newCategoryId,
        name: row.read<String>('name'),
        description: Value(row.read<String>('description')),
        frequencyType: Value(row.read<String>('frequency_type')),
        targetDays: Value(row.read<String>('target_days')),
        timesPerWeek: Value(row.read<int>('times_per_week')),
        targetValue: Value(row.read<double?>('target_value')),
        unit: Value(row.read<String?>('unit')),
        reminderTime: Value(row.read<String?>('reminder_time')),
        colorHex: Value(row.read<String>('color_hex')),
        iconCode: Value(row.read<int>('icon_code')),
        isActive: Value(row.read<bool>('is_active')),
        createdAt: Value(row.read<DateTime>('created_at')),
        syncStatus: const Value('pending'),
      ));
    }

    for (final row in oldLogs) {
      final newHabitId = habitIds[row.read<int>('habit_id')];
      if (newHabitId == null) continue;

      await into(habitLogs).insert(HabitLogsCompanion.insert(
        id: _uuid.v4(),
        habitId: newHabitId,
        loggedDate: row.read<DateTime>('logged_date'),
        isDone: Value(row.read<bool>('is_done')),
        value: Value(row.read<double?>('value')),
        note: Value(row.read<String?>('note')),
        createdAt: Value(row.read<DateTime>('created_at')),
        syncStatus: const Value('pending'),
      ));
    }
  }

  Future<void> _insertDefaultCategories() async {
    final defaults = [
      ('สุขภาพ', '#EF4444', 0xe3a3),
      ('ผลิตภาพ', '#8B5CF6', 0xe8d5),
      ('การเงิน', '#10B981', 0xe8e5),
      ('การเรียนรู้', '#F59E0B', 0xe865),
      ('อื่นๆ', '#6366F1', 0xe7f7),
    ];
    for (final (name, color, icon) in defaults) {
      await into(categories).insert(CategoriesCompanion.insert(
        id: defaultCategoryIds[name]!,
        name: name,
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

  Future<String> resolveCategoryId(String? remoteCategoryId) async {
    if (remoteCategoryId != null && remoteCategoryId.isNotEmpty) {
      final found = await (select(categories)
            ..where((c) => c.id.equals(remoteCategoryId)))
          .getSingleOrNull();
      if (found != null) return found.id;
    }
    final first = await (select(categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (first != null) return first.id;
    await _insertDefaultCategories();
    return defaultCategoryIds.values.first;
  }

  Future<String> insertCategory(String name, String colorHex) async {
    final id = _uuid.v4();
    await into(categories).insert(CategoriesCompanion.insert(
      id: id,
      name: name,
      colorHex: Value(colorHex),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
    ));
    return id;
  }

  Future<int> updateCategory(String id, String name, String colorHex) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(
              name: Value(name),
              colorHex: Value(colorHex),
              updatedAt: Value(DateTime.now()),
              syncStatus: const Value('pending')));

  Future<CategoryDeleteResult> deleteCategory(String id) {
    return transaction(() async {
      if (await countHabitsInCategory(id) > 0) {
        return CategoryDeleteResult.inUse;
      }
      if ((await getAllCategories()).length <= 1) {
        return CategoryDeleteResult.lastOne;
      }
      await (update(categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(
              deletedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
              syncStatus: const Value('pending')));
      return CategoryDeleteResult.deleted;
    });
  }

  Future<int> countHabitsInCategory(String categoryId) {
    final count = habits.id.count();
    return (selectOnly(habits)
          ..addColumns([count])
          ..where(habits.categoryId.equals(categoryId) &
              habits.deletedAt.isNull()))
        .map((r) => r.read(count) ?? 0)
        .getSingle();
  }

  Stream<Map<String, int>> watchHabitCountsByCategory() {
    final count = habits.id.count();
    return (selectOnly(habits)
          ..addColumns([habits.categoryId, count])
          ..where(habits.deletedAt.isNull())
          ..groupBy([habits.categoryId]))
        .map((r) => MapEntry(r.read(habits.categoryId)!, r.read(count) ?? 0))
        .watch()
        .map(Map.fromEntries);
  }

  // ─── Habits ───────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchActiveHabits() => (select(habits)
        ..where((h) => h.isActive.equals(true) & h.deletedAt.isNull()))
      .watch();

  Future<List<Habit>> getActiveHabits() => (select(habits)
        ..where((h) => h.isActive.equals(true) & h.deletedAt.isNull()))
      .get();

  Future<List<Habit>> getAllHabits() =>
      (select(habits)..where((h) => h.deletedAt.isNull())).get();

  Future<Habit?> getHabit(String id) =>
      (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  /// สร้าง habit ใหม่ — gen UUID ให้ถ้ายังไม่มี id + ตั้ง sync fields
  Future<String> insertHabit(HabitsCompanion habit) async {
    final ready = habit.copyWith(
      id: habit.id.present ? habit.id : Value(_uuid.v4()),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
    );
    await into(habits).insert(ready);
    return ready.id.value;
  }

  Future<bool> updateHabit(HabitsCompanion habit) {
    final ready = habit.copyWith(
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
    );
    return update(habits).replace(ready);
  }

  Stream<List<Habit>> watchHabitsIncludingPaused() =>
      (select(habits)..where((h) => h.deletedAt.isNull())).watch();

  Future<int> setHabitActive(String id, bool active) => (update(habits)
        ..where((h) => h.id.equals(id)))
      .write(HabitsCompanion(
        isActive: Value(active),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ));

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

  Future<List<HabitLog>> getAllLogs() =>
      (select(habitLogs)..where((l) => l.deletedAt.isNull())).get();

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

  Future<List<HabitLog>> getLogsForDateRange(DateTime start, DateTime end) {
    return (select(habitLogs)
          ..where((l) =>
              l.loggedDate.isBiggerOrEqualValue(start) &
              l.loggedDate.isSmallerThanValue(end) &
              l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.asc(l.loggedDate)]))
        .get();
  }

  Stream<List<HabitLog>> watchLogsForDateRange(DateTime start, DateTime end) {
    return (select(habitLogs)
          ..where((l) =>
              l.loggedDate.isBiggerOrEqualValue(start) &
              l.loggedDate.isSmallerThanValue(end) &
              l.deletedAt.isNull()))
        .watch();
  }

  Future<HabitLog?> getLogForHabitAndDate(String habitId, DateTime date) async {
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

  Future<int> deleteLogsForHabit(String habitId) => (update(habitLogs)
        ..where((l) => l.habitId.equals(habitId) & l.deletedAt.isNull()))
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

  Future<List<Category>> getPendingCategories() =>
      (select(categories)..where((c) => c.syncStatus.equals('pending'))).get();

  Future<void> markCategoriesSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(categories)..where((c) => c.id.isIn(ids)))
        .write(const CategoriesCompanion(syncStatus: Value('synced')));
  }

  Future<void> applyRemoteCategory(CategoriesCompanion row) =>
      into(categories).insertOnConflictUpdate(row);

  Future<Category?> findCategoryById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

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
    await (update(categories)..where((c) => c.userId.isNull())).write(
      CategoriesCompanion(
        userId: Value(userId),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
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

enum CategoryDeleteResult { deleted, inUse, lastOne }
