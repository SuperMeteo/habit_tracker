import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../models/habit_icons.dart';
import '../providers/habits_provider.dart';
import '../../../shared/widgets/empty_state.dart';

class ManageHabitsScreen extends ConsumerWidget {
  const ManageHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(allHabitsProvider);
    final actions = ref.watch(habitActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการ Habit')),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return EmptyState(
              icon: Icons.checklist,
              title: 'ยังไม่มี Habit',
              subtitle: 'กด + เพื่อเพิ่ม Habit แรก',
            );
          }
          final active = habits.where((h) => h.isActive).toList();
          final paused = habits.where((h) => !h.isActive).toList();

          return ListView(
            children: [
              for (final habit in active) _tile(context, habit, actions),
              if (paused.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Text(
                    'พักไว้ (${paused.length})',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
                for (final habit in paused) _tile(context, habit, actions),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tile(BuildContext context, Habit habit, HabitActions actions) {
    final color = AppTheme.parseHex(habit.colorHex);
    final paused = !habit.isActive;
    return Opacity(
      opacity: paused ? 0.6 : 1,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(HabitIcons.fromCode(habit.iconCode), color: color, size: 20),
        ),
        title: Text(habit.name),
        subtitle: Text(paused ? 'พักไว้' : _frequencyLabel(habit)),
        trailing: paused
            ? TextButton(
                onPressed: () => actions.setHabitActive(habit.id, true),
                child: const Text('เลิกพัก'),
              )
            : IconButton(
                icon: const Icon(Icons.pause_circle_outline),
                tooltip: 'พักไว้ก่อน',
                onPressed: () => actions.setHabitActive(habit.id, false),
              ),
        onTap: () => context.push('/habits/edit', extra: habit),
      ),
    );
  }

  String _frequencyLabel(Habit habit) {
    switch (habit.frequencyType) {
      case 'daily':
        return 'ทุกวัน';
      case 'specific_days':
        return 'เลือกวัน';
      case 'times_per_week':
        return '${habit.timesPerWeek} ครั้ง/สัปดาห์';
      default:
        return habit.frequencyType;
    }
  }
}
