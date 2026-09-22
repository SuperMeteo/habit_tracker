import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/data/models/user_public_stats.dart';
import 'package:habit_tracker/data/repositories/user_stats_repository.dart';

const health = '11111111-1111-4111-8111-111111111101';
const money = '11111111-1111-4111-8111-111111111103';
const stranger = '99999999-9999-4999-8999-999999999999';

Category _cat(String id, String name, String color, int icon) => Category(
      id: id,
      name: name,
      colorHex: color,
      iconCode: icon,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      syncStatus: 'synced',
    );

void main() {
  final myCats = [
    _cat(health, 'ร่างกาย', '#EF4444', 11),
    _cat(money, 'การเงิน', '#10B981', 22),
  ];

  List<CategoryPoints> merge(Map<String, int> points) =>
      UserStatsRepository.mergeCategoryPoints(points, myCats);

  test('ใช้ชื่อและสีหมวดจากเครื่องตัวเอง', () {
    final out = merge({health: 120});
    expect(out.single.name, 'ร่างกาย');
    expect(out.single.colorHex, '#EF4444');
    expect(out.single.iconCode, 11);
    expect(out.single.points, 120);
  });

  test('เรียงจากแต้มมากไปน้อย', () {
    final out = merge({health: 50, money: 300});
    expect(out.map((c) => c.name), ['การเงิน', 'ร่างกาย']);
  });

  test('หมวดที่เครื่องนี้ไม่รู้จัก → รวมเป็น "ด้านอื่น ๆ" ไม่ทำให้แต้มหาย', () {
    final out = merge({health: 100, stranger: 40});
    expect(out.map((c) => c.name), ['ร่างกาย', 'ด้านอื่น ๆ']);
    expect(out.last.points, 40);
    expect(out.fold<int>(0, (s, c) => s + c.points), 140);
  });

  test('หมวดแปลกหน้าหลายอันถูกรวมเป็นก้อนเดียว', () {
    final out = merge({
      stranger: 10,
      '88888888-8888-4888-8888-888888888888': 25,
    });
    expect(out.length, 1);
    expect(out.single.name, 'ด้านอื่น ๆ');
    expect(out.single.points, 35);
  });

  test('"ด้านอื่น ๆ" อยู่ท้ายสุดเสมอ แม้แต้มจะมากกว่า', () {
    final out = merge({health: 10, stranger: 999});
    expect(out.last.name, 'ด้านอื่น ๆ');
  });

  test('ไม่มีแต้มเลย → ลิสต์ว่าง', () {
    expect(merge({}), isEmpty);
  });

  group('แปลง json จากเซิร์ฟเวอร์', () {
    test('ครบทุกช่อง', () {
      final s = UserPublicStats.fromJson({
        'user_id': 'u1',
        'username': 'meteo',
        'display_name': 'ภูตะวัน',
        'tier': 'Gold',
        'total_points': 1600,
        'weekly_points': 90,
        'done_days': 42,
        'current_streak': 7,
        'best_streak': 15,
        'joined_at': '2026-09-01T10:00:00+00:00',
      });
      expect(s.username, 'meteo');
      expect(s.displayName, 'ภูตะวัน');
      expect(s.tier, 'Gold');
      expect(s.emoji, '🥇');
      expect(s.totalPoints, 1600);
      expect(s.currentStreak, 7);
      expect(s.bestStreak, 15);
      expect(s.joinedAt?.year, 2026);
    });

    test('display_name ว่าง → ใช้ username แทน', () {
      final s = UserPublicStats.fromJson(
          {'username': 'meteo', 'display_name': '   '});
      expect(s.displayName, 'meteo');
    });

    test('json ขาดช่อง → ค่าตั้งต้น ไม่ throw', () {
      final s = UserPublicStats.fromJson(const {});
      expect(s.username, '');
      expect(s.tier, 'Bronze');
      expect(s.totalPoints, 0);
      expect(s.currentStreak, 0);
      expect(s.joinedAt, isNull);
    });

    test('วันที่เข้าร่วมรูปแบบผิด → เป็น null ไม่ throw', () {
      final s = UserPublicStats.fromJson(const {'joined_at': 'ไม่ใช่วันที่'});
      expect(s.joinedAt, isNull);
    });
  });

  test('ยอดรวมของทุกด้านคำนวณถูก', () {
    final data = UserProfileData(
      stats: UserPublicStats.fromJson(const {'username': 'a'}),
      byCategory: merge({health: 30, money: 70, stranger: 5}),
    );
    expect(data.categoryTotal, 105);
  });
}
