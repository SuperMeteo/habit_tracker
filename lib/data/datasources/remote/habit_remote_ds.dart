import 'package:supabase_flutter/supabase_flutter.dart';

/// อ่าน/เขียน habits + habit_logs บน Supabase (ใช้โดย SyncService)
///
/// หมายเหตุ: ไม่ส่ง points_awarded ขึ้นไป — ฝั่ง server คำนวณเองผ่าน trigger
/// (กัน client โกงแต้ม) แล้วเราดึงค่าที่คำนวณแล้วกลับลงมาตอน pull
class HabitRemoteDataSource {
  final SupabaseClient _client;
  HabitRemoteDataSource(this._client);

  String get _uid => _client.auth.currentUser!.id;

  // ─── Habits ───────────────────────────────────────────────────────────────

  Future<void> pushHabits(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('habits').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> pullHabits(DateTime? since) async {
    var query = _client.from('habits').select().eq('user_id', _uid);
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    final data = await query;
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ─── Habit logs ───────────────────────────────────────────────────────────

  Future<void> pushLogs(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('habit_logs').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> pullLogs(DateTime? since) async {
    var query = _client.from('habit_logs').select().eq('user_id', _uid);
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    final data = await query;
    return (data as List).cast<Map<String, dynamic>>();
  }
}
