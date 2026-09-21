class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int points;
  final String tier;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.points,
    required this.tier,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? 'Bronze',
    );
  }

  static const tierEmoji = {
    'Bronze': '🥉',
    'Silver': '🥈',
    'Gold': '🥇',
    'Platinum': '💎',
    'Diamond': '🔷',
  };

  String get emoji => tierEmoji[tier] ?? '🥉';
}

/// โหมดการจัดอันดับ — ตรงกับพารามิเตอร์ `mode` ของ Postgres function get_leaderboard
enum LeaderboardMode {
  weekly('weekly', 'สัปดาห์นี้'),
  allTime('alltime', 'ตลอดกาล');

  final String value;
  final String label;
  const LeaderboardMode(this.value, this.label);
}
