import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/features/dashboard/widgets/habit_card.dart';
import 'package:habit_tracker/features/habits/providers/habits_provider.dart';

Habit _habit({
  String type = 'daily',
  int times = 1,
  double? target,
  String? unit,
  String description = '',
}) =>
    Habit(
      id: 1,
      categoryId: 1,
      name: 'ดื่มน้ำ',
      description: description,
      frequencyType: type,
      targetDays: '[1,2,3,4,5,6,7]',
      timesPerWeek: times,
      targetValue: target,
      unit: unit,
      colorHex: '#3B82F6',
      iconCode: Icons.water_drop.codePoint,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

HabitLog _log({bool done = true, double? value}) => HabitLog(
      id: 1,
      habitId: 1,
      loggedDate: DateTime(2026, 9, 17),
      isDone: done,
      value: value,
      createdAt: DateTime(2026, 9, 17),
    );

Future<void> _pump(WidgetTester tester, HabitWithLog item,
    {VoidCallback? onToggle, VoidCallback? onNumericTap}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: HabitCard(
        item: item,
        onToggle: onToggle ?? () {},
        onNumericTap: onNumericTap,
      ),
    ),
  ));
}

void main() {
  testWidgets('habit ทำ/ไม่ทำ: แสดงชื่อ คำอธิบาย และกดช่องติ๊กแล้วเรียก onToggle',
      (tester) async {
    var toggled = 0;
    await _pump(
      tester,
      HabitWithLog(habit: _habit(description: 'วันละ 8 แก้ว')),
      onToggle: () => toggled++,
    );

    expect(find.text('ดื่มน้ำ'), findsOneWidget);
    expect(find.text('วันละ 8 แก้ว'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byType(GestureDetector).last);
    expect(toggled, 1);
  });

  testWidgets('habit ที่ทำแล้ว: ขึ้นเครื่องหมายถูก', (tester) async {
    await _pump(tester, HabitWithLog(habit: _habit(), log: _log()));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('habit เชิงตัวเลข: แสดง 6 / 8 แก้ว และกดการ์ดแล้วเปิดช่องกรอก',
      (tester) async {
    var opened = 0;
    await _pump(
      tester,
      HabitWithLog(
        habit: _habit(target: 8, unit: 'แก้ว'),
        log: _log(value: 6),
      ),
      onNumericTap: () => opened++,
    );

    expect(find.text('6 / 8 แก้ว'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.tap(find.text('ดื่มน้ำ'));
    expect(opened, 1);
  });

  testWidgets('habit N ครั้งต่อสัปดาห์: แสดงยอดทำแล้วในสัปดาห์', (tester) async {
    await _pump(
      tester,
      HabitWithLog(
        habit: _habit(type: 'times_per_week', times: 3),
        weekDoneCount: 2,
      ),
    );
    expect(find.text('ทำแล้ว 2 / 3 ครั้งในสัปดาห์'), findsOneWidget);
  });

  testWidgets('habit รายวัน: ไม่แสดงยอดรายสัปดาห์', (tester) async {
    await _pump(tester, HabitWithLog(habit: _habit()));
    expect(find.textContaining('ครั้งในสัปดาห์'), findsNothing);
  });
}
