import 'leaderboard_entry.dart';

class CategoryLeader {
  final String categoryId;
  final int players;
  final int rank;
  final String userId;
  final String username;
  final String tier;
  final int points;

  const CategoryLeader({
    required this.categoryId,
    required this.players,
    required this.rank,
    required this.userId,
    required this.username,
    required this.tier,
    required this.points,
  });

  factory CategoryLeader.fromJson(Map<String, dynamic> json) => CategoryLeader(
        categoryId: json['category_id'] as String? ?? '',
        players: (json['players'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        tier: json['tier'] as String? ?? 'Bronze',
        points: (json['points'] as num?)?.toInt() ?? 0,
      );

  String get emoji => LeaderboardEntry.tierEmoji[tier] ?? '🥉';
}

class CategoryBoard {
  final String categoryId;
  final String name;
  final String colorHex;
  final int iconCode;
  final int players;
  final List<CategoryLeader> leaders;

  const CategoryBoard({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.iconCode,
    required this.players,
    required this.leaders,
  });

  CategoryLeader? get champion => leaders.isEmpty ? null : leaders.first;
}
