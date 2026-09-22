import 'leaderboard_entry.dart';

class UserPublicStats {
  final String userId;
  final String username;
  final String displayName;
  final String tier;
  final int totalPoints;
  final int weeklyPoints;
  final int doneDays;
  final int currentStreak;
  final int bestStreak;
  final DateTime? joinedAt;

  const UserPublicStats({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.tier,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.doneDays,
    required this.currentStreak,
    required this.bestStreak,
    this.joinedAt,
  });

  factory UserPublicStats.fromJson(Map<String, dynamic> json) =>
      UserPublicStats(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
            ? (json['display_name'] as String).trim()
            : (json['username'] as String? ?? ''),
        tier: json['tier'] as String? ?? 'Bronze',
        totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
        weeklyPoints: (json['weekly_points'] as num?)?.toInt() ?? 0,
        doneDays: (json['done_days'] as num?)?.toInt() ?? 0,
        currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
        bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
        joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? ''),
      );

  String get emoji => LeaderboardEntry.tierEmoji[tier] ?? '🥉';
}

class CategoryPoints {
  final String categoryId;
  final String name;
  final String colorHex;
  final int iconCode;
  final int points;

  const CategoryPoints({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.iconCode,
    required this.points,
  });
}

class UserProfileData {
  final UserPublicStats stats;
  final List<CategoryPoints> byCategory;

  const UserProfileData({required this.stats, required this.byCategory});

  int get categoryTotal =>
      byCategory.fold(0, (sum, c) => sum + c.points);
}
