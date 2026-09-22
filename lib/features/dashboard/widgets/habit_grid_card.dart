import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../habits/providers/habits_provider.dart';
import '../../habits/models/habit_icons.dart';

class HabitGridCard extends StatelessWidget {
  final HabitWithLog item;
  final VoidCallback onToggle;
  final VoidCallback? onNumericTap;
  final VoidCallback? onMenu;

  const HabitGridCard({
    super.key,
    required this.item,
    required this.onToggle,
    this.onNumericTap,
    this.onMenu,
  });

  String get _type => habitInputType(item.habit);
  bool get _isNumeric => _type == 'number';
  bool get _isScale => _type == 'scale3';
  bool get _isWeekly => item.habit.frequencyType == 'times_per_week';
  bool get _isDone => item.log?.isDone ?? false;

  int? get _level {
    final v = item.log?.value;
    if (v == null || !_isDone) return null;
    return v.round().clamp(1, 3);
  }

  double get _progress {
    if (_isScale) {
      final l = _level;
      return l == null ? 0 : l / 3;
    }
    if (_isNumeric) {
      final val = item.log?.value ?? 0;
      final target = item.habit.targetValue ?? 1;
      return (val / target).clamp(0.0, 1.0);
    }
    if (_isWeekly) {
      final goal = item.habit.timesPerWeek;
      if (goal <= 0) return _isDone ? 1 : 0;
      return (item.weekDoneCount / goal).clamp(0.0, 1.0);
    }
    return _isDone ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.parseHex(item.habit.colorHex);

    return Semantics(
      button: true,
      label: item.habit.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _isDone
              ? color.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: _isDone ? color.withValues(alpha: 0.45) : AppTheme.hairline(theme),
          ),
          boxShadow: AppTheme.softShadow(theme),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (_isNumeric || _isScale) ? onNumericTap : onToggle,
            onLongPress: onMenu,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _iconChip(color),
                      const Spacer(),
                      if (!_isNumeric && !_isScale) _checkButton(color, theme),
                    ],
                  ),
                  const Spacer(),
                  Center(child: _centrePiece(color, theme)),
                  const Spacer(),
                  Text(
                    item.habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _isDone ? color : theme.colorScheme.outline,
                      fontWeight: _isDone ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconChip(Color color) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: _isDone ? 0.28 : 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(HabitIcons.fromCode(item.habit.iconCode), color: color, size: 20),
      );

  Widget _checkButton(Color color, ThemeData theme) => GestureDetector(
        onTap: onToggle,
        onLongPress: onMenu,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _isDone ? color : Colors.transparent,
            border: Border.all(
              color: _isDone ? color : theme.colorScheme.outlineVariant,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      );

  Widget _centrePiece(Color color, ThemeData theme) {
    if (_isScale) {
      final l = _level;
      return ProgressRing(
        value: _progress,
        color: color,
        size: 74,
        stroke: 7,
        child: Text(
          l == null ? '?' : ['😕', '😐', '😄'][l - 1],
          style: TextStyle(fontSize: l == null ? 26 : 30, color: color),
        ),
      );
    }
    if (_isNumeric) {
      final val = item.log?.value ?? 0;
      return ProgressRing(
        value: _progress,
        color: color,
        size: 74,
        stroke: 7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmt(val),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1,
              ),
            ),
            if ((item.habit.unit ?? '').isNotEmpty)
              Text(
                item.habit.unit!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
          ],
        ),
      );
    }

    if (_isWeekly) {
      return ProgressRing(
        value: _progress,
        color: color,
        size: 74,
        stroke: 7,
        child: Text(
          '${item.weekDoneCount}/${item.habit.timesPerWeek}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: _isDone ? 0.22 : 0.10),
      ),
      child: Icon(
        _isDone ? Icons.check_rounded : HabitIcons.fromCode(item.habit.iconCode),
        color: color,
        size: _isDone ? 38 : 30,
      ),
    );
  }

  String _subtitle() {
    if (_isScale) {
      final l = _level;
      return l == null ? 'แตะเพื่อตอบ' : 'วันนี้: ${scaleLabels[l - 1]}';
    }
    if (_isNumeric) {
      final target = item.habit.targetValue ?? 1;
      return 'เป้าหมาย ${_fmt(target)} ${item.habit.unit ?? ''}'.trim();
    }
    if (_isWeekly) {
      final goal = item.habit.timesPerWeek;
      return item.weekDoneCount >= goal
          ? 'ครบเป้าสัปดาห์นี้แล้ว'
          : 'สัปดาห์นี้ ${item.weekDoneCount} จาก $goal ครั้ง';
    }
    if (_isDone) return 'ทำแล้ววันนี้';
    return item.habit.description.isNotEmpty
        ? item.habit.description
        : 'ยังไม่ได้ทำ';
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
