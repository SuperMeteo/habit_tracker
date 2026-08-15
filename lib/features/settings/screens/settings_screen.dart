import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/sync/sync_service.dart';
import '../../../data/repositories/auth_repository.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('theme_mode') ?? 'system';
    state = ThemeMode.values.firstWhere((e) => e.name == v,
        orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(appUserProvider);
    final isOnline = SupabaseConfig.isConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        children: [
          // ─── โปรไฟล์ / บัญชี ──────────────────────────────────────────
          if (isOnline) ...[
            _SectionHeader(label: 'บัญชีผู้ใช้'),
            if (user != null)
              _UserTile(
                username: user.username,
                email: user.email,
                tier: user.tier,
                totalPoints: user.totalPoints,
                onLogout: () async {
                  await ref.read(appUserProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('ยังไม่ได้เข้าสู่ระบบ'),
                subtitle: const Text('กดเพื่อ login / สมัครสมาชิก'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/login'),
              ),
            if (user != null) ...[
              _SyncTile(
                state: ref.watch(syncServiceProvider),
                onSync: () => ref.read(syncServiceProvider.notifier).sync(),
              ),
              if (user.isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('ระบบหลังบ้าน (Admin)'),
                  subtitle: const Text('จัดการผู้ใช้และแต้ม'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin'),
                ),
            ],
            const Divider(),
          ],
          _SectionHeader(label: 'รูปแบบการแสดงผล'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('ตามระบบ'),
                    icon: Icon(Icons.brightness_auto)),
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('สว่าง'),
                    icon: Icon(Icons.light_mode)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('มืด'),
                    icon: Icon(Icons.dark_mode)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const Divider(),
          _SectionHeader(label: 'Habit'),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('จัดการ Habit ทั้งหมด'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/habits/manage'),
          ),
          const Divider(),
          _SectionHeader(label: 'เกี่ยวกับ'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Habit Tracker'),
            subtitle: const Text('v1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SyncTile extends StatelessWidget {
  final SyncState state;
  final VoidCallback onSync;
  const _SyncTile({required this.state, required this.onSync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncing = state.status == SyncStatus.syncing;

    String subtitle;
    Color? color;
    switch (state.status) {
      case SyncStatus.syncing:
        subtitle = 'กำลังซิงค์...';
      case SyncStatus.success:
        subtitle = 'ซิงค์ล่าสุด: ${_fmt(state.lastSyncAt)}';
      case SyncStatus.failed:
        subtitle = 'ซิงค์ไม่สำเร็จ: ${state.message ?? ''}';
        color = theme.colorScheme.error;
      case SyncStatus.idle:
        subtitle = state.lastSyncAt != null
            ? 'ซิงค์ล่าสุด: ${_fmt(state.lastSyncAt)}'
            : 'ยังไม่เคยซิงค์';
    }

    return ListTile(
      leading: syncing
          ? const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync),
      title: const Text('ซิงค์ข้อมูลกับคลาวด์'),
      subtitle: Text(subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: color != null ? TextStyle(color: color) : null),
      trailing: syncing ? null : const Icon(Icons.chevron_right),
      onTap: syncing ? null : onSync,
    );
  }

  static String _fmt(DateTime? t) {
    if (t == null) return '-';
    two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }
}

class _UserTile extends StatelessWidget {
  final String username;
  final String email;
  final String tier;
  final int totalPoints;
  final VoidCallback onLogout;
  const _UserTile({
    required this.username,
    required this.email,
    required this.tier,
    required this.totalPoints,
    required this.onLogout,
  });

  static const _tierIcon = {
    'Bronze': '🥉', 'Silver': '🥈', 'Gold': '🥇',
    'Platinum': '💎', 'Diamond': '🔷',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold)),
          ),
          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(email),
          trailing: Chip(
            label: Text('${_tierIcon[tier] ?? '🥉'} $tier',
                style: const TextStyle(fontSize: 12)),
            padding: EdgeInsets.zero,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('$totalPoints แต้มสะสม',
                  style: theme.textTheme.bodySmall),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('ออกจากระบบ'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
    );
  }
}
