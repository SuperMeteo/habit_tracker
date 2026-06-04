import 'package:flutter/material.dart';

class HabitTemplate {
  final String name;
  final String categoryKey; // 'sport' | 'life' | 'education' | 'custom'
  final bool isNumeric;
  final double? targetValue;
  final String? unit;
  final int iconCode;
  final String colorHex;
  final String description;

  const HabitTemplate({
    required this.name,
    required this.categoryKey,
    required this.iconCode,
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

class HabitTemplates {
  static const List<HabitTemplateCategory> categories = [
    HabitTemplateCategory(
      key: 'sport',
      label: 'กีฬา',
      emoji: '🏃',
      color: Color(0xFFEF4444),
      templates: [
        HabitTemplate(
          name: 'วิ่ง',
          categoryKey: 'sport',
          isNumeric: true,
          targetValue: 5,
          unit: 'km',
          iconCode: 0xe566,
          colorHex: '#EF4444',
          description: 'วิ่งระยะทางทุกวัน',
        ),
        HabitTemplate(
          name: 'ปั่นจักรยาน',
          categoryKey: 'sport',
          isNumeric: true,
          targetValue: 20,
          unit: 'km',
          iconCode: 0xe1a5,
          colorHex: '#EF4444',
          description: 'ปั่นจักรยานออกกำลังกาย',
        ),
        HabitTemplate(
          name: 'ว่ายน้ำ',
          categoryKey: 'sport',
          isNumeric: true,
          targetValue: 500,
          unit: 'เมตร',
          iconCode: 0xef6d,
          colorHex: '#3B82F6',
          description: 'ว่ายน้ำเพื่อสุขภาพ',
        ),
        HabitTemplate(
          name: 'ออกกำลังกาย',
          categoryKey: 'sport',
          isNumeric: true,
          targetValue: 45,
          unit: 'นาที',
          iconCode: 0xe3a3,
          colorHex: '#EF4444',
          description: 'ออกกำลังกายทั่วไป',
        ),
        HabitTemplate(
          name: 'เดิน',
          categoryKey: 'sport',
          isNumeric: true,
          targetValue: 10000,
          unit: 'ก้าว',
          iconCode: 0xe566,
          colorHex: '#10B981',
          description: 'เดิน 10,000 ก้าวต่อวัน',
        ),
        HabitTemplate(
          name: 'ยิม',
          categoryKey: 'sport',
          isNumeric: false,
          iconCode: 0xe3a3,
          colorHex: '#EF4444',
          description: 'ไปยิมตามกำหนด',
        ),
      ],
    ),
    HabitTemplateCategory(
      key: 'life',
      label: 'ชีวิต',
      emoji: '🌱',
      color: Color(0xFF10B981),
      templates: [
        HabitTemplate(
          name: 'ดื่มน้ำ',
          categoryKey: 'life',
          isNumeric: true,
          targetValue: 8,
          unit: 'แก้ว',
          iconCode: 0xe798,
          colorHex: '#3B82F6',
          description: 'ดื่มน้ำ 8 แก้วต่อวัน',
        ),
        HabitTemplate(
          name: 'นอนหลับ',
          categoryKey: 'life',
          isNumeric: true,
          targetValue: 8,
          unit: 'ชั่วโมง',
          iconCode: 0xe3e9,
          colorHex: '#8B5CF6',
          description: 'นอนหลับพักผ่อนให้เพียงพอ',
        ),
        HabitTemplate(
          name: 'ทำสมาธิ',
          categoryKey: 'life',
          isNumeric: true,
          targetValue: 10,
          unit: 'นาที',
          iconCode: 0xe7f7,
          colorHex: '#10B981',
          description: 'นั่งสมาธิเพื่อความสงบ',
        ),
        HabitTemplate(
          name: 'น้ำหนัก',
          categoryKey: 'life',
          isNumeric: true,
          targetValue: 70,
          unit: 'kg',
          iconCode: 0xe3a3,
          colorHex: '#F59E0B',
          description: 'บันทึกน้ำหนักประจำวัน',
        ),
        HabitTemplate(
          name: 'กินผักผลไม้',
          categoryKey: 'life',
          isNumeric: true,
          targetValue: 5,
          unit: 'ส่วน',
          iconCode: 0xf053,
          colorHex: '#10B981',
          description: 'กินผักผลไม้ 5 ส่วนต่อวัน',
        ),
        HabitTemplate(
          name: 'ไม่กินขนมหวาน',
          categoryKey: 'life',
          isNumeric: false,
          iconCode: 0xe6b5,
          colorHex: '#EC4899',
          description: 'งดขนมหวานและของทอด',
        ),
      ],
    ),
    HabitTemplateCategory(
      key: 'education',
      label: 'การศึกษา',
      emoji: '📚',
      color: Color(0xFFF59E0B),
      templates: [
        HabitTemplate(
          name: 'อ่านหนังสือ',
          categoryKey: 'education',
          isNumeric: true,
          targetValue: 30,
          unit: 'หน้า',
          iconCode: 0xe865,
          colorHex: '#F59E0B',
          description: 'อ่านหนังสือเพิ่มความรู้',
        ),
        HabitTemplate(
          name: 'เรียน online',
          categoryKey: 'education',
          isNumeric: true,
          targetValue: 60,
          unit: 'นาที',
          iconCode: 0xe04b,
          colorHex: '#6366F1',
          description: 'เรียนคอร์ส online ทุกวัน',
        ),
        HabitTemplate(
          name: 'ฝึกภาษา',
          categoryKey: 'education',
          isNumeric: true,
          targetValue: 20,
          unit: 'นาที',
          iconCode: 0xe894,
          colorHex: '#3B82F6',
          description: 'ฝึกภาษาต่างประเทศ',
        ),
        HabitTemplate(
          name: 'เขียนโค้ด',
          categoryKey: 'education',
          isNumeric: true,
          targetValue: 2,
          unit: 'ชั่วโมง',
          iconCode: 0xe86f,
          colorHex: '#8B5CF6',
          description: 'เขียนโค้ดฝึกทักษะ',
        ),
        HabitTemplate(
          name: 'เขียน Journal',
          categoryKey: 'education',
          isNumeric: false,
          iconCode: 0xe262,
          colorHex: '#F59E0B',
          description: 'บันทึกประจำวัน',
        ),
        HabitTemplate(
          name: 'ฟัง Podcast',
          categoryKey: 'education',
          isNumeric: true,
          targetValue: 30,
          unit: 'นาที',
          iconCode: 0xe05b,
          colorHex: '#EC4899',
          description: 'ฟัง Podcast เพิ่มความรู้',
        ),
      ],
    ),
  ];
}
