import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int totalPoints;
  final int weeklyPoints;
  final String tier;
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.totalPoints = 0,
    this.weeklyPoints = 0,
    this.tier = 'Bronze',
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromSupabase(User user, Map<String, dynamic> profile) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      username: profile['username'] as String? ?? '',
      displayName: profile['display_name'] as String? ?? '',
      avatarUrl: profile['avatar_url'] as String?,
      totalPoints: profile['total_points'] as int? ?? 0,
      weeklyPoints: profile['weekly_points'] as int? ?? 0,
      tier: profile['tier'] as String? ?? 'Bronze',
      role: profile['role'] as String? ?? 'user',
    );
  }
}
