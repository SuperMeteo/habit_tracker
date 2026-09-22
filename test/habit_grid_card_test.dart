import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/features/dashboard/widgets/habit_grid_card.dart';
import 'package:habit_tracker/features/habits/providers/habits_provider.dart';
import 'package:habit_tracker/shared/widgets/progress_ring.dart';

Habit _habit({
  String type = 'daily',
  int times = 1,
  double? target,
  String? unit,
  String description = '',
}) =>
    Habit(
      id: 'x1',
      categoryId: 'c1',
      name: 'ดื่มน้ำ',
      description: description,
      inputType: 'check',
      frequencyType: type,
      targetDays: '[1,2,3,4,5,6,7]',
      timesPerWeek: times,
      targetValue: target,
      unit: unit,
      colorHex: '#3B82F6',
      iconCode: 0xe532,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      syncStatus: 'synced',
    );

HabitLog _log({bool done = true, double? value}) => HabitLog(
      id: 'l1',
      habitId: 'x1',
      loggedDate: DateTime(2026, 9, 17),
      isDone: done,
      value: value,
      pointsAwarded: 0,
      createdAt: DateTime(2026, 9, 17),
      updatedAt: DateTime(2026, 9, 17),
      syncStatus: 'synced',
    );

Future<void> _pump(WidgetTester tester, HabitWithLog item,
    {VoidCallback? onToggle, VoidCallback? onNumericTap, VoidCallback? onMenu}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 240,
        child: HabitGridCard(
          item: item,
          onToggle: onToggle ?? () {},
          onNumericTap: onNumericTap,
          onMenu: onMenu,
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('กดค้างที่การ์ด → เรียกเมนู แก้ไข/พัก/ลบ โดยไม่เผลอติ๊กทำ',
      (tester) async {
    var menu = 0;
    var toggled = 0;
    await _pump(
      tester,
      HabitWithLog(habit: _habit()),
      onToggle: () => toggled++,
      onMenu: () => menu++,
    );

    await tester.longPress(find.text('ดื่มน้ำ'));
    await tester.pump();

    expect(menu, 1);
    expect(toggled, 0);
  });

  testWidgets('กดค้างที่ช่องติ๊กก็เปิดเมนูเหมือนกัน ไม่ใช่จุดตาย',
      (tester) async {
    var menu = 0;
    var toggled = 0;
    await _pump(
      tester,
      HabitWithLog(habit: _habit()),
      onToggle: () => toggled++,
      onMenu: () => menu++,
    );

    await tester.longPress(find.byType(GestureDetector).last);
    await tester.pump();

    expect(menu, 1);
    expect(toggled, 0);
  });

  testWidgets('habit ทำ/ไม่ทำ: แสดงชื่อ + สถานะยังไม่ได้ทำ และกดช่องติ๊กแล้วเรียก onToggle',
      (tester) async {
    var toggled = 0;
    await _pump(
      tester,
      HabitWithLog(habit: _habit(description: 'วันละ 8 แก้ว')),
      onToggle: () => toggled++,
    );

    expect(find.text('ดื่มน้ำ'), findsOneWidget);
    expect(find.text('วันละ 8 แก้ว'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.byType(GestureDetector).last);
    expect(toggled, 1);
  });

  testWidgets('habit ที่ไม่มีคำอธิบาย: ขึ้นว่ายังไม่ได้ทำ', (tester) async {
    await _pump(tester, HabitWithLog(habit: _habit()));
    expect(find.text('ยังไม่ได้ทำ'), findsOneWidget);
  });

  testWidgets('habit ที่ทำแล้ว: ขึ้นเครื่องหมายถูกและข้อความทำแล้ววันนี้',
      (tester) async {
    await _pump(tester, HabitWithLog(habit: _habit(), log: _log()));
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.text('ทำแล้ววันนี้'), findsOneWidget);
  });

  testWidgets('habit เชิงตัวเลข: วงแหวนโชว์ค่าปัจจุบัน + หน่วย + เป้าหมาย',
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

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('แก้ว'), findsOneWidget);
    expect(find.text('เป้าหมาย 8 แก้ว'), findsOneWidget);

    await tester.tap(find.text('ดื่มน้ำ'));
    expect(opened, 1);
  });

  testWidgets('habit เชิงตัวเลข: ไม่มีช่องติ๊ก (กดการ์ดเพื่อกรอกค่าแทน)',
      (tester) async {
    await _pump(
      tester,
      HabitWithLog(habit: _habit(target: 8, unit: 'แก้ว'), log: _log(value: 6)),
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('habit N ครั้งต่อสัปดาห์: วงแหวนโชว์ 2/3 + ข้อความสัปดาห์นี้',
      (tester) async {
    await _pump(
      tester,
      HabitWithLog(
        habit: _habit(type: 'times_per_week', times: 3),
        weekDoneCount: 2,
      ),
    );
    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('สัปดาห์นี้ 2 จาก 3 ครั้ง'), findsOneWidget);
  });

  testWidgets('habit N ครั้งต่อสัปดาห์ที่ครบเป้า: ขึ้นว่าครบแล้ว', (tester) async {
    await _pump(
      tester,
      HabitWithLog(
        habit: _habit(type: 'times_per_week', times: 3),
        weekDoneCount: 3,
      ),
    );
    expect(find.text('ครบเป้าสัปดาห์นี้แล้ว'), findsOneWidget);
  });

  testWidgets('habit รายวัน: ไม่แสดงยอดรายสัปดาห์และไม่มีวงแหวน', (tester) async {
    await _pump(tester, HabitWithLog(habit: _habit()));
    expect(find.textContaining('สัปดาห์นี้'), findsNothing);
    expect(find.byType(ProgressRing), findsNothing);
  });
}
