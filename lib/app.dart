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
import 'features/habits/screens/manage_categories_screen.dart';
import 'shared/widgets/bottom_nav.dart';
import 'core/database/app_database.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onlineMode = SupabaseConfig.isConfigured;

  return GoRouter(
    redirect: (context, state) {
      if (!onlineMode) return null;
      final loggedIn = ref.read(appUserProvider) != null;
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
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/habits/add',
        builder: (_, __) => const AddHabitScreen(),
      ),
      GoRoute(
        path: '/habits/edit',
        builder: (context, state) {
          final habit = state.extra as Habit;
          return AddHabitScreen(existingHabit: habit);
        },
      ),
      GoRoute(
        path: '/habits/manage',
        builder: (_, __) => const ManageHabitsScreen(),
      ),
      GoRoute(
        path: '/categories/manage',
        builder: (_, __) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminScreen(),
      ),
    ],
  );
});

class HabitTrackerApp extends ConsumerStatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  ConsumerState<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends ConsumerState<HabitTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(syncServiceProvider.notifier)
          .scheduleSync(delay: const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    ref.listen(appUserProvider, (prev, next) {
      router.refresh();
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
