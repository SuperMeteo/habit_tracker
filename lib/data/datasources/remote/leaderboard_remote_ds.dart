import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leaderboard_entry.dart';

class LeaderboardRemoteDataSource {
  final SupabaseClient _client;
  LeaderboardRemoteDataSource(this._client);

  /// เรียก Postgres function get_leaderboard(mode, lim)
  Future<List<LeaderboardEntry>> fetch({
    required LeaderboardMode mode,
    int limit = 100,
  }) async {
    final data = await _client.rpc(
      'get_leaderboard',
      params: {'mode': mode.value, 'lim': limit},
    );
    if (data is! List) return [];
    return data
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
  }
}
