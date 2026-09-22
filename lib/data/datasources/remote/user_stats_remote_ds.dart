import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leaderboard_entry.dart';
import '../../models/user_public_stats.dart';

class UserStatsRemoteDataSource {
  final SupabaseClient _client;
  UserStatsRemoteDataSource(this._client);

  /// as_of ส่งวันที่ของเครื่องผู้ใช้ไป ไม่ปล่อยให้เซิร์ฟเวอร์ใช้ current_date
  /// เพราะเซิร์ฟเวอร์เดินเวลาเป็น UTC ไทยเร็วกว่า 7 ชม. ตอนดึก ๆ จะคลาดกัน 1 วัน
  Future<UserPublicStats?> fetchStats(String userId) async {
    final today = DateTime.now();
    final asOf =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final data = await _client.rpc(
      'get_user_public_stats',
      params: {'target': userId, 'as_of': asOf},
    );
    if (data is! List || data.isEmpty) return null;
    return UserPublicStats.fromJson(data.first as Map<String, dynamic>);
  }

  /// ได้แค่รหัสหมวด + ยอดแต้ม — ชื่อหมวดให้ชั้น repository เอาจากเครื่องมาใส่
  Future<Map<String, int>> fetchCategoryPoints(
    String userId, {
    LeaderboardMode mode = LeaderboardMode.allTime,
  }) async {
    final data = await _client.rpc(
      'get_user_category_points',
      params: {'target': userId, 'mode': mode.value},
    );
    if (data is! List) return {};
    final out = <String, int>{};
    for (final row in data.cast<Map<String, dynamic>>()) {
      final id = row['category_id'] as String?;
      if (id == null) continue;
      out[id] = (row['points'] as num?)?.toInt() ?? 0;
    }
    return out;
  }
}
