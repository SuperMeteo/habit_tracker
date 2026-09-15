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
    final habitsAsync = ref.watch(habitsProvider);

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
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (_, i) {
              final habit = habits[i];
              final color = AppTheme.parseHex(habit.colorHex);
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(HabitIcons.fromCode(habit.iconCode),
                      color: color, size: 20),
                ),
                title: Text(habit.name),
                subtitle: Text(_frequencyLabel(habit)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/habits/edit', extra: habit),
              );
            },
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
