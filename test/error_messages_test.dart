import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/utils/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('error ที่เจอจริงตอนทดสอบ', () {
    test('อีเมลโดเมนมั่ว → บอกให้ใช้อีเมลจริง', () {
      final msg = friendlyError(const AuthApiException(
        'Email address "test@g.com" is invalid',
        statusCode: '400',
        code: 'email_address_invalid',
      ));
      expect(msg, contains('อีเมล'));
      expect(msg, contains('gmail.com'));
      expect(msg, isNot(contains('AuthApiException')));
    });

    test('ปิดระบบสมัครด้วยอีเมล → บอกว่าปิดรับสมัคร', () {
      final msg = friendlyError(const AuthApiException(
        'Email signups are disabled',
        statusCode: '400',
        code: 'email_provider_disabled',
      ));
      expect(msg, contains('ปิดรับสมัคร'));
      expect(msg, isNot(contains('disabled')));
    });

    test('ชื่อผู้ใช้ซ้ำ (500 จาก trigger) → บอกให้เปลี่ยนชื่อผู้ใช้', () {
      final msg = friendlyError(const AuthApiException(
        '{"code":"unexpected_failure","message":"Database error saving new user"}',
        statusCode: '500',
        code: 'unexpected_failure',
      ));
      expect(msg, contains('ชื่อผู้ใช้'));
      expect(msg, isNot(contains('Database error')));
      expect(msg, isNot(contains('500')));
    });
  });

  group('error อื่นที่ผู้ใช้มีโอกาสเจอ', () {
    test('รหัสผ่านผิด', () {
      expect(
        friendlyError(const AuthApiException('Invalid login credentials',
            statusCode: '400', code: 'invalid_credentials')),
        'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      );
    });

    test('เน็ตหลุด → บอกให้เช็กสัญญาณ ไม่โชว์ชื่อคลาส', () {
      final msg = friendlyError(
          Exception('ClientException with SocketException: Failed host lookup'));
      expect(msg, contains('อินเทอร์เน็ต'));
      expect(msg, isNot(contains('SocketException')));
    });

    test('ข้อมูลซ้ำในฐานข้อมูล', () {
      expect(
        friendlyError(const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505')),
        contains('มีอยู่แล้ว'),
      );
    });

    test('ยังไม่ได้สร้างตารางบนคลาวด์', () {
      expect(
        friendlyError(const PostgrestException(
            message: 'Could not find the table', code: 'PGRST205')),
        contains('ผู้ดูแล'),
      );
    });

    test('เซสชันหมดอายุ', () {
      expect(
        friendlyError(const PostgrestException(
            message: 'JWT expired', code: 'PGRST301')),
        contains('เข้าสู่ระบบใหม่'),
      );
    });

    test('ไม่มีสิทธิ์ admin', () {
      expect(
        friendlyError(const PostgrestException(
            message: 'forbidden: admin only', code: 'P0001')),
        contains('ผู้ดูแล'),
      );
    });
  });

  group('ข้อความไทยที่เราเขียนเองใน SQL', () {
    test('ด่านล็อกอินของหน้าโปรไฟล์ → ส่งข้อความไทยผ่านไปตรง ๆ', () {
      expect(
        friendlyError(const PostgrestException(
            message: 'ต้องเข้าสู่ระบบก่อนดูโปรไฟล์ผู้อื่น', code: 'P0001')),
        'ต้องเข้าสู่ระบบก่อนดูโปรไฟล์ผู้อื่น',
      );
    });

    test('ข้อความไทยที่มีร่องรอยระบบปนมา → ไม่ปล่อยผ่าน', () {
      final msg = friendlyError(const PostgrestException(
          message: 'ผิดพลาด: relation "habits" does not exist', code: 'XX000'));
      expect(msg, 'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง');
    });

    test('ข้อความอังกฤษที่ไม่รู้จัก → ไม่ปล่อยผ่าน', () {
      expect(
        friendlyError(const PostgrestException(
            message: 'something odd happened', code: 'XX001')),
        'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง',
      );
    });
  });

  group('ทุกกรณีต้องไม่หลุดภาษาโปรแกรมเมอร์', () {
    final samples = <Object?>[
      null,
      Exception('something exploded'),
      StateError('bad state'),
      'random string',
      const AuthApiException('who knows', statusCode: '418', code: 'teapot'),
      const PostgrestException(message: 'mystery', code: 'XX999'),
    ];

    for (final s in samples) {
      test('${s.runtimeType}: ไม่มีคำศัพท์เทคนิคหลุดออกมา', () {
        final msg = friendlyError(s);
        expect(msg, isNotEmpty);
        for (final banned in [
          'Exception',
          'Error(',
          'statusCode',
          'code:',
          'null',
          '{',
          'PostgrestException',
        ]) {
          expect(msg, isNot(contains(banned)), reason: 'เจอ "$banned" ใน: $msg');
        }
      });
    }
  });
}
