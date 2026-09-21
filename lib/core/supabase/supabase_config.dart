/// ค่าเชื่อมต่อ Supabase — ส่งผ่าน --dart-define (ไม่ hardcode key ลง git)
///
/// รันด้วย run_dev.ps1 หรือ:
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co
///               --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
///
/// ถ้ายังไม่ตั้งค่า → [isConfigured] = false → offline mode (ไม่ init Supabase)
class SupabaseConfig {
  static const url    = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
