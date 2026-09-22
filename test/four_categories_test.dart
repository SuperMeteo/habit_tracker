import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/features/habits/models/habit_templates.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('หมวดตั้งต้นมี 4 หมวดตามที่ตกลง และ id คงที่ทุกเครื่อง', () async {
    final cats = await db.getAllCategories();
    expect(cats.map((c) => c.name).toList(),
        ['ร่างกาย', 'การกิน', 'การนอน', 'จิตใจ']);
    expect(cats.map((c) => c.id).toSet(), scoredCategoryIds.toSet());
  });

  test('ทุกแม่แบบชี้ไปหมวดที่มีอยู่จริง ไม่งั้น habit จะไม่ได้คะแนน', () async {
    final ids = (await db.getAllCategories()).map((c) => c.id).toSet();

    expect(HabitTemplates.categories.map((c) => c.key).toSet(), ids);
    for (final cat in HabitTemplates.categories) {
      expect(cat.templates, isNotEmpty, reason: 'หมวด ${cat.label} ไม่มีแม่แบบ');
      for (final t in cat.templates) {
        expect(ids.contains(t.categoryKey), isTrue,
            reason: 'แม่แบบ ${t.name} ชี้หมวดที่ไม่มี');
        expect(t.categoryKey, cat.key,
            reason: 'แม่แบบ ${t.name} อยู่ผิดหมวด');
      }
    }
  });

  test('แม่แบบเชิงตัวเลขต้องมีเป้าหมายและหน่วยครบ', () {
    for (final cat in HabitTemplates.categories) {
      for (final t in cat.templates) {
        if (!t.isNumeric) continue;
        expect(t.targetValue, isNotNull, reason: '${t.name} ไม่มีเป้าหมาย');
        expect(t.unit, isNotNull, reason: '${t.name} ไม่มีหน่วย');
      }
    }
  });

  test('อัปเกรดจากหมวดเก่า: habit ย้ายเข้าร่างกาย และหมวดเก่าถูกลบแบบส่งขึ้นคลาวด์',
      () async {
    const oldMoney = '11111111-1111-4111-8111-111111111103';
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: oldMoney,
          name: 'การเงิน',
          syncStatus: const Value('synced'),
        ));
    final habitId = await db.insertHabit(HabitsCompanion(
      categoryId: const Value(oldMoney),
      name: const Value('เก็บออม'),
    ));

    await db.migrateToFourCategoriesForTest();

    final habit = await db.getHabit(habitId);
    expect(habit!.categoryId, scoredCategoryIds.first);
    expect(habit.syncStatus, 'pending');

    expect((await db.getAllCategories()).map((c) => c.id).toSet(),
        scoredCategoryIds.toSet());
    final pending = await db.getPendingCategories();
    expect(pending.any((c) => c.id == oldMoney && c.deletedAt != null), isTrue);
  });
}
