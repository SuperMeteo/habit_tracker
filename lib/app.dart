import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_config.dart';
import 'core/sync/sync_service.dart';
import 'data/repositories/auth_repository.dart';
import 'features/admin/screens/admin_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/habits/screens/add_habit_screen.dart';
import 'features/habits/screens/manage_habits_screen.dart';
import 'shared/widgets/bottom_nav.dart';
import 'core/database/app_database.dart';

GoRouter _buildRouter(WidgetRef ref) {
  final user = ref.watch(appUserProvider);
  final onlineMode = SupabaseConfig.isConfigured;

  return GoRouter(
    // ถ้า online mode + ยังไม่ login → redirect ไป /login
    // ถ้า offline mode → ไปหน้าหลักได้เลย
    redirect: (context, state) {
      if (!onlineMode) return null;               // offline: ผ่านทุก route
      final loggedIn = user != null;
      final goingToLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/habits/add', builder: (_, __) => const AddHabitScreen()),
      GoRoute(
        path: '/habits/edit',
        builder: (context, state) =>
            AddHabitScreen(existingHabit: state.extra as Habit),
      ),
      GoRoute(path: '/habits/manage', builder: (_, __) => const ManageHabitsScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    ],
  );
}

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = _buildRouter(ref);

    // เมื่อ login สำเร็จ → sync ข้อมูล local ⇄ cloud อัตโนมัติ
    ref.listen(appUserProvider, (prev, next) {
      if (prev == null && next != null) {
        ref.read(syncServiceProvider.notifier).sync();
      }
    });

    return MaterialApp.router(
      title: 'Habit Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
