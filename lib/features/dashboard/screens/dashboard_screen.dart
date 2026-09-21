import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../habits/providers/habits_provider.dart';
import '../widgets/habit_grid_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final actions = ref.watch(habitActionsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref, selectedDate),
          _buildDateStrip(context, ref, selectedDate),
          SliverToBoxAdapter(
            child: dashboardAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'ยังไม่มี Habit วันนี้',
                    subtitle: 'กด + เพื่อเพิ่ม Habit แรกของคุณ',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/habits/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่ม Habit'),
                    ),
                  );
                }
                final done = items.where((i) => i.log?.isDone == true).length;
                return Column(
                  children: [
                    _buildSummaryCard(context, done, items.length),
                    _buildGrid(context, ref, items, actions, selectedDate),
                    const SizedBox(height: 100),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(friendlyError(e), textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/add'),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่ม Habit'),
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final isToday = HabitDateUtils.isSameDay(selectedDate, DateTime.now());
    final user = ref.watch(appUserProvider);
    return SliverAppBar(
      floating: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday
                ? (user != null ? 'สวัสดี ${user.username}' : 'วันนี้')
                : HabitDateUtils.formatDate(selectedDate),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'th').format(selectedDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: _TierBadge(tier: user.tier, points: user.weeklyPoints),
            ),
          ),
        if (!isToday)
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'กลับวันนี้',
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }



  Future<void> _onToggle(
    BuildContext context,
    HabitActions actions,
    HabitWithLog item,
    DateTime date,
  ) async {
    final isDone = item.log?.isDone ?? false;
    if (isDone) {
      final ok = await _confirmUndo(context, item.habit.name);
      if (!ok) return;
    }
    await actions.toggleHabit(item.habit.id, date, isDone);
  }

  Future<bool> _confirmUndo(BuildContext context, String name) async {
    final theme = Theme.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        icon: Icon(Icons.undo_rounded, color: theme.colorScheme.primary),
        title: const Text('ยกเลิกที่ทำไว้?'),
        content: Text(
          '"$name" จะกลับไปเป็นยังไม่ได้ทำ และแต้มที่ได้จะถูกหักคืน',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('เก็บไว้เหมือนเดิม'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 44),
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<HabitWithLog> items,
    HabitActions actions,
    DateTime selectedDate,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1280
        ? 4
        : width >= 880
            ? 3
            : 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          return HabitGridCard(
            item: item,
            onToggle: () =>
                _onToggle(context, actions, item, selectedDate),
            onNumericTap: () =>
                _showNumericDialog(context, ref, item, actions, selectedDate),
          );
        },
      ),
    );
  }

  Widget _buildDateStrip(
      BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final today = HabitDateUtils.today();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: days.length,
          itemBuilder: (context, i) {
            final day = days[i];
            final isSelected = HabitDateUtils.isSameDay(day, selectedDate);
            final isToday = HabitDateUtils.isSameDay(day, today);
            final color = Theme.of(context).colorScheme.primary;
            return GestureDetector(
              onTap: () =>
                  ref.read(selectedDateProvider.notifier).state = day,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : isToday
                          ? color.withValues(alpha: 0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      HabitDateUtils.dayName(day.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int done, int total) {
    final progress = total == 0 ? 0.0 : done / total;
    final theme = Theme.of(context);
    final allDone = total > 0 && done == total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient(theme),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: AppTheme.softShadow(theme),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ความคืบหน้าวันนี้',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$done จาก $total',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    allDone
                        ? 'ครบทุกอย่างแล้ว เยี่ยมมาก'
                        : total == 0
                            ? 'ยังไม่มี Habit วันนี้'
                            : 'เหลืออีก ${total - done} อย่าง',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ProgressRing(
              value: progress,
              color: Colors.white,
              trackColor: Colors.white24,
              size: 86,
              stroke: 9,
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumericDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    HabitActions actions,
    DateTime date,
  ) {
    final controller = TextEditingController(
      text: item.log?.value?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.habit.name),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'ค่า',
            suffixText: item.habit.unit ?? '',
            hintText: 'เป้าหมาย: ${item.habit.targetValue}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                actions.logNumericValue(item.habit.id, date, value);
              }
              Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  final int points;
  const _TierBadge({required this.tier, required this.points});

  static const _icon = {
    'Bronze': '🥉',
    'Silver': '🥈',
    'Gold': '🥇',
    'Platinum': '💎',
    'Diamond': '🔷',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_icon[tier] ?? '🥉'} $points',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
