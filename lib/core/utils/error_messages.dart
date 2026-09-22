import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _fallback = 'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง';
const _offline = 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ ตรวจสอบสัญญาณแล้วลองใหม่';

String friendlyError(Object? error) {
  if (error == null) return _fallback;

  final raw = error.toString();
  if (kDebugMode) debugPrint('[error] $raw');

  if (_looksOffline(raw)) return _offline;

  if (error is AuthException) {
    final byCode = _authByCode[error.code];
    if (byCode != null) return byCode;
    return _authByText(error.message) ??
        _passThroughThai(error.message) ??
        _fallback;
  }

  if (error is PostgrestException) {
    final byCode = _postgrestByCode[error.code];
    if (byCode != null) return byCode;
    return _authByText(error.message) ?? _passThroughThai(error.message) ?? _fallback;
  }

  return _authByText(raw) ?? _fallback;
}

// ข้อความที่เราเขียนเองใน SQL (raise exception) เป็นภาษาไทยที่อ่านรู้เรื่องอยู่แล้ว
// ถ้าไม่ปล่อยผ่าน จะถูกกลืนเป็น "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง" ซึ่งแย่กว่าเดิม
// เงื่อนไข: ต้องมีอักษรไทย และต้องไม่มีร่องรอยข้อความของระบบปนมา
String? _passThroughThai(String message) {
  final msg = message.trim();
  if (msg.isEmpty || msg.length > 200) return null;
  final hasThai = RegExp(r'[฀-๿]').hasMatch(msg);
  if (!hasThai) return null;
  final looksTechnical = RegExp(
          r'Exception|statusCode|\{|\}|null|::|SQLSTATE|relation |column ',
          caseSensitive: false)
      .hasMatch(msg);
  if (looksTechnical) return null;
  return msg;
}

bool _looksOffline(String raw) {
  final s = raw.toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('clientexception') ||
      s.contains('connection refused') ||
      s.contains('connection closed') ||
      s.contains('network is unreachable') ||
      s.contains('timeoutexception') ||
      s.contains('xmlhttprequest');
}

const _authByCode = <String, String>{
  'email_address_invalid':
      'รูปแบบอีเมลไม่ถูกต้อง ลองใช้อีเมลจริง เช่น ชื่อคุณ@gmail.com',
  'email_exists': 'อีเมลนี้เคยสมัครไว้แล้ว ลองเข้าสู่ระบบแทน',
  'user_already_exists': 'อีเมลนี้เคยสมัครไว้แล้ว ลองเข้าสู่ระบบแทน',
  'email_provider_disabled':
      'ตอนนี้ระบบปิดรับสมัครด้วยอีเมลอยู่ กรุณาติดต่อผู้ดูแล',
  'signup_disabled': 'ตอนนี้ปิดรับสมัครสมาชิกชั่วคราว',
  'email_not_confirmed':
      'ยังไม่ได้ยืนยันอีเมล กรุณากดลิงก์ในอีเมลก่อนเข้าสู่ระบบ',
  'invalid_credentials': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
  'weak_password': 'รหัสผ่านสั้นเกินไป ใช้อย่างน้อย 6 ตัวอักษร',
  'same_password': 'รหัสผ่านใหม่ซ้ำกับรหัสเดิม',
  'over_request_rate_limit': 'ลองบ่อยเกินไป รอสักครู่แล้วลองใหม่',
  'over_email_send_rate_limit': 'ส่งอีเมลบ่อยเกินไป รอสักครู่แล้วลองใหม่',
  'validation_failed': 'กรอกข้อมูลไม่ครบหรือรูปแบบไม่ถูกต้อง',
  'session_expired': 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
  'unexpected_failure':
      'สมัครไม่สำเร็จ — ชื่อผู้ใช้นี้อาจมีคนใช้แล้ว ลองเปลี่ยนชื่อผู้ใช้',
};

const _postgrestByCode = <String, String>{
  '23505': 'ข้อมูลนี้มีอยู่แล้ว ลองใช้ชื่ออื่น',
  '23503': 'ข้อมูลเชื่อมโยงไม่ครบ ลองซิงก์ข้อมูลใหม่อีกครั้ง',
  '23502': 'กรอกข้อมูลไม่ครบ',
  '42501': 'ไม่มีสิทธิ์เข้าถึงข้อมูลนี้',
  'PGRST301': 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
  'PGRST205': 'ระบบหลังบ้านยังตั้งค่าไม่ครบ กรุณาติดต่อผู้ดูแล',
  'PGRST116': 'ไม่พบข้อมูลที่ต้องการ',
};

String? _authByText(String message) {
  final s = message.toLowerCase();
  if (s.contains('database error saving new user')) {
    return 'สมัครไม่สำเร็จ — ชื่อผู้ใช้นี้อาจมีคนใช้แล้ว ลองเปลี่ยนชื่อผู้ใช้';
  }
  if (s.contains('invalid login credentials')) {
    return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
  }
  if (s.contains('email signups are disabled')) {
    return 'ตอนนี้ระบบปิดรับสมัครด้วยอีเมลอยู่ กรุณาติดต่อผู้ดูแล';
  }
  if (s.contains('is invalid') && s.contains('email')) {
    return 'รูปแบบอีเมลไม่ถูกต้อง ลองใช้อีเมลจริง เช่น ชื่อคุณ@gmail.com';
  }
  if (s.contains('already registered') || s.contains('already exists')) {
    return 'มีข้อมูลนี้อยู่แล้ว ลองใช้ชื่อหรืออีเมลอื่น';
  }
  if (s.contains('duplicate key')) {
    return 'ข้อมูลนี้มีอยู่แล้ว ลองใช้ชื่ออื่น';
  }
  if (s.contains('password') && s.contains('least')) {
    return 'รหัสผ่านสั้นเกินไป ใช้อย่างน้อย 6 ตัวอักษร';
  }
  if (s.contains('forbidden') || s.contains('admin only')) {
    return 'ต้องมีสิทธิ์ผู้ดูแลถึงจะทำรายการนี้ได้';
  }
  if (s.contains('jwt') || s.contains('token')) {
    return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
  }
  if (s.contains('ไม่ได้เชื่อมต่อ supabase')) {
    return 'ตอนนี้ใช้งานแบบออฟไลน์อยู่ ฟีเจอร์นี้ต้องเชื่อมต่ออินเทอร์เน็ต';
  }
  if (s.contains('ไม่พบโปรไฟล์')) {
    return 'ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่อีกครั้ง';
  }
  if (s.contains('login ไม่สำเร็จ')) {
    return 'เข้าสู่ระบบไม่สำเร็จ ลองใหม่อีกครั้ง';
  }
  if (s.contains('สมัครสมาชิกไม่สำเร็จ')) {
    return 'สมัครสมาชิกไม่สำเร็จ ลองใหม่อีกครั้ง';
  }
  return null;
}
