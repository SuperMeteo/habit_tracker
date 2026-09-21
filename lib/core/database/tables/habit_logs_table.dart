import 'package:drift/drift.dart';
import 'habits_table.dart';

class HabitLogs extends Table {
  // UUID (sync-ready)
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get loggedDate => dateTime()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  // for numeric habits (e.g. glasses of water)
  RealColumn get value => real().nullable()();
  TextColumn get note => text().nullable()();
  // แต้มที่ได้จาก log นี้ — server (Supabase) เป็นคนคำนวณจริง, ฝั่ง local เก็บ mirror ไว้
  IntColumn get pointsAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // ─── sync fields ───────────────────────────────────────────────
  TextColumn get userId => text().nullable()();           // null = guest
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();     // 'pending' | 'synced'

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, loggedDate},
      ];
}
