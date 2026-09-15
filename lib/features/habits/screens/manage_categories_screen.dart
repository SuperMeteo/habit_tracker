import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/habits_provider.dart';

const int categoryNameMaxLength = 50;

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final counts =
        ref.watch(categoryHabitCountsProvider).valueOrNull ?? const <int, int>{};

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการหมวดหมู่')),
      body: categoriesAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'ยังไม่มีหมวดหมู่',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat = cats[i];
              final color = AppTheme.parseHex(cat.colorHex);
              final count = counts[cat.id] ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(Icons.label, color: color),
                ),
                title: Text(cat.name),
                subtitle: Text('$count habit'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'ลบ',
                  onPressed: () => _delete(context, ref, cat, count),
                ),
                onTap: () => _edit(context, ref, cat),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
    if (result == null) return;
    await ref
        .read(databaseProvider)
        .insertCategory(result.name, result.colorHex);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category cat) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(existing: cat),
    );
    if (result == null) return;
    await ref
        .read(databaseProvider)
        .updateCategory(cat.id, result.name, result.colorHex);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Category cat, int count) async {
    final messenger = ScaffoldMessenger.of(context);
    if (count > 0) {
      messenger.showSnackBar(SnackBar(
          content: Text('ลบไม่ได้ มี $count habit ใช้หมวดนี้อยู่')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบหมวดหมู่'),
        content: Text('ลบ "${cat.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await ref.read(databaseProvider).deleteCategory(cat.id);
    switch (result) {
      case CategoryDeleteResult.deleted:
        break;
      case CategoryDeleteResult.inUse:
        messenger.showSnackBar(
            const SnackBar(content: Text('ลบไม่ได้ มี habit ใช้หมวดนี้อยู่')));
      case CategoryDeleteResult.lastOne:
        messenger.showSnackBar(
            const SnackBar(content: Text('ต้องเหลืออย่างน้อย 1 หมวดหมู่')));
    }
  }
}

class CategoryFormResult {
  final String name;
  final String colorHex;
  const CategoryFormResult(this.name, this.colorHex);
}

class CategoryFormDialog extends StatefulWidget {
  final Category? existing;
  const CategoryFormDialog({super.key, this.existing});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  static const _colorOptions = [
    '#6366F1', '#EF4444', '#8B5CF6', '#10B981',
    '#F59E0B', '#3B82F6', '#EC4899', '#14B8A6',
  ];

  late final TextEditingController _nameCtrl;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _colorHex = widget.existing?.colorHex ?? _colorOptions.first;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? get _error {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return null;
    if (name.length > categoryNameMaxLength) {
      return 'ยาวเกิน $categoryNameMaxLength ตัวอักษร (ตอนนี้ ${name.length})';
    }
    return null;
  }

  bool get _canSave {
    final name = _nameCtrl.text.trim();
    return name.isNotEmpty && name.length <= categoryNameMaxLength;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'ชื่อหมวดหมู่',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((hex) {
              final selected = hex == _colorHex;
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.parseHex(hex),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _canSave
              ? () => Navigator.pop(context,
                  CategoryFormResult(_nameCtrl.text.trim(), _colorHex))
              : null,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
