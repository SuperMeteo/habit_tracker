import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/user_public_stats.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_stats_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../habits/models/habit_icons.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(appUserProvider);
    final isMe = me?.id == userId;
    final async = ref.watch(userProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text(isMe ? 'โปรไฟล์ของฉัน' : 'โปรไฟล์')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'โหลดโปรไฟล์ไม่สำเร็จ',
          subtitle: friendlyError(e),
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(userProfileProvider(userId)),
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'ไม่พบผู้ใช้นี้',
              subtitle: 'บัญชีอาจถูกลบไปแล้ว',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userProfileProvider(userId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _header(context, data.stats),
                const SectionTitle('แต้ม'),
                _pointsRow(context, data.stats),
                const SectionTitle('ความสม่ำเสมอ'),
                _streakRow(context, data.stats),
                const SectionTitle('แต้มแยกตามด้าน'),
                _byCategory(context, data),
                const SizedBox(height: 16),
                _privacyNote(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, UserPublicStats s) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              s.username.isNotEmpty ? s.username[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                if (s.displayName.isNotEmpty && s.displayName != s.username)
                  Text(s.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(context, '${s.emoji} ${s.tier}',
                        theme.colorScheme.primary),
                    if (s.joinedAt != null)
                      _chip(
                          context,
                          'เข้าร่วม ${DateFormat('MMM yyyy', 'th').format(s.joinedAt!)}',
                          theme.colorScheme.outline),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );

  Widget _pointsRow(BuildContext context, UserPublicStats s) => Row(
        children: [
          Expanded(
              child: _statCard(context, 'แต้มสะสม', '${s.totalPoints}',
                  Icons.stars_rounded, Colors.amber.shade700)),
          const SizedBox(width: 10),
          Expanded(
              child: _statCard(context, 'สัปดาห์นี้', '${s.weeklyPoints}',
                  Icons.calendar_today_rounded, Colors.indigo)),
        ],
      );

  Widget _streakRow(BuildContext context, UserPublicStats s) => Row(
        children: [
          Expanded(
              child: _statCard(context, 'ต่อเนื่องล่าสุด', '${s.currentStreak} วัน',
                  Icons.local_fire_department, Colors.deepOrange)),
          const SizedBox(width: 10),
          Expanded(
              child: _statCard(context, 'สถิติสูงสุด', '${s.bestStreak} วัน',
                  Icons.emoji_events, Colors.teal)),
          const SizedBox(width: 10),
          Expanded(
              child: _statCard(context, 'วันที่ทำสำเร็จ', '${s.doneDays} วัน',
                  Icons.check_circle, Colors.green)),
        ],
      );

  Widget _statCard(
      BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _byCategory(BuildContext context, UserProfileData data) {
    if (data.byCategory.isEmpty) {
      return const AppCard(
        child: Text('ยังไม่มีแต้มในด้านใดเลย', textAlign: TextAlign.center),
      );
    }
    final max = data.byCategory.first.points;
    return AppCard(
      child: Column(
        children: [
          for (final c in data.byCategory) ...[
            _categoryRow(context, c, max),
            if (c != data.byCategory.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _categoryRow(BuildContext context, CategoryPoints c, int max) {
    final theme = Theme.of(context);
    final color = AppTheme.parseHex(c.colorHex);
    return Row(
      children: [
        ProgressRing(
          value: max == 0 ? 0 : c.points / max,
          color: color,
          size: 46,
          stroke: 5,
          child: Icon(HabitIcons.fromCode(c.iconCode), color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : c.points / max,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('${c.points}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _privacyNote(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'เห็นได้แค่ยอดแต้มรวม — ชื่อ Habit และบันทึกรายวันเป็นความลับ',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }
}
