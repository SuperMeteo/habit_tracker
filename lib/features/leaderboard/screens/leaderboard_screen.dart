import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../shared/widgets/empty_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // โหมด offline → ไม่มีอันดับให้ดู
    if (!SupabaseConfig.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('อันดับ')),
        body: const EmptyState(
          icon: Icons.cloud_off,
          title: 'ใช้งานแบบออฟไลน์',
          subtitle: 'ระบบอันดับต้องเชื่อมต่ออินเทอร์เน็ต',
        ),
      );
    }

    final user = ref.watch(appUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('อันดับ')),
        body: EmptyState(
          icon: Icons.leaderboard_outlined,
          title: 'ยังไม่ได้เข้าสู่ระบบ',
          subtitle: 'เข้าสู่ระบบเพื่อแข่งขันสะสมแต้มกับเพื่อน',
          action: FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('เข้าสู่ระบบ'),
          ),
        ),
      );
    }

    final mode = ref.watch(leaderboardModeProvider);
    final boardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('อันดับ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: () => ref.invalidate(leaderboardProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<LeaderboardMode>(
              segments: LeaderboardMode.values
                  .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                  .toList(),
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(leaderboardModeProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: boardAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'ยังไม่มีอันดับ',
                    subtitle: 'เริ่มทำ Habit เพื่อสะสมแต้มเป็นคนแรก!',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(leaderboardProvider),
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _RankTile(
                      entry: entries[i],
                      isMe: entries[i].userId == user.id,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'โหลดอันดับไม่สำเร็จ',
                subtitle: friendlyError(e),
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(leaderboardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  const _RankTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: isMe ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(child: _rankLabel(theme)),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                entry.username,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text('(คุณ)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary)),
              ),
          ],
        ),
        subtitle: Text('${entry.emoji} ${entry.tier}'),
        trailing: Text(
          '${entry.points}',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _rankLabel(ThemeData theme) {
    // อันดับ 1-3 ใช้เหรียญ
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final medal = medals[entry.rank];
    if (medal != null) return Text(medal, style: const TextStyle(fontSize: 22));
    return Text('${entry.rank}',
        style: theme.textTheme.titleMedium
            ?.copyWith(color: theme.colorScheme.outline));
  }
}
