import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../habits/providers/habits_provider.dart';
import '../models/habit_icons.dart';
import '../models/habit_templates.dart';
import 'template_picker_screen.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  final Habit? existingHabit;
  const AddHabitScreen({super.key, this.existingHabit});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _targetValueCtrl;

  String _categoryId = '';
  String _frequencyType = 'daily';
  List<int> _targetDays = [1, 2, 3, 4, 5, 6, 7];
  bool _isNumeric = false;
  String _colorHex = '#6366F1';
  int _iconCode = HabitIcons.defaultCode;
  TimeOfDay? _reminderTime;

  static const _colorOptions = [
    '#6366F1', '#EF4444', '#8B5CF6', '#10B981',
    '#F59E0B', '#3B82F6', '#EC4899', '#14B8A6',
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.existingHabit;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _descCtrl = TextEditingController(text: h?.description ?? '');
    _unitCtrl = TextEditingController(text: h?.unit ?? '');
    _targetValueCtrl =
        TextEditingController(text: h?.targetValue?.toString() ?? '');
    if (h != null) {
      _categoryId = h.categoryId;
      _frequencyType = h.frequencyType;
      _targetDays = List<int>.from(jsonDecode(h.targetDays));
      _isNumeric = h.targetValue != null;
      _colorHex = h.colorHex;
      _iconCode = h.iconCode;
      if (h.reminderTime != null) {
        final parts = h.reminderTime!.split(':');
        _reminderTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    _targetValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTemplate(BuildContext context) async {
    final template = await Navigator.push<HabitTemplate>(
      context,
      MaterialPageRoute(builder: (_) => const TemplatePickerScreen()),
    );
    if (template == null) return;
    setState(() {
      _nameCtrl.text = template.name;
      _descCtrl.text = template.description;
      _isNumeric = template.isNumeric;
      _colorHex = template.colorHex;
      _iconCode = template.iconCode;
      if (template.isNumeric) {
        _targetValueCtrl.text =
            template.targetValue?.toStringAsFixed(0) ?? '';
        _unitCtrl.text = template.unit ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingHabit != null;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'แก้ไข Habit' : 'เพิ่ม Habit'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.existingHabit == null) ...[
              OutlinedButton.icon(
                onPressed: () => _pickTemplate(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('เลือกจาก Template'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('หรือกรอกเอง',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
            ],
            _buildIconColorRow(context),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อ Habit *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'คำอธิบาย (ไม่บังคับ)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            _sectionLabel('หมวดหมู่'),
            categoriesAsync.when(
              data: (cats) => _buildCategoryChips(cats),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('ความถี่'),
            _buildFrequencySelector(),
            if (_frequencyType == 'specific_days') ...[
              const SizedBox(height: 12),
              _buildDaySelector(),
            ],
            const SizedBox(height: 20),
            _buildNumericToggle(),
            if (_isNumeric) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetValueCtrl,
                      decoration:
                          const InputDecoration(labelText: 'เป้าหมาย'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (_isNumeric &&
                            (v == null || double.tryParse(v) == null)) {
                          return 'กรุณากรอกตัวเลข';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration:
                          const InputDecoration(labelText: 'หน่วย (เช่น แก้ว)'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('การแจ้งเตือน'),
            _buildReminderTile(context),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Text(isEdit ? 'บันทึกการเปลี่ยนแปลง' : 'เพิ่ม Habit'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIconColorRow(BuildContext context) {
    final color = AppTheme.parseHex(_colorHex);
    return Row(
      children: [
        GestureDetector(
          onTap: () => _pickIcon(context),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(HabitIcons.fromCode(_iconCode), color: color, size: 30),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((hex) {
              final c = AppTheme.parseHex(hex);
              final selected = hex == _colorHex;
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
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
        ),
      ],
    );
  }

  void _pickIcon(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: HabitIcons.available.length,
        itemBuilder: (_, i) {
          final icon = HabitIcons.available[i];
          final selected = icon.codePoint == _iconCode;
          return GestureDetector(
            onTap: () {
              setState(() => _iconCode = icon.codePoint);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.parseHex(_colorHex).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected
                      ? AppTheme.parseHex(_colorHex)
                      : Theme.of(context).colorScheme.onSurface),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> cats) {
    // default: เลือกหมวดแรกถ้ายังไม่ได้เลือก (id เป็น UUID จึงตั้งค่าเริ่มไม่ได้)
    if (_categoryId.isEmpty && cats.isNotEmpty) _categoryId = cats.first.id;
    return Wrap(
      spacing: 8,
      children: cats.map((cat) {
        final selected = cat.id == _categoryId;
        final color = AppTheme.parseHex(cat.colorHex);
        return FilterChip(
          label: Text(cat.name),
          selected: selected,
          selectedColor: color.withValues(alpha: 0.2),
          checkmarkColor: color,
          onSelected: (_) => setState(() => _categoryId = cat.id),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'daily', label: Text('ทุกวัน')),
        ButtonSegment(value: 'specific_days', label: Text('เลือกวัน')),
        ButtonSegment(value: 'times_per_week', label: Text('ต่อสัปดาห์')),
      ],
      selected: {_frequencyType},
      onSelectionChanged: (s) => setState(() => _frequencyType = s.first),
    );
  }

  Widget _buildDaySelector() {
    const dayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = _targetDays.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            selected ? _targetDays.remove(day) : _targetDays.add(day);
          }),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.parseHex(_colorHex)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              dayLabels[i],
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumericToggle() {
    return SwitchListTile(
      title: const Text('ติดตามค่าตัวเลข'),
      subtitle: const Text('เช่น ดื่มน้ำ 8 แก้ว, วิ่ง 5 กม.'),
      value: _isNumeric,
      onChanged: (v) => setState(() => _isNumeric = v),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildReminderTile(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_outlined),
      title: Text(_reminderTime == null
          ? 'ไม่มีการแจ้งเตือน'
          : 'แจ้งเตือนเวลา ${_reminderTime!.format(context)}'),
      trailing: _reminderTime != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _reminderTime = null),
            )
          : null,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _reminderTime ?? TimeOfDay.now(),
        );
        if (picked != null) setState(() => _reminderTime = picked);
      },
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 วัน')));
      return;
    }
    final actions = ref.read(habitActionsProvider);
    final companion = HabitsCompanion(
      id: widget.existingHabit != null
          ? Value(widget.existingHabit!.id)
          : const Value.absent(),
      categoryId: Value(_categoryId),
      name: Value(_nameCtrl.text.trim()),
      description: Value(_descCtrl.text.trim()),
      frequencyType: Value(_frequencyType),
      targetDays: Value(jsonEncode(_targetDays)),
      targetValue: Value(_isNumeric ? double.tryParse(_targetValueCtrl.text) : null),
      unit: Value(_isNumeric ? _unitCtrl.text.trim() : null),
      reminderTime: Value(_reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null),
      colorHex: Value(_colorHex),
      iconCode: Value(_iconCode),
    );
    if (widget.existingHabit != null) {
      await actions.updateHabit(companion);
    } else {
      await actions.addHabit(companion);
    }
    if (mounted) context.pop();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบ Habit'),
        content: const Text('แน่ใจหรือไม่? ข้อมูลทั้งหมดจะถูกลบถาวร'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref
          .read(habitActionsProvider)
          .deleteHabit(widget.existingHabit!.id);
      if (mounted) context.pop();
    }
  }
}
