import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../models/admin_user_row.dart';

final adminRepositoryProvider = Provider<AdminRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return AdminRepository(client);
});

final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminUserRow>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  if (repo == null) return [];
  return repo.listUsers();
});

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  if (repo == null) return const AdminStats();
  return repo.stats();
});

/// เรียก Postgres function ฝั่ง admin — ทุกตัวมี guard `is_admin()` บน server
/// ถ้า user ธรรมดาเรียก จะได้ exception 'forbidden: admin only'
class AdminRepository {
  final SupabaseClient _client;
  AdminRepository(this._client);

  Future<List<AdminUserRow>> listUsers({int limit = 200}) async {
    final data = await _client.rpc('admin_list_users', params: {'lim': limit});
    if (data is! List) return [];
    return data.cast<Map<String, dynamic>>().map(AdminUserRow.fromJson).toList();
  }

  Future<AdminStats> stats() async {
    final data = await _client.rpc('admin_stats');
    if (data is List && data.isNotEmpty) {
      return AdminStats.fromJson(data.first as Map<String, dynamic>);
    }
    return const AdminStats();
  }

  Future<void> adjustPoints({
    required String userId,
    required int delta,
    String note = 'admin_adjust',
  }) =>
      _client.rpc('admin_adjust_points',
          params: {'target_user': userId, 'delta': delta, 'note': note});

  Future<void> setRole({required String userId, required String role}) =>
      _client.rpc('admin_set_role',
          params: {'target_user': userId, 'new_role': role});
}
