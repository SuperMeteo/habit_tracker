import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get colorHex => text().withDefault(const Constant('#6366F1'))();
  IntColumn get iconCode => integer().withDefault(const Constant(0xe532))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
