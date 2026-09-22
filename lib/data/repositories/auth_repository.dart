import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../datasources/remote/auth_remote_ds.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null; // offline mode
  return AuthRepository(AuthRemoteDataSource(client));
});

// AppUser ปัจจุบัน (null = guest/offline)
final appUserProvider = StateNotifierProvider<AppUserNotifier, AppUser?>((ref) {
  return AppUserNotifier(ref);
});

class AppUserNotifier extends StateNotifier<AppUser?> {
  final Ref _ref;
  AppUserNotifier(this._ref) : super(null) {
    _init();
  }

  void _init() async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) return;
    state = await repo.getCurrentUser();

    // ฟัง auth state เปลี่ยน (login/logout)
    repo.authStateChanges.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn && event.session != null) {
        state = await repo.getCurrentUser();
      } else if (event.event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });
  }

  /// ดึงโปรไฟล์ใหม่จาก server — เรียกหลัง sync เพื่อให้แต้ม/แรงค์บนจอตรงกับของจริง
  Future<void> refresh() async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null || state == null) return;
    try {
      final fresh = await repo.getCurrentUser();
      if (fresh != null) state = fresh;
    } catch (_) {}
  }

  Future<void> signIn(String email, String password) async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) throw Exception('ไม่ได้เชื่อมต่อ Supabase');
    state = await repo.signIn(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String username) async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) throw Exception('ไม่ได้เชื่อมต่อ Supabase');
    state = await repo.signUp(email: email, password: password, username: username);
  }

  Future<void> signOut() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo?.signOut();
    state = null;
  }
}

class AuthRepository {
  final AuthRemoteDataSource _ds;
  AuthRepository(this._ds);

  Stream<AuthState> get authStateChanges => _ds.authStateChanges;
  Future<AppUser?> getCurrentUser() => _ds.getCurrentUser();
  Future<AppUser> signIn({required String email, required String password}) =>
      _ds.signIn(email: email, password: password);
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String username,
  }) => _ds.signUp(email: email, password: password, username: username);
  Future<void> signOut() => _ds.signOut();
  Future<bool> isUsernameAvailable(String name) =>
      _ds.isUsernameAvailable(name);
}
