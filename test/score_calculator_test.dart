import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/scoring/score_calculator.dart';

final today = DateTime(2026, 9, 22);

Habit _habit(String id, String categoryId, {DateTime? deletedAt}) => Habit(
      id: id,
      categoryId: categoryId,
      name: id,
      description: '',
      inputType: 'check',
      frequencyType: 'daily',
      targetDays: '[1,2,3,4,5,6,7]',
      timesPerWeek: 1,
      colorHex: '#EF4444',
      iconCode: 1,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      deletedAt: deletedAt,
      syncStatus: 'synced',
    );

HabitLog _log(String habitId, int daysAgo,
        {bool done = true, DateTime? deletedAt}) =>
    HabitLog(
      id: '$habitId-$daysAgo',
      habitId: habitId,
      loggedDate: today.subtract(Duration(days: daysAgo)),
      isDone: done,
      pointsAwarded: 0,
      createdAt: today,
      updatedAt: today,
      deletedAt: deletedAt,
      syncStatus: 'synced',
    );

ScoreResult _run(List<Habit> habits, List<HabitLog> logs) =>
    ScoreCalculator.compute(habits: habits, logs: logs, today: today);

void main() {
  final body = scoredCategoryIds[0];
  final food = scoredCategoryIds[1];
  final sleep = scoredCategoryIds[2];
  final mind = scoredCategoryIds[3];

  test('ยังไม่เคยทำอะไรเลย คะแนนเป็น 0 และไม่โดนหักย้อนหลัง', () {
    final r = _run([_habit('h1', body)], []);
    expect(r.total, 0);
    expect(r.pointsOf(body), 0);
  });

  test('ทำครบทั้ง 4 หมวดในวันเดียว ได้ 40 คะแนนตามที่ตกลง', () {
    final habits = [
      _habit('h1', body),
      _habit('h2', food),
      _habit('h3', sleep),
      _habit('h4', mind),
    ];
    final logs = [
      _log('h1', 0),
      _log('h2', 0),
      _log('h3', 0),
      _log('h4', 0),
    ];
    final r = _run(habits, logs);
    expect(r.total, 40);
    expect(r.doneTodayCount, 4);
    for (final id in scoredCategoryIds) {
      expect(r.pointsOf(id), 10);
    }
  });

  test('ทำหลาย habit ในหมวดเดียววันเดียว นับเป็นครั้งเดียว ไม่ปั๊มคะแนน', () {
    final habits = [_habit('h1', body), _habit('h2', body)];
    final logs = [_log('h1', 0), _log('h2', 0)];
    expect(_run(habits, logs).pointsOf(body), 10);
  });

  test('ทำต่อเนื่อง 7 วัน วันที่ 7 ได้ตัวคูณ 1.25', () {
    final habits = [_habit('h1', body)];
    final logs = [for (var i = 0; i < 7; i++) _log('h1', i)];
    final r = _run(habits, logs);
    expect(r.pointsOf(body), 60 + 13);
    expect(r.byCategory[body]!.streak, 7);
  });

  test('ตัวคูณขยับตามช่วงที่กำหนด', () {
    expect(ScoreCalculator.multiplier(1), 1.0);
    expect(ScoreCalculator.multiplier(6), 1.0);
    expect(ScoreCalculator.multiplier(7), 1.25);
    expect(ScoreCalculator.multiplier(13), 1.25);
    expect(ScoreCalculator.multiplier(14), 1.5);
    expect(ScoreCalculator.multiplier(29), 1.5);
    expect(ScoreCalculator.multiplier(30), 2.0);
  });

  test('ขาดไป 1 วันกลางทาง โดนหัก 5 และตัวนับต่อเนื่องเริ่มใหม่', () {
    final habits = [_habit('h1', body)];
    final logs = [_log('h1', 3), _log('h1', 2), _log('h1', 0)];
    final r = _run(habits, logs);
    expect(r.pointsOf(body), 10 + 10 - 5 + 10);
    expect(r.byCategory[body]!.streak, 1);
    expect(r.byCategory[body]!.bestStreak, 2);
  });

  test('วันนี้ยังไม่ได้ทำ ยังไม่โดนหัก เพราะวันยังไม่จบ', () {
    final habits = [_habit('h1', body)];
    final logs = [_log('h1', 2), _log('h1', 1)];
    final r = _run(habits, logs);
    expect(r.pointsOf(body), 20);
    expect(r.byCategory[body]!.streak, 2);
    expect(r.byCategory[body]!.doneToday, isFalse);
  });

  test('ขาดยาวจนคะแนนจะติดลบ ต้องหยุดที่ 0 ไม่ลงไปต่ำกว่านั้น', () {
    final habits = [_habit('h1', body)];
    final logs = [_log('h1', 20)];
    expect(_run(habits, logs).pointsOf(body), 0);
  });

  test('log ที่ยกเลิกติ๊ก หรือถูกลบ ไม่ถูกนับเป็นวันที่ทำ', () {
    final habits = [_habit('h1', body)];
    final logs = [
      _log('h1', 1, done: false),
      _log('h1', 0, deletedAt: today),
    ];
    expect(_run(habits, logs).pointsOf(body), 0);
  });

  test('habit ที่ถูกลบถาวร ประวัติไม่ถูกนับคะแนนอีก', () {
    final habits = [_habit('h1', body, deletedAt: today)];
    final logs = [_log('h1', 0)];
    expect(_run(habits, logs).total, 0);
  });

  test('ระดับแรงค์ขยับตามคะแนนรวม', () {
    expect(ScoreCalculator.tierOf(0), 'Bronze');
    expect(ScoreCalculator.tierOf(499), 'Bronze');
    expect(ScoreCalculator.tierOf(500), 'Silver');
    expect(ScoreCalculator.tierOf(1500), 'Gold');
    expect(ScoreCalculator.tierOf(4000), 'Platinum');
    expect(ScoreCalculator.tierOf(10000), 'Diamond');
  });
}
