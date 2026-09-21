import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../datasources/remote/leaderboard_remote_ds.dart';
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

class LeaderboardRepository {
  final LeaderboardRemoteDataSource _ds;
  LeaderboardRepository(this._ds);

  Future<List<LeaderboardEntry>> fetch({
    required LeaderboardMode mode,
    int limit = 100,
  }) =>
      _ds.fetch(mode: mode, limit: limit);
}
