import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Android / iOS / Windows / macOS / Linux — เก็บเป็นไฟล์ habit_tracker.db ในเครื่อง
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'habit_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
