import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_leader.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../habits/models/habit_icons.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_card.dart';

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
            onPressed: () {
              ref.invalidate(leaderboardProvider);
              ref.invalidate(categoryBoardsProvider);
            },
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
          _CategoryBoards(
            boards: ref.watch(categoryBoardsProvider),
            myUserId: user.id,
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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

class _CategoryBoards extends StatelessWidget {
  final AsyncValue<List<CategoryBoard>> boards;
  final String myUserId;
  const _CategoryBoards({required this.boards, required this.myUserId});

  @override
  Widget build(BuildContext context) {
    final list = boards.valueOrNull ?? const <CategoryBoard>[];
    if (list.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionTitle('แชมป์แต่ละด้าน'),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _BoardCard(
              board: list[i],
              isMine: list[i].champion?.userId == myUserId,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text('อันดับรวมทุกด้าน',
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _BoardCard extends StatelessWidget {
  final CategoryBoard board;
  final bool isMine;
  const _BoardCard({required this.board, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.parseHex(board.colorHex);
    final champ = board.champion;

    return SizedBox(
      width: 196,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        tint: color,
        highlighted: isMine,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(HabitIcons.fromCode(board.iconCode),
                      color: color, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(board.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const Spacer(),
            if (champ == null)
              Text('ยังไม่มีใครทำ',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline))
            else ...[
              Row(
                children: [
                  const Text('🥇', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(champ.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('${champ.points} แต้ม ${champ.emoji}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            Text('แข่งกัน ${board.players} คน',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      highlighted: isMe,
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
