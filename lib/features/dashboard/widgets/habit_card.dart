import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../habits/providers/habits_provider.dart';
import '../../habits/models/habit_icons.dart';

class HabitCard extends StatelessWidget {
  final HabitWithLog item;
  final VoidCallback onToggle;
  final VoidCallback? onNumericTap;

  const HabitCard({
    super.key,
    required this.item,
    required this.onToggle,
    this.onNumericTap,
  });

  bool get _isNumeric => item.habit.targetValue != null;
  bool get _isDone => item.log?.isDone ?? false;
  double get _progress {
    if (!_isNumeric) return _isDone ? 1.0 : 0.0;
    final val = item.log?.value ?? 0;
    final target = item.habit.targetValue ?? 1;
    return (val / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.parseHex(item.habit.colorHex);
    final isDone = _isDone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? color.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? color.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isNumeric ? onNumericTap : onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _buildIcon(color, isDone),
              const SizedBox(width: 14),
              Expanded(child: _buildContent(theme, isDone)),
              _buildTrailing(color, isDone, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color, bool isDone) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDone ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        HabitIcons.fromCode(item.habit.iconCode),
        color: color,
        size: 22,
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.habit.name,
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_isNumeric) ...[
          const SizedBox(height: 6),
          _buildProgressBar(theme),
        ] else if (item.habit.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.habit.description,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final color = AppTheme.parseHex(item.habit.colorHex);
    final val = item.log?.value ?? 0;
    final target = item.habit.targetValue ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)} / ${target.toStringAsFixed(target % 1 == 0 ? 0 : 1)} ${item.habit.unit ?? ''}',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildTrailing(Color color, bool isDone, ThemeData theme) {
    if (_isNumeric) {
      return Icon(Icons.chevron_right, color: theme.colorScheme.outline);
    }
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDone ? color : Colors.transparent,
          border: Border.all(
            color: isDone ? color : theme.colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}
