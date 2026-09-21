import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../database/app_database.dart';

typedef ReminderSlot = ({int id, int? weekday});

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'habit_reminders';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'เตือนทำ Habit',
      channelDescription: 'แจ้งเตือนตามเวลาที่ตั้งไว้ในแต่ละ habit',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initFuture;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() {
    if (!isSupported) return Future.value();
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() != false;
  }

  Future<void> syncAll(AppDatabase db) async {
    if (!isSupported) return;
    try {
      await init();
      await _plugin.cancelAll();
      for (final habit in await db.getActiveHabits()) {
        await _schedule(habit);
      }
    } catch (e) {
      debugPrint('NotificationService.syncAll: $e');
    }
  }

  Future<void> scheduleForHabit(Habit habit) async {
    if (!isSupported) return;
    try {
      await init();
      await _cancelIds(habit.id);
      await _schedule(habit);
    } catch (e) {
      debugPrint('NotificationService.scheduleForHabit: $e');
    }
  }

  Future<void> cancelForHabit(String habitId) async {
    if (!isSupported) return;
    try {
      await init();
      await _cancelIds(habitId);
    } catch (e) {
      debugPrint('NotificationService.cancelForHabit: $e');
    }
  }

  Future<void> _cancelIds(String habitId) async {
    for (final id in allIdsFor(habitId)) {
      await _plugin.cancel(id);
    }
  }

  Future<void> _schedule(Habit habit) async {
    final time = parseReminderTime(habit.reminderTime);
    if (time == null || !habit.isActive) return;
    final now = tz.TZDateTime.now(tz.local);
    for (final slot in slotsFor(habit)) {
      await _plugin.zonedSchedule(
        slot.id,
        habit.name,
        reminderBody(habit),
        nextInstance(now, time.hour, time.minute, weekday: slot.weekday),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: slot.weekday == null
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static const _maxBase = 214748364;

  static int notifBase(String habitId) {
    var hash = 0x811c9dc5;
    for (final unit in habitId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash % _maxBase;
  }

  static List<int> allIdsFor(String habitId) {
    final base = notifBase(habitId) * 10;
    return List.generate(8, (i) => base + i);
  }

  static List<ReminderSlot> slotsFor(Habit habit) {
    if (parseReminderTime(habit.reminderTime) == null) return const [];
    final base = notifBase(habit.id) * 10;
    if (habit.frequencyType != 'specific_days') {
      return [(id: base, weekday: null)];
    }
    List<int> days;
    try {
      days = List<int>.from(jsonDecode(habit.targetDays));
    } catch (_) {
      days = const [];
    }
    final valid = days.where((d) => d >= 1 && d <= 7).toSet().toList()..sort();
    return [for (final d in valid) (id: base + d, weekday: d)];
  }

  static ({int hour, int minute})? parseReminderTime(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }

  static tz.TZDateTime nextInstance(tz.TZDateTime now, int hour, int minute,
      {int? weekday}) {
    var t = tz.TZDateTime(
        now.location, now.year, now.month, now.day, hour, minute);
    while (!t.isAfter(now) || (weekday != null && t.weekday != weekday)) {
      t = tz.TZDateTime(now.location, t.year, t.month, t.day + 1, hour, minute);
    }
    return t;
  }

  static String reminderBody(Habit habit) {
    if (habit.targetValue != null) {
      final target = habit.targetValue!;
      final value =
          target % 1 == 0 ? target.toStringAsFixed(0) : target.toString();
      return 'เป้าหมายวันนี้ $value ${habit.unit ?? ''}'.trim();
    }
    if (habit.frequencyType == 'times_per_week') {
      return 'เป้าสัปดาห์นี้ ${habit.timesPerWeek} ครั้ง';
    }
    return 'ถึงเวลาทำแล้ว';
  }
}
