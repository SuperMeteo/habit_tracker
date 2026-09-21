import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// SupabaseClient — คืน null ถ้ายังไม่ได้ตั้งค่า credential (โหมด offline)
///
/// ใช้ผ่าน repository layer เท่านั้น อย่าเรียกใน UI ตรงๆ
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return Supabase.instance.client;
});

/// สถานะ auth ปัจจุบัน (stream) — คืน null ถ้า offline
final authStateProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

/// user ที่ login อยู่ (null = guest/offline)
final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  // watch auth state เพื่อให้ rebuild เมื่อ login/logout
  ref.watch(authStateProvider);
  return client?.auth.currentUser;
});
