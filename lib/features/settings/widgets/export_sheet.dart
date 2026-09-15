import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/data_exporter.dart';
import '../../habits/providers/habits_provider.dart';

enum ExportAction { csv, json, copyCsv }

void showExportSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<ExportAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('ไฟล์ CSV'),
            subtitle: const Text('เปิดใน Excel / Google Sheets'),
            onTap: () => Navigator.pop(sheetContext, ExportAction.csv),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('ไฟล์ JSON'),
            subtitle: const Text('สำรองข้อมูลทั้งหมด'),
            onTap: () => Navigator.pop(sheetContext, ExportAction.json),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('คัดลอก CSV'),
            onTap: () => Navigator.pop(sheetContext, ExportAction.copyCsv),
          ),
        ],
      ),
    ),
  ).then((action) {
    if (action != null && context.mounted) {
      _runExport(context, ref.read(databaseProvider), action);
    }
  });
}

Future<void> _runExport(
    BuildContext context, AppDatabase db, ExportAction action) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final categories = await db.getAllCategories();
    final habits = await db.getAllHabits();
    final logs = await db.getAllLogs();
    final now = DateTime.now();

    if (action == ExportAction.json) {
      final content = DataExporter.toJson(
          categories: categories, habits: habits, logs: logs, exportedAt: now);
      await _shareFile(content, DataExporter.fileName(now, 'json'),
          'application/json');
      return;
    }

    final csv = DataExporter.toCsv(
        categories: categories, habits: habits, logs: logs);
    if (action == ExportAction.copyCsv) {
      await Clipboard.setData(ClipboardData(text: csv.substring(1)));
      messenger.showSnackBar(
          SnackBar(content: Text('คัดลอกแล้ว ${logs.length} รายการ')));
      return;
    }
    await _shareFile(csv, DataExporter.fileName(now, 'csv'), 'text/csv');
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('ส่งออกไม่สำเร็จ: $e')));
  }
}

Future<void> _shareFile(String content, String name, String mimeType) {
  return SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(utf8.encode(content), mimeType: mimeType, name: name),
    ],
    fileNameOverrides: [name],
    subject: name,
  ));
}
