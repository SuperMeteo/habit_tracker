import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

const _v1Schema = '''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  color_hex TEXT NOT NULL DEFAULT '#6366F1',
  icon_code INTEGER NOT NULL DEFAULT 58674,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
);
CREATE TABLE habits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL REFERENCES categories (id),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  frequency_type TEXT NOT NULL DEFAULT 'daily',
  target_days TEXT NOT NULL DEFAULT '[1,2,3,4,5,6,7]',
  times_per_week INTEGER NOT NULL DEFAULT 1,
  target_value REAL NULL,
  unit TEXT NULL,
  reminder_time TEXT NULL,
  color_hex TEXT NOT NULL DEFAULT '#6366F1',
  icon_code INTEGER NOT NULL DEFAULT 58674,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
);
CREATE TABLE habit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER NOT NULL REFERENCES habits (id),
  logged_date INTEGER NOT NULL,
  is_done INTEGER NOT NULL DEFAULT 0 CHECK (is_done IN (0, 1)),
  value REAL NULL,
  note TEXT NULL,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
  UNIQUE (habit_id, logged_date)
);
PRAGMA user_version = 1;
''';

const _v1Rows = '''
INSERT INTO categories (id, name, color_hex, icon_code, created_at) VALUES
  (1, 'สุขภาพ', '#EF4444', 11, 1700000000),
  (2, 'การเงิน', '#10B981', 22, 1700000000);
INSERT INTO habits (id, category_id, name, description, frequency_type,
  target_days, times_per_week, target_value, unit, reminder_time,
  color_hex, icon_code, is_active, created_at) VALUES
  (1, 1, 'ดื่มน้ำ', '', 'daily', '[1,2,3,4,5,6,7]', 1, 8, 'แก้ว', '07:30',
   '#3B82F6', 33, 1, 1700000000),
  (2, 2, 'ออมเงิน', 'ทุกวันจันทร์', 'specific_days', '[1,3,5]', 1, NULL, NULL,
   NULL, '#10B981', 44, 0, 1700000100);
INSERT INTO habit_logs (id, habit_id, logged_date, is_done, value, note, created_at) VALUES
  (1, 1, 1757894400, 1, 6, 'โน้ต', 1757894400),
  (2, 2, 1757980800, 0, NULL, NULL, 1757980800),
  (3, 1, 1757980800, 1, 8, NULL, 1757980800);
''';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('habit_migration_');
    file = File('${dir.path}/habit_v1.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  void seedV1({bool withRows = true}) {
    final raw = sqlite3.open(file.path);
    raw.execute(_v1Schema);
    if (withRows) raw.execute(_v1Rows);
    raw.dispose();
  }

  test('อัปเกรด v1 → v3 ข้อมูลเดิมอยู่ครบ และ habit เก่าย้ายเข้าหมวดร่างกาย',
      () async {
    seedV1();
    final db = AppDatabase.forTesting(NativeDatabase(file));

    final cats = await db.getAllCategories();
    expect(cats.map((c) => c.name).toSet(), defaultCategoryIds.keys.toSet());
    expect(cats.every((c) => c.id.length == 36), isTrue);
    final body = cats.firstWhere((c) => c.name == 'ร่างกาย');
    expect(body.id, defaultCategoryIds['ร่างกาย']);
    expect(body.colorHex, '#EF4444');

    final habits = await db.getAllHabits();
    expect(habits.length, 2);
    final water = habits.firstWhere((h) => h.name == 'ดื่มน้ำ');
    final save = habits.firstWhere((h) => h.name == 'ออมเงิน');
    expect(water.categoryId, body.id);
    expect(save.categoryId, body.id);
    expect(water.targetValue, 8);
    expect(water.unit, 'แก้ว');
    expect(water.reminderTime, '07:30');
    expect(water.isActive, isTrue);
    expect(water.createdAt.millisecondsSinceEpoch ~/ 1000, 1700000000);
    expect(save.isActive, isFalse);
    expect(save.frequencyType, 'specific_days');
    expect(save.targetDays, '[1,3,5]');
    expect(save.description, 'ทุกวันจันทร์');
    expect(save.iconCode, 44);

    final waterLogs = await db.getAllLogsForHabit(water.id);
    expect(waterLogs.length, 2);
    expect(waterLogs.first.loggedDate.millisecondsSinceEpoch ~/ 1000,
        1757894400);
    expect(waterLogs.first.value, 6);
    expect(waterLogs.first.note, 'โน้ต');
    expect(waterLogs.first.isDone, isTrue);
    expect(waterLogs.last.value, 8);

    final saveLogs = await db.getAllLogsForHabit(save.id);
    expect(saveLogs.single.isDone, isFalse);
    expect(saveLogs.single.value, isNull);

    expect((await db.getPendingHabits()).length, 2);
    expect((await db.getPendingLogs()).length, 3);
    expect(habits.every((h) => h.userId == null), isTrue);

    await db.close();
  });

  test('เปิดซ้ำหลังอัปเกรด ไม่ migrate ซ้ำ id เดิมคงอยู่', () async {
    seedV1();
    var db = AppDatabase.forTesting(NativeDatabase(file));
    final firstIds = (await db.getAllHabits()).map((h) => h.id).toSet();
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    expect((await db.getAllHabits()).map((h) => h.id).toSet(), firstIds);
    expect((await db.getAllCategories()).length, 4);
    await db.close();
  });

  test('v1 ที่ไม่มีหมวดเลย → ได้หมวดตั้งต้น 4 หมวดหลังอัปเกรด', () async {
    seedV1(withRows: false);
    final db = AppDatabase.forTesting(NativeDatabase(file));
    expect((await db.getAllCategories()).length, 4);
    expect(await db.getAllHabits(), isEmpty);
    await db.close();
  });
}
