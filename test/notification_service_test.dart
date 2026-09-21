import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Habit _habit({
  String id = 'h3',
  String type = 'daily',
  String days = '[1,2,3,4,5,6,7]',
  String? reminder = '07:30',
  double? target,
  String? unit,
  int times = 1,
}) =>
    Habit(
      id: id,
      categoryId: 'c1',
      name: 'วิ่ง',
      description: '',
      frequencyType: type,
      targetDays: days,
      timesPerWeek: times,
      targetValue: target,
      unit: unit,
      reminderTime: reminder,
      colorHex: '#6366F1',
      iconCode: 0xe532,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      syncStatus: 'synced',
    );

void main() {
  late tz.Location bangkok;

  setUpAll(() {
    tzdata.initializeTimeZones();
    bangkok = tz.getLocation('Asia/Bangkok');
  });

  group('อ่านเวลาแจ้งเตือน', () {
    test('รูปแบบถูกต้อง', () {
      expect(NotificationService.parseReminderTime('07:30'), (hour: 7, minute: 30));
      expect(NotificationService.parseReminderTime('23:59'), (hour: 23, minute: 59));
    });

    test('ค่าว่าง หรือรูปแบบผิด → ไม่ตั้งเตือน', () {
      for (final bad in [null, '', 'abc', '24:00', '12:60', '7.30']) {
        expect(NotificationService.parseReminderTime(bad), isNull, reason: '$bad');
      }
    });
  });

  group('หาเวลาแจ้งเตือนครั้งถัดไป', () {
    late tz.TZDateTime tuesday8am;
    setUp(() => tuesday8am = tz.TZDateTime(bangkok, 2026, 9, 15, 8));

    test('เวลายังไม่ถึง → วันนี้', () {
      final t = NotificationService.nextInstance(tuesday8am, 9, 0);
      expect([t.year, t.month, t.day, t.hour], [2026, 9, 15, 9]);
    });

    test('เวลาผ่านไปแล้ว หรือตรงเวลาพอดี → พรุ่งนี้', () {
      final passed = NotificationService.nextInstance(tuesday8am, 7, 30);
      expect([passed.day, passed.hour, passed.minute], [16, 7, 30]);
      final exact = NotificationService.nextInstance(tuesday8am, 8, 0);
      expect(exact.day, 16);
    });

    test('ระบุวันในสัปดาห์ → ไปวันนั้นที่ใกล้ที่สุด', () {
      expect(tuesday8am.weekday, DateTime.tuesday);
      final monday = NotificationService.nextInstance(tuesday8am, 7, 30,
          weekday: DateTime.monday);
      expect([monday.month, monday.day, monday.weekday], [9, 21, DateTime.monday]);
      final today = NotificationService.nextInstance(tuesday8am, 9, 0,
          weekday: DateTime.tuesday);
      expect(today.day, 15);
    });

    test('ข้ามสิ้นเดือนได้', () {
      final end = tz.TZDateTime(bangkok, 2026, 9, 30, 22);
      final t = NotificationService.nextInstance(end, 6, 0);
      expect([t.month, t.day], [10, 1]);
    });
  });

  group('รายการแจ้งเตือนของ habit', () {
    test('รายวัน / ต่อสัปดาห์ → เตือนทุกวัน 1 รายการ', () {
      final base = NotificationService.notifBase('h3') * 10;
      expect(NotificationService.slotsFor(_habit()), [(id: base, weekday: null)]);
      expect(NotificationService.slotsFor(_habit(type: 'times_per_week')),
          [(id: base, weekday: null)]);
    });

    test('เลือกวัน → แยกรายการตามวัน ไม่ซ้ำ', () {
      final base = NotificationService.notifBase('h3') * 10;
      final slots = NotificationService.slotsFor(
          _habit(type: 'specific_days', days: '[5,1,3,3,9]'));
      expect(slots, [
        (id: base + 1, weekday: 1),
        (id: base + 3, weekday: 3),
        (id: base + 5, weekday: 5),
      ]);
    });

    test('ไม่ได้ตั้งเวลา → ไม่มีรายการ', () {
      expect(NotificationService.slotsFor(_habit(reminder: null)), isEmpty);
    });

    test('รหัสจาก UUID คงที่ทุกครั้ง อยู่ในช่วง int32 และไม่ชนกับ habit อื่น', () {
      const a = '5f1c2d3e-4b5a-4c6d-8e7f-9a0b1c2d3e4f';
      const b = '5f1c2d3e-4b5a-4c6d-8e7f-9a0b1c2d3e40';
      final idsA = NotificationService.allIdsFor(a);
      expect(idsA, NotificationService.allIdsFor(a));
      expect(idsA.length, 8);
      expect(idsA.last - idsA.first, 7);
      expect(idsA.every((id) => id >= 0 && id <= 2147483647), isTrue);
      expect(idsA.toSet().intersection(NotificationService.allIdsFor(b).toSet()),
          isEmpty);
    });
  });

  group('ข้อความแจ้งเตือน', () {
    test('เชิงตัวเลข', () {
      expect(NotificationService.reminderBody(_habit(target: 8, unit: 'แก้ว')),
          'เป้าหมายวันนี้ 8 แก้ว');
    });
    test('ต่อสัปดาห์', () {
      expect(
          NotificationService.reminderBody(_habit(type: 'times_per_week', times: 3)),
          'เป้าสัปดาห์นี้ 3 ครั้ง');
    });
    test('ทั่วไป', () {
      expect(NotificationService.reminderBody(_habit()), 'ถึงเวลาทำแล้ว');
    });
  });
}
