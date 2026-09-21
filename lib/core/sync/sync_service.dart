import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote/habit_remote_ds.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/habits/providers/habits_provider.dart';
import '../database/app_database.dart';
import '../supabase/supabase_client_provider.dart';

/// สถานะการ sync สำหรับโชว์บน UI
enum SyncStatus { idle, syncing, success, failed }

class SyncState {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSyncAt;
  const SyncState({this.status = SyncStatus.idle, this.message, this.lastSyncAt});

  SyncState copyWith({SyncStatus? status, String? message, DateTime? lastSyncAt}) =>
      SyncState(
        status: status ?? this.status,
        message: message,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );
}

final syncServiceProvider =
    StateNotifierProvider<SyncService, SyncState>((ref) => SyncService(ref));

class SyncService extends StateNotifier<SyncState> {
  final Ref _ref;
  static const _lastSyncKey = 'last_sync_at';
  bool _running = false;
  bool _needsAnotherRound = false;
  Timer? _debounce;

  SyncService(this._ref) : super(const SyncState());

  /// ตั้งเวลาซิงก์แบบหน่วง — ติ๊กรัว ๆ หลายอันจะถูกรวบเป็นรอบเดียว
  /// เงียบเสมอ: ถ้าออฟไลน์หรือยังไม่ login จะไม่ทำอะไรและไม่ฟ้อง
  void scheduleSync({Duration delay = const Duration(seconds: 3)}) {
    if (_ref.read(supabaseClientProvider) == null) return;
    if (_ref.read(appUserProvider) == null) return;
    _debounce?.cancel();
    _debounce = Timer(delay, sync);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// sync 2 ทาง: push แถวที่ค้าง → pull ของใหม่จาก server
  /// ปลอดภัยที่จะเรียกซ้ำ (กันรันซ้อนด้วย [_running])
  Future<void> sync() async {
    // ติ๊กระหว่างรอบก่อนยังวิ่งอยู่ → จำไว้แล้วซิงก์อีกรอบให้ ไม่ทิ้งข้อมูลค้าง
    if (_running) {
      _needsAnotherRound = true;
      return;
    }

    final client = _ref.read(supabaseClientProvider);
    final user = _ref.read(appUserProvider);
    if (client == null || user == null) return; // offline / ยังไม่ login

    _running = true;
    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final db = _ref.read(databaseProvider);
      final remote = HabitRemoteDataSource(client);

      // ผูกข้อมูลที่สร้างตอนเป็น guest เข้ากับบัญชีนี้ก่อน
      await db.claimGuestData(user.id);

      await _push(db, remote, user.id);
      final since = await _lastSync();
      await _pull(db, remote, since);

      final now = DateTime.now();
      await _saveLastSync(now);
      state = SyncState(status: SyncStatus.success, lastSyncAt: now);
      await _ref.read(appUserProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(status: SyncStatus.failed, message: '$e');
    } finally {
      _running = false;
      if (_needsAnotherRound) {
        _needsAnotherRound = false;
        scheduleSync(delay: const Duration(seconds: 2));
      }
    }
  }

  // ─── Push ─────────────────────────────────────────────────────────────────

  Future<void> _push(
      AppDatabase db, HabitRemoteDataSource remote, String uid) async {
    final habits = await db.getPendingHabits();
    if (habits.isNotEmpty) {
      await remote.pushHabits(habits.map((h) => _habitToRow(h, uid)).toList());
      await db.markHabitsSynced(habits.map((h) => h.id).toList());
    }

    final logs = await db.getPendingLogs();
    if (logs.isNotEmpty) {
      await remote.pushLogs(logs.map((l) => _logToRow(l, uid)).toList());
      await db.markLogsSynced(logs.map((l) => l.id).toList());
    }
  }

  Map<String, dynamic> _habitToRow(Habit h, String uid) => {
        'id': h.id,
        'user_id': uid,
        'name': h.name,
        'description': h.description,
        'category_id': h.categoryId,
        'frequency_type': h.frequencyType,
        'target_days': h.targetDays,
        'target_value': h.targetValue,
        'unit': h.unit,
        'reminder_time': h.reminderTime,
        'color_hex': h.colorHex,
        'icon_code': h.iconCode,
        'is_active': h.isActive,
        'updated_at': h.updatedAt.toUtc().toIso8601String(),
        'deleted_at': h.deletedAt?.toUtc().toIso8601String(),
      };

  // ไม่ส่ง points_awarded — server คำนวณเอง (anti-cheat)
  Map<String, dynamic> _logToRow(HabitLog l, String uid) => {
        'id': l.id,
        'habit_id': l.habitId,
        'user_id': uid,
        'logged_date': _dateOnly(l.loggedDate),
        'is_done': l.isDone,
        'value': l.value,
        'note': l.note,
        'updated_at': l.updatedAt.toUtc().toIso8601String(),
        'deleted_at': l.deletedAt?.toUtc().toIso8601String(),
      };

  // ─── Pull ─────────────────────────────────────────────────────────────────

  Future<void> _pull(
      AppDatabase db, HabitRemoteDataSource remote, DateTime? since) async {
    for (final row in await remote.pullHabits(since)) {
      final incoming = _parseDate(row['updated_at']);
      final local = await db.findHabitById(row['id'] as String);
      // last-write-wins: ข้ามถ้าของ local ใหม่กว่า
      if (local != null && incoming != null && local.updatedAt.isAfter(incoming)) {
        continue;
      }
      await db.applyRemoteHabit(HabitsCompanion(
        id: Value(row['id'] as String),
        categoryId: Value(
            await db.resolveCategoryId(row['category_id'] as String?)),
        name: Value(row['name'] as String? ?? ''),
        description: Value(row['description'] as String? ?? ''),
        frequencyType: Value(row['frequency_type'] as String? ?? 'daily'),
        targetDays: Value(row['target_days'] as String? ?? '[1,2,3,4,5,6,7]'),
        targetValue: Value((row['target_value'] as num?)?.toDouble()),
        unit: Value(row['unit'] as String?),
        reminderTime: Value(row['reminder_time'] as String?),
        colorHex: Value(row['color_hex'] as String? ?? '#6366F1'),
        iconCode: Value((row['icon_code'] as num?)?.toInt() ?? 0xe532),
        isActive: Value(row['is_active'] as bool? ?? true),
        userId: Value(row['user_id'] as String?),
        updatedAt: Value(incoming ?? DateTime.now()),
        deletedAt: Value(_parseDate(row['deleted_at'])),
        syncStatus: const Value('synced'),
      ));
    }

    for (final row in await remote.pullLogs(since)) {
      final incoming = _parseDate(row['updated_at']);
      final local = await db.findLogById(row['id'] as String);
      if (local != null && incoming != null && local.updatedAt.isAfter(incoming)) {
        continue;
      }
      final logged = _parseDate(row['logged_date']);
      if (logged == null) continue;
      await db.applyRemoteLog(HabitLogsCompanion(
        id: Value(row['id'] as String),
        habitId: Value(row['habit_id'] as String),
        loggedDate: Value(DateTime(logged.year, logged.month, logged.day)),
        isDone: Value(row['is_done'] as bool? ?? false),
        value: Value((row['value'] as num?)?.toDouble()),
        note: Value(row['note'] as String?),
        // แต้มที่ server คำนวณแล้ว — เชื่อค่าจาก server เท่านั้น
        pointsAwarded: Value((row['points_awarded'] as num?)?.toInt() ?? 0),
        userId: Value(row['user_id'] as String?),
        updatedAt: Value(incoming ?? DateTime.now()),
        deletedAt: Value(_parseDate(row['deleted_at'])),
        syncStatus: const Value('synced'),
      ));
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _lastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_lastSyncKey);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> _saveLastSync(DateTime t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, t.toIso8601String());
  }
}

// เผื่อใช้ตรวจ targetDays ที่เก็บเป็น JSON string
List<int> parseTargetDays(String json) {
  try {
    return List<int>.from(jsonDecode(json) as List);
  } catch (_) {
    return const [1, 2, 3, 4, 5, 6, 7];
  }
}
