import 'package:intl/intl.dart';

class HabitDateUtils {
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday; // Mon=1
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static String formatDate(DateTime date) =>
      DateFormat('EEE, d MMM', 'th').format(date);

  static String formatShortDate(DateTime date) =>
      DateFormat('d/M', 'th').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'th').format(date);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  static String dayName(int weekday) {
    const names = ['', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return names[weekday];
  }
}
