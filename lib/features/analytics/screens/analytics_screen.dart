import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../widgets/streak_card.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/weekly_bar_chart.dart';
import '../../../shared/widgets/empty_state.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(analyticsProvider);
    final heatmapAsync = ref.watch(heatmapProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('สถิติ',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),

          // Heatmap
          SliverToBoxAdapter(
            child: heatmapAsync.when(
              data: (data) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: CalendarHeatmap(
                    data: data,
                    maxValue: data.values.isEmpty
                        ? 1
                        : data.values.reduce((a, b) => a > b ? a : b)),
              ),
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Charts for numeric habits
          statsAsync.when(
            data: (stats) {
              final numericStats =
                  stats.where((s) => s.habit.targetValue != null).toList();
              if (numericStats.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('กราฟความคืบหน้า',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ...numericStats.map((s) => Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: WeeklyBarChart(
                              habit: s.habit, logs: s.recentLogs),
                        )),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Streak cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Streak รายละเอียด',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          statsAsync.when(
            data: (stats) {
              if (stats.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'ยังไม่มีข้อมูล',
                    subtitle: 'เพิ่ม Habit และเริ่ม log เพื่อดูสถิติ',
                  ),
                );
              }
              final sorted = [...stats]
                ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => StreakCard(stats: sorted[i]),
                  childCount: sorted.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
