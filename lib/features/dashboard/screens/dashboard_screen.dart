import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../habits/providers/habits_provider.dart';
import '../widgets/habit_card.dart';
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
                    ...items.map((item) => HabitCard(
                          item: item,
                          onToggle: () => actions.toggleHabit(
                              item.habit.id, selectedDate, item.log?.isDone),
                          onNumericTap: () =>
                              _showNumericDialog(context, ref, item, actions, selectedDate),
                        )),
                    const SizedBox(height: 100),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 4),
                  Text(
                    '$done / $total',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
