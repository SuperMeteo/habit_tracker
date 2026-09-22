import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/utils/date_utils.dart';
import 'package:habit_tracker/core/utils/streak_calculator.dart';

Habit _habit({String type = 'daily', String days = '[1,2,3,4,5,6,7]'}) => Habit(
      id: 'h1',
      categoryId: 'c1',
      name: 'อ่านหนังสือ',
      description: '',
      inputType: 'check',
      frequencyType: type,
      targetDays: days,
      timesPerWeek: 1,
      colorHex: '#6366F1',
      iconCode: 0xe532,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      syncStatus: 'synced',
    );

int _id = 0;
HabitLog _log(DateTime date, {bool done = true}) => HabitLog(
      id: 'l${++_id}',
      habitId: 'h1',
      loggedDate: date,
      isDone: done,
      createdAt: date,
      pointsAwarded: 0,
      updatedAt: date,
      syncStatus: 'synced',
    );

void main() {
  final now = DateTime(2026, 9, 17, 9);
  final today = DateTime(now.year, now.month, now.day);
  DateTime ago(int days) => DateTime(today.year, today.month, today.day - days);

  group('Streak รายวัน', () {
    test('ไม่มี log เลย → 0', () {
      final r = StreakCalculator.calculate(habit: _habit(), logs: [], now: now);
      expect(r, {'current': 0, 'longest': 0});
    });

    test('ทำวันนี้ด้วย นับรวมวันนี้', () {
      final logs = [_log(ago(0)), _log(ago(1)), _log(ago(2))];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 3);
    });

    test('เมื่อวานขาด → ปัจจุบัน 0 แต่สูงสุดยังจำไว้', () {
      final logs = [_log(ago(2)), _log(ago(3)), _log(ago(4))];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 0);
      expect(r['longest'], 3);
    });

    test('log ที่ยกเลิกติ๊กแล้ว ไม่นับ', () {
      final logs = [_log(ago(1)), _log(ago(2), done: false), _log(ago(3))];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 1);
      expect(r['longest'], 1);
    });
  });

  group('Streak แบบเลือกวัน (จ / พ / ศ)', () {
    final mwf = _habit(type: 'specific_days', days: '[1,3,5]');
    final weekStart = HabitDateUtils.startOfWeek(today);
    DateTime dayOf(int weekOffset, int weekday) => DateTime(
        weekStart.year, weekStart.month, weekStart.day + weekOffset * 7 + weekday - 1);

    test('วันที่ไม่ได้เลือกไม่ถือว่าขาด', () {
      final logs = [
        _log(dayOf(0, 3)),
        _log(dayOf(0, 1)),
        _log(dayOf(-1, 5)),
      ];
      final r = StreakCalculator.calculate(habit: mwf, logs: logs, now: now);
      expect(r['current'], 3);
    });

    test('ขาดวันที่เลือกไว้ 1 วัน → เริ่มนับใหม่ แต่สูงสุดยังจำไว้', () {
      final logs = [
        _log(dayOf(0, 3)),
        _log(dayOf(0, 1)),
        _log(dayOf(-1, 3)),
        _log(dayOf(-1, 1)),
        _log(dayOf(-2, 5)),
      ];
      final r = StreakCalculator.calculate(habit: mwf, logs: logs, now: now);
      expect(r['current'], 2);
      expect(r['longest'], 3);
    });
  });
}
