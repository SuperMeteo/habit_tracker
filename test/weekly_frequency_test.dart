import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/utils/date_utils.dart';
import 'package:habit_tracker/core/utils/streak_calculator.dart';

Habit _habit({String type = 'times_per_week', int times = 3}) => Habit(
      id: 'h1',
      categoryId: 'c1',
      name: 'วิ่ง',
      description: '',
      frequencyType: type,
      targetDays: '[1,2,3,4,5,6,7]',
      timesPerWeek: times,
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

DateTime _day(DateTime weekStart, int weekOffset, int dayOffset) => DateTime(
    weekStart.year, weekStart.month, weekStart.day + weekOffset * 7 + dayOffset);

List<HabitLog> _logsInWeek(DateTime weekStart, int weekOffset, int count) =>
    List.generate(count, (d) => _log(_day(weekStart, weekOffset, d)));

void main() {
  final now = DateTime(2026, 9, 17, 20, 30);
  final weekStart = HabitDateUtils.startOfWeek(now);

  group('ความถี่ N ครั้งต่อสัปดาห์ — อัตราสำเร็จ', () {
    test('เป้า 3 ทำได้ 2 → 2/3', () {
      final logs = _logsInWeek(weekStart, 0, 2);
      expect(StreakCalculator.weeklyDoneCount(logs: logs, weekStart: weekStart), 2);
      expect(
        StreakCalculator.weeklyCompletionRate(
            habit: _habit(), logsThisWeek: logs, weekStart: weekStart),
        closeTo(2 / 3, 1e-9),
      );
    });

    test('ทำเกินเป้า อัตราไม่เกิน 100%', () {
      final logs = _logsInWeek(weekStart, 0, 5);
      expect(
        StreakCalculator.weeklyCompletionRate(
            habit: _habit(), logsThisWeek: logs, weekStart: weekStart),
        1.0,
      );
    });

    test('log ที่ยกเลิกติ๊ก และ log นอกสัปดาห์ ไม่ถูกนับ', () {
      final logs = [
        _log(_day(weekStart, 0, 0)),
        _log(_day(weekStart, 0, 1), done: false),
        _log(_day(weekStart, -1, 6)),
        _log(_day(weekStart, 1, 0)),
      ];
      expect(StreakCalculator.weeklyDoneCount(logs: logs, weekStart: weekStart), 1);
    });
  });

  group('ความถี่ N ครั้งต่อสัปดาห์ — Streak นับเป็นสัปดาห์', () {
    test('2 สัปดาห์ก่อนครบเป้า สัปดาห์นี้ยังไม่ครบ → ไม่ถือว่าขาด ได้ 2', () {
      final logs = [
        ..._logsInWeek(weekStart, -2, 3),
        ..._logsInWeek(weekStart, -1, 3),
        ..._logsInWeek(weekStart, 0, 1),
      ];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 2);
      expect(r['longest'], 2);
    });

    test('สัปดาห์นี้ครบเป้าแล้ว นับรวมด้วย', () {
      final logs = [
        ..._logsInWeek(weekStart, -1, 3),
        ..._logsInWeek(weekStart, 0, 3),
      ];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 2);
    });

    test('ขาดกลางทาง → ปัจจุบันเริ่มนับใหม่ แต่สถิติสูงสุดยังจำไว้', () {
      final logs = [
        ..._logsInWeek(weekStart, -4, 3),
        ..._logsInWeek(weekStart, -3, 3),
        ..._logsInWeek(weekStart, -2, 1),
        ..._logsInWeek(weekStart, -1, 3),
      ];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 1);
      expect(r['longest'], 2);
    });

    test('เว้นบางวันในสัปดาห์ Streak ไม่ขาด (ต่างจากนับรายวัน)', () {
      final logs = [
        _log(_day(weekStart, -1, 0)),
        _log(_day(weekStart, -1, 3)),
        _log(_day(weekStart, -1, 6)),
      ];
      final r = StreakCalculator.calculate(habit: _habit(), logs: logs, now: now);
      expect(r['current'], 1);
    });
  });

  test('habit รายวันยังนับเหมือนเดิม: วันนี้ยังไม่ติ๊ก ไม่ถือว่าขาด', () {
    final today = DateTime(now.year, now.month, now.day);
    final logs = [
      _log(today.subtract(const Duration(days: 2))),
      _log(today.subtract(const Duration(days: 1))),
    ];
    final r = StreakCalculator.calculate(
        habit: _habit(type: 'daily'), logs: logs, now: now);
    expect(r['current'], 2);
  });
}
