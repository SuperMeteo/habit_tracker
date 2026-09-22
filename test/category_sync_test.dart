import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> idOf(String name) async =>
      (await db.getAllCategories()).firstWhere((c) => c.name == name).id;

  test('หมวดตั้งต้นไม่ถูกส่งขึ้นคลาวด์ซ้ำ ๆ (ตั้งไว้เป็น synced แล้ว)', () async {
    expect(await db.getPendingCategories(), isEmpty);
  });

  test('หมวดที่สร้างเองรอส่งขึ้นคลาวด์', () async {
    final id = await db.insertCategory('งานบ้าน', '#10B981');
    final pending = await db.getPendingCategories();
    expect(pending.map((c) => c.id), [id]);
    expect(pending.single.syncStatus, 'pending');
  });

  test('แก้ชื่อหมวดตั้งต้น → กลับมาเป็นรอส่ง (จะได้ไปอัปเดตบนคลาวด์)', () async {
    final health = await idOf('สุขภาพ');
    await db.updateCategory(health, 'ร่างกาย', '#EF4444');
    expect((await db.getPendingCategories()).single.id, health);
  });

  test('ลบหมวด → ยังส่งขึ้นคลาวด์ได้ เพื่อให้เครื่องอื่นลบตาม', () async {
    final money = await idOf('การเงิน');
    expect(await db.deleteCategory(money), CategoryDeleteResult.deleted);
    final pending = await db.getPendingCategories();
    expect(pending.single.id, money);
    expect(pending.single.deletedAt, isNotNull);
  });

  test('markCategoriesSynced → หายจากคิวรอส่ง', () async {
    final id = await db.insertCategory('งานบ้าน', '#10B981');
    await db.markCategoriesSynced([id]);
    expect(await db.getPendingCategories(), isEmpty);
  });

  test('รับหมวดจากคลาวด์ → เพิ่มเข้าเครื่อง และไม่ค้างในคิวรอส่ง', () async {
    const remoteId = '22222222-2222-4222-8222-222222222201';
    await db.applyRemoteCategory(CategoriesCompanion(
      id: const Value(remoteId),
      name: const Value('งานอดิเรก'),
      colorHex: const Value('#F59E0B'),
      iconCode: const Value(123),
      userId: const Value('user-1'),
      updatedAt: Value(DateTime(2026, 9, 22)),
      syncStatus: const Value('synced'),
    ));

    final found = await db.findCategoryById(remoteId);
    expect(found, isNotNull);
    expect(found!.name, 'งานอดิเรก');
    expect(found.userId, 'user-1');
    expect(await db.getPendingCategories(), isEmpty);
    expect((await db.getAllCategories()).length, 6);
  });

  test('รับหมวดเดิมจากคลาวด์อีกครั้ง → ทับของเก่า ไม่เพิ่มแถวซ้ำ', () async {
    final health = await idOf('สุขภาพ');
    await db.applyRemoteCategory(CategoriesCompanion(
      id: Value(health),
      name: const Value('ร่างกาย'),
      colorHex: const Value('#EF4444'),
      iconCode: const Value(1),
      updatedAt: Value(DateTime(2026, 9, 22)),
      syncStatus: const Value('synced'),
    ));
    expect((await db.getAllCategories()).length, 5);
    expect((await db.findCategoryById(health))!.name, 'ร่างกาย');
  });

  test('login แล้วผูกข้อมูล guest: หมวด habit และ log ได้ userId พร้อมกัน',
      () async {
    final catId = await db.insertCategory('งานบ้าน', '#10B981');
    final habitId = await db.insertHabit(HabitsCompanion(
      categoryId: Value(catId),
      name: const Value('ถูพื้น'),
    ));
    await db.upsertLog(HabitLogsCompanion(
      habitId: Value(habitId),
      loggedDate: Value(DateTime(2026, 9, 22)),
      isDone: const Value(true),
    ));

    await db.claimGuestData('user-9');

    expect((await db.findCategoryById(catId))!.userId, 'user-9');
    expect((await db.findHabitById(habitId))!.userId, 'user-9');
    expect((await db.getAllLogsForHabit(habitId)).single.userId, 'user-9');
  });

  test('หมวดตั้งต้นใช้ id เดียวกันทุกเครื่อง — จำเป็นสำหรับบอร์ดแยกด้าน', () async {
    for (final entry in defaultCategoryIds.entries) {
      expect(await idOf(entry.key), entry.value);
    }
  });
}
