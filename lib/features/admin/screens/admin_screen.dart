import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/admin_user_row.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/empty_state.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(appUserProvider);

    // guard ฝั่ง client (ฝั่ง server มี is_admin() กันอีกชั้น)
    if (me == null || !me.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ระบบหลังบ้าน')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'ไม่มีสิทธิ์เข้าถึง',
          subtitle: 'หน้านี้สำหรับผู้ดูแลระบบเท่านั้น',
        ),
      );
    }

    final usersAsync = ref.watch(adminUsersProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบหลังบ้าน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: () {
              ref.invalidate(adminUsersProvider);
              ref.invalidate(adminStatsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminUsersProvider);
          ref.invalidate(adminStatsProvider);
        },
        child: ListView(
          children: [
            statsAsync.when(
              data: (s) => _StatsGrid(stats: s),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('โหลดสถิติไม่สำเร็จ: $e',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('ผู้ใช้ทั้งหมด',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
            ),
            usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'ยังไม่มีผู้ใช้',
                  );
                }
                return Column(
                  children: users
                      .map((u) => _UserRow(
                            user: u,
                            isMe: u.id == me.id,
                            onAdjust: (delta) =>
                                _adjust(context, ref, u, delta),
                            onToggleRole: () => _toggleRole(context, ref, u),
                          ))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('โหลดผู้ใช้ไม่สำเร็จ: $e',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _adjust(
      BuildContext context, WidgetRef ref, AdminUserRow u, int delta) async {
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.adjustPoints(userId: u.id, delta: delta);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ปรับแต้ม ${u.username} ${delta > 0 ? '+' : ''}$delta'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ปรับแต้มไม่สำเร็จ — ${friendlyError(e)}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _toggleRole(
      BuildContext context, WidgetRef ref, AdminUserRow u) async {
    final next = u.isAdmin ? 'user' : 'admin';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เปลี่ยนสิทธิ์'),
        content: Text('เปลี่ยนสิทธิ์ของ "${u.username}" เป็น "$next" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน')),
        ],
      ),
    );
    if (ok != true) return;

    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.setRole(userId: u.id, role: next);
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เปลี่ยนสิทธิ์ไม่สำเร็จ: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('ผู้ใช้', '${stats.totalUsers}', Icons.people),
      ('Habit', '${stats.totalHabits}', Icons.checklist),
      ('บันทึกสำเร็จ', '${stats.totalLogs}', Icons.done_all),
      ('แต้มรวม', '${stats.pointsSum}', Icons.stars),
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((it) {
          final (label, value, icon) = it;
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 40) / 2,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(label,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AdminUserRow user;
  final bool isMe;
  final void Function(int delta) onAdjust;
  final VoidCallback onToggleRole;

  const _UserRow({
    required this.user,
    required this.isMe,
    required this.onAdjust,
    required this.onToggleRole,
  });

  static const _tierEmoji = {
    'Bronze': '🥉', 'Silver': '🥈', 'Gold': '🥇',
    'Platinum': '💎', 'Diamond': '🔷',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: user.isAdmin
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: user.isAdmin
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
              child: Text(user.username, overflow: TextOverflow.ellipsis)),
          if (user.isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Chip(
                label: const Text('admin', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('(คุณ)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.primary)),
            ),
        ],
      ),
      subtitle: Text(
        '${_tierEmoji[user.tier] ?? '🥉'} ${user.tier} · '
        '${user.totalPoints} แต้ม · ${user.habitCount} habit',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สัปดาห์นี้: ${user.weeklyPoints} แต้ม',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton(
                      onPressed: () => onAdjust(10), child: const Text('+10')),
                  OutlinedButton(
                      onPressed: () => onAdjust(50), child: const Text('+50')),
                  OutlinedButton(
                      onPressed: () => onAdjust(-10), child: const Text('-10')),
                  TextButton.icon(
                    icon: Icon(user.isAdmin
                        ? Icons.remove_moderator_outlined
                        : Icons.admin_panel_settings_outlined),
                    label: Text(user.isAdmin ? 'ถอด admin' : 'ตั้งเป็น admin'),
                    onPressed: onToggleRole,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
