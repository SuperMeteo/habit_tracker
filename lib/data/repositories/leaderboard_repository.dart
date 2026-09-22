import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../features/habits/providers/habits_provider.dart';
import '../datasources/remote/leaderboard_remote_ds.dart';
import '../models/category_leader.dart';
import '../models/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null; // offline mode
  return LeaderboardRepository(LeaderboardRemoteDataSource(client));
});

/// โหมดที่เลือกอยู่บนหน้า leaderboard
final leaderboardModeProvider =
    StateProvider<LeaderboardMode>((ref) => LeaderboardMode.weekly);

/// รายการอันดับตามโหมดที่เลือก
final leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  if (repo == null) return [];
  final mode = ref.watch(leaderboardModeProvider);
  return repo.fetch(mode: mode);
});

/// บอร์ดแยกด้าน — ชื่อและสีของหมวดมาจากฐานข้อมูลในเครื่อง
/// เซิร์ฟเวอร์ส่งมาแค่รหัสหมวด เพราะแต่ละคนตั้งชื่อหมวดเองได้
final categoryBoardsProvider =
    FutureProvider.autoDispose<List<CategoryBoard>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  if (repo == null) return [];
  final mode = ref.watch(leaderboardModeProvider);
  final db = ref.watch(databaseProvider);
  return repo.categoryBoards(mode: mode, categories: await db.getAllCategories());
});

class LeaderboardRepository {
  final LeaderboardRemoteDataSource _ds;
  LeaderboardRepository(this._ds);

  Future<List<LeaderboardEntry>> fetch({
    required LeaderboardMode mode,
    int limit = 100,
  }) =>
      _ds.fetch(mode: mode, limit: limit);

  Future<List<CategoryBoard>> categoryBoards({
    required LeaderboardMode mode,
    required List<Category> categories,
    int perCategory = 3,
    int minPlayers = 2,
  }) async {
    final rows = await _ds.fetchCategoryLeaders(
      mode: mode,
      perCategory: perCategory,
      minPlayers: minPlayers,
    );
    return groupCategoryBoards(rows, categories);
  }

  /// จับกลุ่มผลจากเซิร์ฟเวอร์เข้ากับหมวดที่มีอยู่ในเครื่อง
  ///
  /// แยกเป็นฟังก์ชันล้วน (ไม่แตะเน็ต) เพื่อทดสอบตรรกะได้ตรง ๆ
  /// หมวดที่เครื่องนี้ไม่รู้จัก (หมวดที่คนอื่นสร้างเอง) จะถูกข้ามไป
  /// ไม่ใช่เพราะกันข้อมูล แต่เพราะไม่มีชื่อจะแสดง และเทียบกันไม่ได้อยู่แล้ว
  static List<CategoryBoard> groupCategoryBoards(
    List<CategoryLeader> rows,
    List<Category> categories,
  ) {
    if (rows.isEmpty) return [];

    final byId = {for (final c in categories) c.id: c};
    final grouped = <String, List<CategoryLeader>>{};
    for (final row in rows) {
      if (!byId.containsKey(row.categoryId)) continue;
      grouped.putIfAbsent(row.categoryId, () => []).add(row);
    }

    final boards = <CategoryBoard>[];
    for (final entry in grouped.entries) {
      final cat = byId[entry.key]!;
      final leaders = [...entry.value]..sort((a, b) => a.rank.compareTo(b.rank));
      boards.add(CategoryBoard(
        categoryId: cat.id,
        name: cat.name,
        colorHex: cat.colorHex,
        iconCode: cat.iconCode,
        players: leaders.first.players,
        leaders: leaders,
      ));
    }
    boards.sort((a, b) {
      final byPlayers = b.players.compareTo(a.players);
      if (byPlayers != 0) return byPlayers;
      return a.name.compareTo(b.name);
    });
    return boards;
  }
}
