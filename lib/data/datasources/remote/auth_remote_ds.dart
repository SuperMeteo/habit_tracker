import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';

/// สมัครสำเร็จแล้ว แต่โปรเจกต์เปิด "Confirm email" ไว้ → ต้องยืนยันอีเมลก่อนใช้งาน
class EmailConfirmationRequired implements Exception {
  const EmailConfirmationRequired();
  @override
  String toString() =>
      'สมัครสำเร็จ! กรุณายืนยันอีเมลจากลิงก์ที่ส่งไป แล้วกลับมาเข้าสู่ระบบ';
}

class AuthRemoteDataSource {
  final SupabaseClient _client;
  AuthRemoteDataSource(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': username},
    );
    if (res.user == null) throw Exception('สมัครสมาชิกไม่สำเร็จ');

    // ถ้าโปรเจกต์เปิด "Confirm email" ไว้ จะยังไม่ได้ session
    // → ยังใช้งานไม่ได้จนกว่าจะยืนยันอีเมล บอกผู้ใช้ให้ชัดแทนที่จะ error งงๆ
    if (res.session == null) {
      throw const EmailConfirmationRequired();
    }

    // profile ถูกสร้างอัตโนมัติจาก trigger — รอแล้ว fetch
    await Future.delayed(const Duration(milliseconds: 500));
    return _fetchProfile(res.user!);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('login ไม่สำเร็จ');
    return _fetchProfile(res.user!);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user);
  }

  Future<AppUser> _fetchProfile(User user) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) throw Exception('ไม่พบโปรไฟล์');
    return AppUser.fromSupabase(user, data);
  }
}
