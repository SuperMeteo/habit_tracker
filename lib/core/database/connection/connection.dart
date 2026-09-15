// เลือกตัวเชื่อมต่อฐานข้อมูลตามแพลตฟอร์มที่คอมไพล์
// - มือถือ / เดสก์ท็อป (มี dart:io) -> native.dart  = SQLite ไฟล์จริงในเครื่อง (ของเดิม)
// - เว็บ (มี dart:js_interop)       -> web.dart     = SQLite เวอร์ชัน WebAssembly ในเบราว์เซอร์
export 'unsupported.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.js_interop) 'web.dart';
