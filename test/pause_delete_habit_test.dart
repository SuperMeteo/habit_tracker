import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> firstCategoryId() async =>
      (await db.getAllCategories()).first.id;

  Future<String> addHabit() async => db.insertHabit(HabitsCompanion(
        categoryId: Value(await firstCategoryId()),
        name: const Value('วิ่ง'),
      ));

  Future<void> tick(String habitId, DateTime day) => db.upsertLog(
        HabitLogsCompanion(
          habitId: Value(habitId),
          loggedDate: Value(day),
          isDone: const Value(true),
        ),
      );

  test('พักไว้: หายจากหน้าหลัก แต่ยังอยู่ในหน้าจัดการ และประวัติไม่หาย',
      () async {
    final id = await addHabit();
    await tick(id, DateTime(2026, 9, 22));

    await db.setHabitActive(id, false);

    expect(await db.getActiveHabits(), isEmpty);
    expect((await db.getAllHabits()).map((h) => h.id), [id]);
    expect(await db.getAllLogsForHabit(id), hasLength(1));
  });

  test('เลิกพัก: กลับมาโชว์ในหน้าหลักเหมือนเดิม', () async {
    final id = await addHabit();
    await db.setHabitActive(id, false);
    await db.setHabitActive(id, true);

    expect((await db.getActiveHabits()).map((h) => h.id), [id]);
  });

  test('พักไว้แล้วต้องถูกส่งขึ้นคลาวด์ ไม่ใช่ค้างอยู่เครื่องเดียว', () async {
    final id = await addHabit();
    await db.markHabitsSynced([id]);
    expect(await db.getPendingHabits(), isEmpty);

    await db.setHabitActive(id, false);

    expect((await db.getPendingHabits()).map((h) => h.id), [id]);
  });

  test('ลบถาวร: ประวัติถูกลบด้วย และ log ที่ลบต้องถูกส่งไปให้เซิร์ฟเวอร์หักแต้ม',
      () async {
    final id = await addHabit();
    await tick(id, DateTime(2026, 9, 21));
    await tick(id, DateTime(2026, 9, 22));
    final logIds = (await db.getAllLogsForHabit(id)).map((l) => l.id).toSet();
    await db.markLogsSynced(logIds.toList());

    await db.deleteLogsForHabit(id);
    await db.deleteHabit(id);

    expect(await db.getAllLogsForHabit(id), isEmpty);
    expect(await db.getAllHabits(), isEmpty);

    final pending = await db.getPendingLogs();
    expect(pending.map((l) => l.id).toSet(), logIds);
    expect(pending.every((l) => l.deletedAt != null), isTrue);
  });

  test('ลบถาวรซ้ำรอบสอง: ไม่ปั๊ม deletedAt ทับของเดิมจนแต้มถูกหักสองรอบ',
      () async {
    final id = await addHabit();
    await tick(id, DateTime(2026, 9, 22));
    await db.deleteLogsForHabit(id);
    final firstStamp = (await db.getPendingLogs())
        .firstWhere((l) => l.habitId == id)
        .deletedAt;

    final touched = await db.deleteLogsForHabit(id);

    expect(touched, 0);
    final again = (await db.getPendingLogs())
        .firstWhere((l) => l.habitId == id)
        .deletedAt;
    expect(again, firstStamp);
  });
}
