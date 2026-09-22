import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_leader.dart';
import '../../models/leaderboard_entry.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class LeaderboardRemoteDataSource {
  final SupabaseClient _client;
  LeaderboardRemoteDataSource(this._client);

  /// เรียก Postgres function get_leaderboard(mode, lim)
  Future<List<LeaderboardEntry>> fetch({
    required LeaderboardMode mode,
    int limit = 100,
    String? categoryId,
    DateTime? asOf,
  }) async {
    final data = await _client.rpc(
      'get_leaderboard',
      params: {
        'mode': mode.value,
        'lim': limit,
        'as_of': _day(asOf ?? DateTime.now()),
        if (categoryId != null) 'cat': categoryId,
      },
    );
    if (data is! List) return [];
    return data
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
  }

  /// เรียก get_category_leaders — ได้แค่รหัสหมวด ไม่มีชื่อหมวด
  /// ชื่อหมวดให้ชั้น repository เอาจากฐานข้อมูลในเครื่องมาใส่
  Future<List<CategoryLeader>> fetchCategoryLeaders({
    required LeaderboardMode mode,
    int perCategory = 3,
    int minPlayers = 2,
  }) async {
    final data = await _client.rpc(
      'get_category_leaders',
      params: {
        'mode': mode.value,
        'per_category': perCategory,
        'min_players': minPlayers,
        'as_of': _day(DateTime.now()),
      },
    );
    if (data is! List) return [];
    return data
        .cast<Map<String, dynamic>>()
        .map(CategoryLeader.fromJson)
        .toList();
  }
}
