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

  Future<void> addHabit(String categoryId, {bool active = true}) =>
      db.insertHabit(HabitsCompanion(
        categoryId: Value(categoryId),
        name: const Value('วิ่ง'),
        isActive: Value(active),
      ));

  test('ฐานข้อมูลใหม่มีหมวดตั้งต้น 5 หมวด และ id คงที่ทุกเครื่อง', () async {
    final cats = await db.getAllCategories();
    expect(cats.length, 5);
    expect(await idOf('สุขภาพ'), defaultCategoryIds['สุขภาพ']);
    expect(cats.map((c) => c.id).toSet(), defaultCategoryIds.values.toSet());
  });

  test('habit จากคลาวด์ที่ชี้หมวดที่ไม่รู้จัก → ตกไปหมวดแรก ไม่พัง', () async {
    final health = await idOf('สุขภาพ');
    expect(await db.resolveCategoryId(health), health);
    expect(await db.resolveCategoryId('ไม่มีหมวดนี้'), health);
    expect(await db.resolveCategoryId(null), health);
    expect(await db.resolveCategoryId(''), health);
  });

  test('เพิ่มและแก้ไขหมวดหมู่', () async {
    final id = await db.insertCategory('งานบ้าน', '#10B981');
    await db.updateCategory(id, 'งานบ้านทุกวัน', '#EF4444');
    final cat = (await db.getAllCategories()).firstWhere((c) => c.id == id);
    expect(cat.name, 'งานบ้านทุกวัน');
    expect(cat.colorHex, '#EF4444');
    expect(cat.syncStatus, 'pending');
  });

  test('ลบหมวดที่มี habit ใช้อยู่ไม่ได้ (รวม habit ที่ปิดไว้)', () async {
    final health = await idOf('สุขภาพ');
    await addHabit(health, active: false);
    expect(await db.deleteCategory(health), CategoryDeleteResult.inUse);
    expect((await db.getAllCategories()).length, 5);
  });

  test('ลบหมวดที่ว่างได้ และหายจากรายการ', () async {
    final money = await idOf('การเงิน');
    expect(await db.deleteCategory(money), CategoryDeleteResult.deleted);
    expect((await db.getAllCategories()).map((c) => c.id), isNot(contains(money)));
  });

  test('ลบหมวดสุดท้ายไม่ได้', () async {
    for (final name in ['ผลิตภาพ', 'การเงิน', 'การเรียนรู้', 'อื่นๆ']) {
      expect(await db.deleteCategory(await idOf(name)),
          CategoryDeleteResult.deleted);
    }
    expect(await db.deleteCategory(await idOf('สุขภาพ')),
        CategoryDeleteResult.lastOne);
    expect((await db.getAllCategories()).length, 1);
  });

  test('นับจำนวน habit ในแต่ละหมวด', () async {
    final health = await idOf('สุขภาพ');
    final money = await idOf('การเงิน');
    final learn = await idOf('การเรียนรู้');
    await addHabit(health);
    await addHabit(health);
    await addHabit(learn);
    expect(await db.watchHabitCountsByCategory().first, {health: 2, learn: 1});
    expect(await db.countHabitsInCategory(money), 0);
  });

  test('habit ที่ลบแล้วไม่ถูกนับในหมวด', () async {
    final health = await idOf('สุขภาพ');
    await addHabit(health);
    final habit = (await db.getAllHabits()).single;
    await db.deleteHabit(habit.id);
    expect(await db.countHabitsInCategory(health), 0);
    expect(await db.getAllHabits(), isEmpty);
    expect((await db.getPendingHabits()).single.deletedAt, isNotNull);
  });
}
