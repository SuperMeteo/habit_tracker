import 'package:drift/drift.dart';
import 'categories_table.dart';

class Habits extends Table {
  // UUID (sync-ready)
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  // 'daily' | 'specific_days' | 'times_per_week'
  TextColumn get frequencyType => text().withDefault(const Constant('daily'))();
  // JSON list e.g. "[1,3,5]" Mon=1 Sun=7
  TextColumn get targetDays => text().withDefault(const Constant('[1,2,3,4,5,6,7]'))();
  IntColumn get timesPerWeek => integer().withDefault(const Constant(1))();
  // null = boolean habit, >0 = numeric habit
  RealColumn get targetValue => real().nullable()();
  TextColumn get unit => text().nullable()();
  // "HH:mm" format, null = no reminder
  TextColumn get reminderTime => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#6366F1'))();
  IntColumn get iconCode => integer().withDefault(const Constant(0xe532))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // ─── sync fields ───────────────────────────────────────────────
  TextColumn get userId => text().nullable()();           // null = guest
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();     // 'pending' | 'synced'

  @override
  Set<Column> get primaryKey => {id};
}
