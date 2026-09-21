import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/supabase/supabase_config.dart';
import 'features/habits/providers/habits_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HabitTrackerApp(),
    ),
  );
  unawaited(
      NotificationService.instance.syncAll(container.read(databaseProvider)));
}
