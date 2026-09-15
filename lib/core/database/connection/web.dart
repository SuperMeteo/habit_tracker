import 'package:flutter/foundation.dart';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// เว็บ — ใช้ SQLite ที่คอมไพล์เป็น WebAssembly เก็บข้อมูลไว้ในเบราว์เซอร์
/// ต้องมีไฟล์ web/sqlite3.wasm และ web/drift_worker.js อยู่ด้วย
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'habit_tracker',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // ไม่ใช่ error — แค่บอกว่าเบราว์เซอร์ขาดความสามารถบางอย่าง
      // drift จะถอยไปใช้วิธีเก็บข้อมูลแบบอื่นให้เอง
      debugPrint('drift/web: เบราว์เซอร์ไม่มี ${result.missingFeatures} '
          'จึงใช้วิธีเก็บข้อมูลแบบ ${result.chosenImplementation}');
    }

    return result.resolvedExecutor;
  }));
}
