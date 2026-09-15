import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> addHabit(int categoryId, {bool active = true}) =>
      db.insertHabit(HabitsCompanion(
        categoryId: Value(categoryId),
        name: const Value('วิ่ง'),
        isActive: Value(active),
      ));

  test('ฐานข้อมูลใหม่มีหมวดตั้งต้น 5 หมวด', () async {
    expect((await db.getAllCategories()).length, 5);
  });

  test('เพิ่มและแก้ไขหมวดหมู่', () async {
    final id = await db.insertCategory('งานบ้าน', '#10B981');
    await db.updateCategory(id, 'งานบ้านทุกวัน', '#EF4444');
    final cat = (await db.getAllCategories()).firstWhere((c) => c.id == id);
    expect(cat.name, 'งานบ้านทุกวัน');
    expect(cat.colorHex, '#EF4444');
  });

  test('ลบหมวดที่มี habit ใช้อยู่ไม่ได้ (รวม habit ที่ปิดไว้)', () async {
    await addHabit(1, active: false);
    expect(await db.deleteCategory(1), CategoryDeleteResult.inUse);
    expect((await db.getAllCategories()).length, 5);
  });

  test('ลบหมวดที่ว่างได้', () async {
    expect(await db.deleteCategory(2), CategoryDeleteResult.deleted);
    expect((await db.getAllCategories()).map((c) => c.id), isNot(contains(2)));
  });

  test('ลบหมวดสุดท้ายไม่ได้', () async {
    for (final id in [2, 3, 4, 5]) {
      expect(await db.deleteCategory(id), CategoryDeleteResult.deleted);
    }
    expect(await db.deleteCategory(1), CategoryDeleteResult.lastOne);
    expect((await db.getAllCategories()).length, 1);
  });

  test('นับจำนวน habit ในแต่ละหมวด', () async {
    await addHabit(1);
    await addHabit(1);
    await addHabit(3);
    expect(await db.watchHabitCountsByCategory().first, {1: 2, 3: 1});
    expect(await db.countHabitsInCategory(2), 0);
  });
}
