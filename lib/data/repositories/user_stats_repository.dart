import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../features/habits/providers/habits_provider.dart';
import '../datasources/remote/user_stats_remote_ds.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_public_stats.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return UserStatsRepository(UserStatsRemoteDataSource(client));
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfileData?, String>(
  (ref, userId) async {
    final repo = ref.watch(userStatsRepositoryProvider);
    if (repo == null) return null;
    final db = ref.watch(databaseProvider);
    return repo.profile(userId, categories: await db.getAllCategories());
  },
);

class UserStatsRepository {
  final UserStatsRemoteDataSource _ds;
  UserStatsRepository(this._ds);

  Future<UserProfileData?> profile(
    String userId, {
    required List<Category> categories,
    LeaderboardMode mode = LeaderboardMode.allTime,
  }) async {
    final stats = await _ds.fetchStats(userId);
    if (stats == null) return null;
    final points = await _ds.fetchCategoryPoints(userId, mode: mode);
    return UserProfileData(
      stats: stats,
      byCategory: mergeCategoryPoints(points, categories),
    );
  }

  /// เอาชื่อ/สี/ไอคอนหมวดจากเครื่องตัวเองมาประกอบกับยอดแต้มจากเซิร์ฟเวอร์
  ///
  /// แยกเป็นฟังก์ชันล้วนเพื่อทดสอบได้ตรง ๆ โดยไม่ต้องต่อเน็ต
  /// หมวดที่เครื่องนี้ไม่รู้จัก (หมวดที่คนนั้นสร้างเอง) จะรวมเป็น "ด้านอื่น ๆ"
  /// ไม่ทิ้งแต้มหาย เพราะยอดรวมจะไม่ตรงกับแต้มสะสมแล้วผู้ใช้จะสงสัย
  static List<CategoryPoints> mergeCategoryPoints(
    Map<String, int> points,
    List<Category> categories,
  ) {
    final byId = {for (final c in categories) c.id: c};
    final known = <CategoryPoints>[];
    var otherPoints = 0;

    for (final entry in points.entries) {
      final cat = byId[entry.key];
      if (cat == null) {
        otherPoints += entry.value;
        continue;
      }
      known.add(CategoryPoints(
        categoryId: cat.id,
        name: cat.name,
        colorHex: cat.colorHex,
        iconCode: cat.iconCode,
        points: entry.value,
      ));
    }

    known.sort((a, b) => b.points.compareTo(a.points));

    if (otherPoints > 0) {
      known.add(CategoryPoints(
        categoryId: '',
        name: 'ด้านอื่น ๆ',
        colorHex: '#9CA3AF',
        iconCode: 0xe532,
        points: otherPoints,
      ));
    }
    return known;
  }
}
