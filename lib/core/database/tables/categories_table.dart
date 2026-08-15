import 'package:drift/drift.dart';

class Categories extends Table {
  // UUID (sync-ready) — ไม่ใช้ autoIncrement เพราะ id จะชนกันตอน sync หลายเครื่อง
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get colorHex => text().withDefault(const Constant('#6366F1'))();
  IntColumn get iconCode => integer().withDefault(const Constant(0xe532))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // ─── sync fields ───────────────────────────────────────────────
  TextColumn get userId => text().nullable()();           // null = default/guest
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();     // 'pending' | 'synced'

  @override
  Set<Column> get primaryKey => {id};
}
