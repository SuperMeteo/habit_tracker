import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/data/models/category_leader.dart';
import 'package:habit_tracker/data/repositories/leaderboard_repository.dart';

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

Map<String, dynamic> _row(String catId, int rank, String user, int points,
        {int players = 2}) =>
    {
      'category_id': catId,
      'players': players,
      'rank': rank,
      'user_id': 'id-$user',
      'username': user,
      'tier': 'Bronze',
      'points': points,
    };

void main() {
  final myCats = [
    _cat(health, 'ร่างกาย', '#EF4444', 11),
    _cat(money, 'การเงิน', '#10B981', 22),
  ];

  List<CategoryBoard> boardsFrom(List<Map<String, dynamic>> rows) =>
      LeaderboardRepository.groupCategoryBoards(
        rows.map(CategoryLeader.fromJson).toList(),
        myCats,
      );

  test('ใช้ชื่อและสีหมวดจากเครื่องตัวเอง ไม่ใช่จากเซิร์ฟเวอร์', () {
    final boards = boardsFrom([
      _row(health, 1, 'meteo', 120),
      _row(health, 2, 'nita', 80),
    ]);

    expect(boards.single.name, 'ร่างกาย');
    expect(boards.single.colorHex, '#EF4444');
    expect(boards.single.iconCode, 11);
  });

  test('แชมป์คืออันดับ 1 และเรียงอันดับให้ถูกแม้เซิร์ฟเวอร์ส่งมาสลับ', () {
    final boards = boardsFrom([
      _row(health, 3, 'ck', 20),
      _row(health, 1, 'meteo', 120),
      _row(health, 2, 'nita', 80),
    ]);

    expect(boards.single.champion!.username, 'meteo');
    expect(boards.single.leaders.map((l) => l.rank), [1, 2, 3]);
  });

  test('หมวดที่เครื่องนี้ไม่รู้จัก (คนอื่นสร้างเอง) ถูกข้าม ไม่พัง', () {
    final boards = boardsFrom([
      _row(stranger, 1, 'someone', 500),
      _row(health, 1, 'meteo', 10),
    ]);

    expect(boards.map((b) => b.categoryId), [health]);
  });

  test('เรียงด้านที่มีคนแข่งเยอะไว้ก่อน', () {
    final boards = boardsFrom([
      _row(money, 1, 'nita', 50, players: 2),
      _row(health, 1, 'meteo', 10, players: 7),
    ]);

    expect(boards.map((b) => b.name), ['ร่างกาย', 'การเงิน']);
    expect(boards.first.players, 7);
  });

  test('ไม่มีข้อมูลจากเซิร์ฟเวอร์ → ได้ลิสต์ว่าง ไม่ throw', () {
    expect(boardsFrom([]), isEmpty);
  });

  test('อันดับแปลงจาก json ครบทุกช่อง', () {
    final l = CategoryLeader.fromJson(_row(health, 2, 'nita', 80, players: 5));
    expect(l.categoryId, health);
    expect(l.rank, 2);
    expect(l.username, 'nita');
    expect(l.points, 80);
    expect(l.players, 5);
    expect(l.emoji, '🥉');
  });

  test('json ที่ขาดช่อง → ใช้ค่าตั้งต้น ไม่ throw', () {
    final l = CategoryLeader.fromJson(const {});
    expect(l.categoryId, '');
    expect(l.rank, 0);
    expect(l.points, 0);
    expect(l.tier, 'Bronze');
  });
}
