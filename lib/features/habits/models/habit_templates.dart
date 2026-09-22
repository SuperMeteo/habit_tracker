import 'package:flutter/material.dart';

class HabitTemplate {
  final String name;
  final String categoryKey;
  final bool isNumeric;
  final double? targetValue;
  final String? unit;
  final IconData icon;

  int get iconCode => icon.codePoint;
  final String colorHex;
  final String description;

  const HabitTemplate({
    required this.name,
    required this.categoryKey,
    required this.icon,
    required this.colorHex,
    this.isNumeric = false,
    this.targetValue,
    this.unit,
    this.description = '',
  });
}

class HabitTemplateCategory {
  final String key;
  final String label;
  final String emoji;
  final Color color;
  final List<HabitTemplate> templates;
  const HabitTemplateCategory({
    required this.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.templates,
  });
}

const kBodyId = '11111111-1111-4111-8111-111111111101';
const kFoodId = '11111111-1111-4111-8111-111111111106';
const kSleepId = '11111111-1111-4111-8111-111111111107';
const kMindId = '11111111-1111-4111-8111-111111111108';

class HabitTemplates {
  static const List<HabitTemplateCategory> categories = [
    HabitTemplateCategory(
      key: kBodyId,
      label: 'ร่างกาย',
      emoji: '💪',
      color: Color(0xFFEF4444),
      templates: [
        HabitTemplate(
          name: 'วิ่ง',
          categoryKey: kBodyId,
          isNumeric: true,
          targetValue: 5,
          unit: 'km',
          icon: Icons.directions_run,
          colorHex: '#EF4444',
          description: 'วิ่งระยะทางตามเป้า',
        ),
        HabitTemplate(
          name: 'บอดี้เวท',
          categoryKey: kBodyId,
          isNumeric: true,
          targetValue: 20,
          unit: 'นาที',
          icon: Icons.fitness_center,
          colorHex: '#EF4444',
          description: 'วิดพื้น สควอท แพลงก์',
        ),
        HabitTemplate(
          name: 'เวทเทรนนิ่ง',
          categoryKey: kBodyId,
          isNumeric: true,
          targetValue: 45,
          unit: 'นาที',
          icon: Icons.fitness_center,
          colorHex: '#DC2626',
          description: 'ยกน้ำหนักตามโปรแกรม',
        ),
        HabitTemplate(
          name: 'ปั่นจักรยาน',
          categoryKey: kBodyId,
          isNumeric: true,
          targetValue: 20,
          unit: 'km',
          icon: Icons.directions_bike,
          colorHex: '#F97316',
          description: 'ปั่นจักรยานออกกำลังกาย',
        ),
        HabitTemplate(
          name: 'เดิน',
          categoryKey: kBodyId,
          isNumeric: true,
          targetValue: 10000,
          unit: 'ก้าว',
          icon: Icons.hiking,
          colorHex: '#EF4444',
          description: 'เดินให้ครบตามเป้า',
        ),
      ],
    ),
    HabitTemplateCategory(
      key: kFoodId,
      label: 'การกิน',
      emoji: '🍽️',
      color: Color(0xFFF59E0B),
      templates: [
        HabitTemplate(
          name: 'ไม่กินของหวาน',
          categoryKey: kFoodId,
          icon: Icons.no_food,
          colorHex: '#F59E0B',
          description: 'งดน้ำตาลทั้งวัน',
        ),
        HabitTemplate(
          name: 'กินโปรตีนให้ถึง',
          categoryKey: kFoodId,
          isNumeric: true,
          targetValue: 100,
          unit: 'กรัม',
          icon: Icons.restaurant,
          colorHex: '#F59E0B',
          description: 'นับโปรตีนที่กินทั้งวัน',
        ),
        HabitTemplate(
          name: 'ดื่มน้ำ',
          categoryKey: kFoodId,
          isNumeric: true,
          targetValue: 8,
          unit: 'แก้ว',
          icon: Icons.water_drop,
          colorHex: '#3B82F6',
          description: 'ดื่มน้ำให้ครบตามเป้า',
        ),
        HabitTemplate(
          name: 'กินผักผลไม้',
          categoryKey: kFoodId,
          isNumeric: true,
          targetValue: 5,
          unit: 'ส่วน',
          icon: Icons.eco,
          colorHex: '#10B981',
          description: 'ผักหรือผลไม้ให้ครบส่วน',
        ),
      ],
    ),
    HabitTemplateCategory(
      key: kSleepId,
      label: 'การนอน',
      emoji: '😴',
      color: Color(0xFF6366F1),
      templates: [
        HabitTemplate(
          name: 'นอนให้ครบ',
          categoryKey: kSleepId,
          isNumeric: true,
          targetValue: 8,
          unit: 'ชั่วโมง',
          icon: Icons.bedtime,
          colorHex: '#6366F1',
          description: 'กรอกจำนวนชั่วโมงที่นอนได้',
        ),
        HabitTemplate(
          name: 'เข้านอนก่อนเที่ยงคืน',
          categoryKey: kSleepId,
          icon: Icons.timer,
          colorHex: '#8B5CF6',
          description: 'ขึ้นเตียงก่อน 00:00',
        ),
        HabitTemplate(
          name: 'ไม่เล่นมือถือก่อนนอน',
          categoryKey: kSleepId,
          isNumeric: true,
          targetValue: 30,
          unit: 'นาที',
          icon: Icons.spa,
          colorHex: '#6366F1',
          description: 'วางมือถือก่อนนอนกี่นาที',
        ),
      ],
    ),
    HabitTemplateCategory(
      key: kMindId,
      label: 'จิตใจ',
      emoji: '🧘',
      color: Color(0xFF10B981),
      templates: [
        HabitTemplate(
          name: 'นั่งสมาธิ',
          categoryKey: kMindId,
          isNumeric: true,
          targetValue: 10,
          unit: 'นาที',
          icon: Icons.self_improvement,
          colorHex: '#10B981',
          description: 'นั่งสมาธิให้ครบตามเป้า',
        ),
        HabitTemplate(
          name: 'ขอบคุณสิ่งดี ๆ วันนี้',
          categoryKey: kMindId,
          icon: Icons.favorite,
          colorHex: '#EC4899',
          description: 'นึกถึงเรื่องดีของวันนี้',
        ),
        HabitTemplate(
          name: 'พักใจจากงาน',
          categoryKey: kMindId,
          isNumeric: true,
          targetValue: 15,
          unit: 'นาที',
          icon: Icons.psychology,
          colorHex: '#14B8A6',
          description: 'เวลาที่ได้พักจริง ๆ',
        ),
      ],
    ),
  ];
}
