import 'package:drift/drift.dart';
import 'habits_table.dart';

class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id)();
  DateTimeColumn get loggedDate => dateTime()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  // for numeric habits (e.g. glasses of water)
  RealColumn get value => real().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, loggedDate},
      ];
}
