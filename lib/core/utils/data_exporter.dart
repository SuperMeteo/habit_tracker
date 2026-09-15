import 'dart:convert';
import '../database/app_database.dart';

class DataExporter {
  static const _bom = '﻿';

  static String toCsv({
    required List<Category> categories,
    required List<Habit> habits,
    required List<HabitLog> logs,
  }) {
    final habitById = {for (final h in habits) h.id: h};
    final categoryById = {for (final c in categories) c.id: c};
    final sorted = [...logs]
      ..sort((a, b) {
        final byDate = a.loggedDate.compareTo(b.loggedDate);
        return byDate != 0 ? byDate : a.habitId.compareTo(b.habitId);
      });

    final buffer = StringBuffer(_bom)
      ..write(_row([
        'วันที่', 'habit', 'หมวดหมู่', 'ทำแล้ว',
        'ค่า', 'หน่วย', 'เป้าหมาย', 'บันทึก',
      ]));
    for (final log in sorted) {
      final habit = habitById[log.habitId];
      final category = habit == null ? null : categoryById[habit.categoryId];
      buffer.write(_row([
        formatDate(log.loggedDate),
        _text(habit?.name),
        _text(category?.name),
        log.isDone ? '1' : '0',
        _number(log.value),
        _text(habit?.unit),
        _number(habit?.targetValue),
        _text(log.note),
      ]));
    }
    return buffer.toString();
  }

  static String toJson({
    required List<Category> categories,
    required List<Habit> habits,
    required List<HabitLog> logs,
    required DateTime exportedAt,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'habit_tracker',
      'formatVersion': 1,
      'exportedAt': exportedAt.toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'habits': habits.map((h) => h.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
    });
  }

  static String fileName(DateTime now, String extension) =>
      'habit_tracker_${formatDate(now)}.$extension';

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _row(List<String> cells) => '${cells.map(_cell).join(',')}\r\n';

  static String _cell(String value) {
    if (value.contains(RegExp(r'[",\r\n]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _text(String? value) {
    if (value == null || value.isEmpty) return '';
    if (RegExp(r'^[=+\-@\t\r]').hasMatch(value)) return "'$value";
    return value;
  }

  static String _number(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}
