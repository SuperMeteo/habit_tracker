import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/utils/data_exporter.dart';

final _created = DateTime(2026, 1, 1);

Category _category(int id, String name) => Category(
    id: id, name: name, colorHex: '#6366F1', iconCode: 0xe532, createdAt: _created);

Habit _habit(int id, String name, {int categoryId = 1, double? target, String? unit}) =>
    Habit(
      id: id,
      categoryId: categoryId,
      name: name,
      description: '',
      frequencyType: 'daily',
      targetDays: '[1,2,3,4,5,6,7]',
      timesPerWeek: 1,
      targetValue: target,
      unit: unit,
      colorHex: '#6366F1',
      iconCode: 0xe532,
      isActive: true,
      createdAt: _created,
    );

HabitLog _log(int id, int habitId, DateTime date,
        {bool done = true, double? value, String? note}) =>
    HabitLog(
      id: id,
      habitId: habitId,
      loggedDate: date,
      isDone: done,
      value: value,
      note: note,
      createdAt: date,
    );

List<String> _lines(String csv) =>
    csv.substring(1).split('\r\n').where((l) => l.isNotEmpty).toList();

void main() {
  final categories = [_category(1, 'สุขภาพ'), _category(2, 'การเรียนรู้')];
  final habits = [
    _habit(1, 'ดื่มน้ำ', target: 8, unit: 'แก้ว'),
    _habit(2, 'อ่านหนังสือ', categoryId: 2),
  ];

  group('CSV', () {
    test('ขึ้นต้นด้วย BOM มีหัวตาราง และเรียงตามวันที่', () {
      final csv = DataExporter.toCsv(
        categories: categories,
        habits: habits,
        logs: [
          _log(1, 2, DateTime(2026, 9, 15)),
          _log(2, 1, DateTime(2026, 9, 14), value: 6),
        ],
      );
      expect(csv.startsWith('﻿'), isTrue);
      final lines = _lines(csv);
      expect(lines[0], 'วันที่,habit,หมวดหมู่,ทำแล้ว,ค่า,หน่วย,เป้าหมาย,บันทึก');
      expect(lines[1], '2026-09-14,ดื่มน้ำ,สุขภาพ,1,6,แก้ว,8,');
      expect(lines[2], '2026-09-15,อ่านหนังสือ,การเรียนรู้,1,,,,');
      expect(lines.length, 3);
    });

    test('ข้อความที่มี , " หรือขึ้นบรรทัดใหม่ ถูกครอบด้วยเครื่องหมายคำพูด', () {
      final csv = DataExporter.toCsv(
        categories: categories,
        habits: [_habit(1, 'วิ่ง, เดิน')],
        logs: [
          _log(1, 1, DateTime(2026, 9, 1), note: 'เขาบอกว่า "ดี"\nมาก'),
        ],
      );
      expect(csv, contains('"วิ่ง, เดิน"'));
      expect(csv, contains('"เขาบอกว่า ""ดี""\nมาก"'));
    });

    test('กันสูตร Excel: ข้อความขึ้นต้นด้วย = + - @ ถูกใส่ \' นำหน้า แต่ตัวเลขติดลบไม่โดน', () {
      final csv = DataExporter.toCsv(
        categories: [_category(1, '@admin')],
        habits: [_habit(1, '=HYPERLINK("x")', target: 5)],
        logs: [_log(1, 1, DateTime(2026, 9, 1), value: -1, note: '+1')],
      );
      final row = _lines(csv)[1];
      expect(row, contains('"\'=HYPERLINK(""x"")"'));
      expect(row, contains("'@admin"));
      expect(row, contains("'+1"));
      expect(row, contains(',-1,'));
    });

    test('ค่าทศนิยมคงไว้ ค่าจำนวนเต็มไม่มี .0', () {
      final csv = DataExporter.toCsv(
        categories: categories,
        habits: [_habit(1, 'วิ่ง', target: 5, unit: 'กม.')],
        logs: [_log(1, 1, DateTime(2026, 9, 1), value: 2.5)],
      );
      expect(_lines(csv)[1], '2026-09-01,วิ่ง,สุขภาพ,1,2.5,กม.,5,');
    });

    test('log ของ habit ที่ถูกลบไปแล้ว ไม่ทำให้พัง', () {
      final csv = DataExporter.toCsv(
        categories: categories,
        habits: const [],
        logs: [_log(1, 99, DateTime(2026, 9, 1), done: false)],
      );
      expect(_lines(csv)[1], '2026-09-01,,,0,,,,');
    });
  });

  group('JSON', () {
    test('อ่านกลับได้ครบทุกตาราง', () {
      final logs = [_log(1, 1, DateTime(2026, 9, 14), value: 6)];
      final json = DataExporter.toJson(
        categories: categories,
        habits: habits,
        logs: logs,
        exportedAt: DateTime(2026, 9, 15, 10, 30),
      );
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['app'], 'habit_tracker');
      expect(decoded['exportedAt'], '2026-09-15T10:30:00.000');
      expect((decoded['categories'] as List).length, 2);
      expect((decoded['habits'] as List).length, 2);
      expect((decoded['logs'] as List).length, 1);
      expect(HabitLog.fromJson(decoded['logs'][0]).value, 6);
      expect(Habit.fromJson(decoded['habits'][0]).name, 'ดื่มน้ำ');
    });
  });

  test('ชื่อไฟล์มีวันที่', () {
    expect(DataExporter.fileName(DateTime(2026, 9, 5), 'csv'),
        'habit_tracker_2026-09-05.csv');
  });
}
