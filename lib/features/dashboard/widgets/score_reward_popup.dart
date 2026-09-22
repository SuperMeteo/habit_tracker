import 'package:flutter/material.dart';
import '../../../core/scoring/score_calculator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rank_badge.dart';

class ScoreReward {
  final int gained;
  final int total;
  final String categoryName;
  final Color categoryColor;
  final int streak;
  final double multiplier;
  final bool allFourDone;
  final bool tierUp;
  final String tier;

  const ScoreReward({
    required this.gained,
    required this.total,
    required this.categoryName,
    required this.categoryColor,
    required this.streak,
    required this.multiplier,
    required this.allFourDone,
    required this.tierUp,
    required this.tier,
  });
}

Future<void> showScoreReward(BuildContext context, ScoreReward reward) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'ได้คะแนน',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, __) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + 0.15 * curved.value.clamp(0.0, 1.0),
          child: _RewardCard(reward: reward),
        ),
      );
    },
  );
}

class _RewardCard extends StatefulWidget {
  final ScoreReward reward;
  const _RewardCard({required this.reward});

  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  @override
  void initState() {
    super.initState();
    final wait = widget.reward.tierUp || widget.reward.allFourDone
        ? const Duration(milliseconds: 2600)
        : const Duration(milliseconds: 1700);
    Future.delayed(wait, () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    final theme = Theme.of(context);
    final info = tierInfo(r.tier);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius + 6),
            border: Border.all(color: r.categoryColor.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: r.categoryColor.withValues(alpha: 0.28),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.tierUp) ...[
                RankBadge(tier: r.tier, size: 62),
                const SizedBox(height: 10),
                Text(
                  'เลื่อนขั้นเป็น ${info.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: info.gradient.last,
                  ),
                ),
                const SizedBox(height: 10),
              ] else if (r.allFourDone) ...[
                Text('🎉', style: const TextStyle(fontSize: 42)),
                const SizedBox(height: 6),
                Text(
                  'ครบทั้ง 4 ด้านของวันนี้',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                '+${r.gained}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: r.categoryColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'คะแนนด้าน${r.categoryName}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              if (r.multiplier > 1) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: r.categoryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ต่อเนื่อง ${r.streak} วัน  ×${_fmt(r.multiplier)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: r.categoryColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RankBadge(tier: r.tier, size: 24, showStars: false),
                  const SizedBox(width: 8),
                  Text(
                    'คะแนนรวม ${r.total}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

ScoreReward? buildReward({
  required ScoreResult before,
  required ScoreResult after,
  required String Function(String id) nameOf,
  required Color Function(String id) colorOf,
}) {
  final gained = after.total - before.total;
  if (gained <= 0) return null;

  var bestId = after.byCategory.keys.first;
  var bestGain = 0;
  for (final entry in after.byCategory.entries) {
    final diff = entry.value.points - (before.byCategory[entry.key]?.points ?? 0);
    if (diff > bestGain) {
      bestGain = diff;
      bestId = entry.key;
    }
  }

  final cat = after.byCategory[bestId];
  final beforeTier = ScoreCalculator.tierOf(before.total);
  final afterTier = ScoreCalculator.tierOf(after.total);

  return ScoreReward(
    gained: gained,
    total: after.total,
    categoryName: nameOf(bestId),
    categoryColor: colorOf(bestId),
    streak: cat?.streak ?? 0,
    multiplier: ScoreCalculator.multiplier(cat?.streak ?? 1),
    allFourDone: after.doneTodayCount == 4 && before.doneTodayCount < 4,
    tierUp: beforeTier != afterTier,
    tier: afterTier,
  );
}
