import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/scoring/score_calculator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/rank_badge.dart';
import '../../habits/providers/habits_provider.dart';

class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(scoreProvider);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final theme = Theme.of(context);
    final total = score.total;
    final tier = ScoreCalculator.tierOf(total);
    final info = tierInfo(tier);
    final next = ScoreCalculator.nextTierAt(total);
    final toNext = (next - total).clamp(0, next);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RankBadge(tier: tier, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คะแนนรวม',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$total',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          info.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: info.gradient.last,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      total >= 10000
                          ? 'ระดับสูงสุดแล้ว'
                          : 'อีก $toNext คะแนนขึ้นระดับถัดไป',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Bar(
            value: total,
            max: next,
            color: info.gradient.last,
            height: 12,
          ),
          const SizedBox(height: 18),
          Text(
            'คะแนนแยกด้าน',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final id in scoredCategoryIds)
            _CategoryRow(
              name: _nameOf(cats, id),
              color: _colorOf(cats, id, theme),
              score: score.byCategory[id],
              maxPoints: _maxOf(score),
            ),
          const SizedBox(height: 6),
          Text(
            'ทำครบทั้ง 4 ด้านในหนึ่งวันได้อย่างน้อย 40 คะแนน · '
            'ยิ่งทำติดกันยิ่งได้ตัวคูณ · วันไหนไม่ทำจะถูกหัก 5',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  static int _maxOf(ScoreResult r) {
    var max = 10;
    for (final c in r.byCategory.values) {
      if (c.points > max) max = c.points;
    }
    return max;
  }

  static String _nameOf(List<Category> cats, String id) {
    for (final c in cats) {
      if (c.id == id) return c.name;
    }
    const fallback = {
      '11111111-1111-4111-8111-111111111101': 'ร่างกาย',
      '11111111-1111-4111-8111-111111111106': 'การกิน',
      '11111111-1111-4111-8111-111111111107': 'การนอน',
      '11111111-1111-4111-8111-111111111108': 'จิตใจ',
    };
    return fallback[id] ?? 'อื่น ๆ';
  }

  static Color _colorOf(List<Category> cats, String id, ThemeData theme) {
    for (final c in cats) {
      if (c.id == id) return AppTheme.parseHex(c.colorHex);
    }
    return theme.colorScheme.primary;
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final Color color;
  final CategoryScore? score;
  final int maxPoints;

  const _CategoryRow({
    required this.name,
    required this.color,
    required this.score,
    required this.maxPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = score?.points ?? 0;
    final streak = score?.streak ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (streak > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'ต่อเนื่อง $streak วัน',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              Text(
                '$points',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Bar(value: points, max: maxPoints, color: color, height: 8),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final double height;

  const _Bar({
    required this.value,
    required this.max,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          LayoutBuilder(
            builder: (context, c) => AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: height,
              width: c.maxWidth * ratio,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.65), color],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
