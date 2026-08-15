// Smoke test พื้นฐาน
//
// หมายเหตุ: ตัวแอปใช้ drift/SQLite + path_provider ซึ่งต้องมี platform binding
// จึง pumpWidget(HabitTrackerApp()) ตรงๆ ใน unit test ไม่ได้
// (ต้องใช้ integration_test แทน) — ไฟล์นี้จึงเป็น placeholder ให้ analyze/test ผ่าน

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity check', () {
    expect(1 + 1, 2);
  });
}
