import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/crops/presentation/crops_screen.dart';
import '../../features/smart_advisor/presentation/advisor_screen.dart';
import '../../features/field_logs/presentation/field_logs_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = auth.status == AuthStatus.authenticated;
      final isLoading = auth.status == AuthStatus.loading;
      final loc = state.matchedLocation;

      if (isLoading) return null;

      final publicRoutes = ['/splash', '/onboarding', '/login', '/register'];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));

      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic && loc != '/splash') return '/home/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',     builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login',      builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (c, s) => const RegisterScreen()),

      ShellRoute(
        builder: (c, s, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home/dashboard', builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/home/crops',     builder: (c, s) => const CropsScreen()),
          GoRoute(
            path: 'advisor',
            builder: (context, state) => const SmartAdvisorScreen(),
          ),
          GoRoute(path: '/home/logs',      builder: (c, s) => const FieldLogsScreen()),
          GoRoute(path: '/home/tasks',     builder: (c, s) => const TasksScreen()),
          GoRoute(path: '/home/more',      builder: (c, s) => const MoreScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(path: '/calendar',  builder: (c, s) => const CalendarScreen()),
      GoRoute(path: '/expenses',  builder: (c, s) => const ExpensesScreen()),
      GoRoute(path: '/reports',   builder: (c, s) => const ReportsScreen()),
      GoRoute(path: '/chat',      builder: (c, s) => const ChatScreen()),
      GoRoute(path: '/settings',  builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/profile',   builder: (c, s) => const ProfileScreen()),
    ],
  );
});
