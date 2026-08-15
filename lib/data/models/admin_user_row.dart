class AdminUserRow {
  final String id;
  final String username;
  final String displayName;
  final int totalPoints;
  final int weeklyPoints;
  final String tier;
  final String role;
  final int habitCount;

  const AdminUserRow({
    required this.id,
    required this.username,
    required this.displayName,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.tier,
    required this.role,
    required this.habitCount,
  });

  bool get isAdmin => role == 'admin';

  factory AdminUserRow.fromJson(Map<String, dynamic> j) => AdminUserRow(
        id: j['id'] as String? ?? '',
        username: j['username'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        weeklyPoints: (j['weekly_points'] as num?)?.toInt() ?? 0,
        tier: j['tier'] as String? ?? 'Bronze',
        role: j['role'] as String? ?? 'user',
        habitCount: (j['habit_count'] as num?)?.toInt() ?? 0,
      );
}

class AdminStats {
  final int totalUsers;
  final int totalHabits;
  final int totalLogs;
  final int pointsSum;

  const AdminStats({
    this.totalUsers = 0,
    this.totalHabits = 0,
    this.totalLogs = 0,
    this.pointsSum = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: (j['total_users'] as num?)?.toInt() ?? 0,
        totalHabits: (j['total_habits'] as num?)?.toInt() ?? 0,
        totalLogs: (j['total_logs'] as num?)?.toInt() ?? 0,
        pointsSum: (j['points_sum'] as num?)?.toInt() ?? 0,
      );
}
