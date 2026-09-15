import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/habits/screens/add_habit_screen.dart';
import 'features/habits/screens/manage_habits_screen.dart';
import 'features/habits/screens/manage_categories_screen.dart';
import 'shared/widgets/bottom_nav.dart';
import 'core/database/app_database.dart';

final _router = GoRouter(
  routes: [
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
  ],
);

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Habit Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
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
