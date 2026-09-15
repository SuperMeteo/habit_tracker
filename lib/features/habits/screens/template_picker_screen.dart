import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/habit_icons.dart';
import '../models/habit_templates.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HabitTemplates.categories.length + 1, // +1 for custom
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือก Template'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            ...HabitTemplates.categories.map(
              (c) => Tab(text: '${c.emoji} ${c.label}'),
            ),
            const Tab(text: '✏️ กำหนดเอง'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ...HabitTemplates.categories.map(
            (cat) => _TemplateGrid(category: cat),
          ),
          _CustomTemplateForm(),
        ],
      ),
    );
  }
}

class _TemplateGrid extends StatelessWidget {
  final HabitTemplateCategory category;
  const _TemplateGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: category.templates.length,
      itemBuilder: (_, i) => _TemplateCard(
        template: category.templates[i],
        onTap: () => Navigator.pop(context, category.templates[i]),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final HabitTemplate template;
  final VoidCallback onTap;
  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.parseHex(template.colorHex);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                HabitIcons.fromCode(template.iconCode),
                color: color,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              template.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            if (template.isNumeric && template.targetValue != null)
              Text(
                'เป้า: ${template.targetValue!.toStringAsFixed(template.targetValue! % 1 == 0 ? 0 : 1)} ${template.unit ?? ''}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              )
            else
              Text(
                'ทำ / ไม่ทำ',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomTemplateForm extends StatefulWidget {
  @override
  State<_CustomTemplateForm> createState() => _CustomTemplateFormState();
}

class _CustomTemplateFormState extends State<_CustomTemplateForm> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  bool _isNumeric = false;
  String _colorHex = '#6366F1';

  static const _colors = [
    '#6366F1', '#EF4444', '#8B5CF6', '#10B981',
    '#F59E0B', '#3B82F6', '#EC4899', '#14B8A6',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('สร้าง Habit ของตัวเอง',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'ชื่อ Habit *',
            hintText: 'เช่น โยคะ, ฝึกกีตาร์',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _colors.map((hex) {
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
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('ติดตามค่าตัวเลข'),
          subtitle: const Text('เช่น km, นาที, แก้ว'),
          value: _isNumeric,
          onChanged: (v) => setState(() => _isNumeric = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isNumeric) ...[
          Row(children: [
            Expanded(
              child: TextField(
                controller: _targetCtrl,
                decoration: const InputDecoration(labelText: 'เป้าหมาย'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                decoration:
                    const InputDecoration(labelText: 'หน่วย (เช่น km, นาที)'),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกชื่อ Habit')));
              return;
            }
            final template = HabitTemplate(
              name: _nameCtrl.text.trim(),
              categoryKey: 'custom',
              isNumeric: _isNumeric,
              targetValue: _isNumeric
                  ? double.tryParse(_targetCtrl.text)
                  : null,
              unit: _isNumeric ? _unitCtrl.text.trim() : null,
              icon: Icons.star,
              colorHex: _colorHex,
            );
            Navigator.pop(context, template);
          },
          child: const Text('ใช้ Template นี้'),
        ),
      ],
    );
  }
}
