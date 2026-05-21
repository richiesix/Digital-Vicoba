import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/groups/screens/group_list_screen.dart';
import '../../features/loans/screens/loan_application_screen.dart';
import '../../features/loans/screens/loan_approval_screen.dart';
import '../../features/meetings/screens/meeting_screen.dart';
import '../../features/members/screens/member_management_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../core/reports/report_storage_service.dart';
import '../../features/reports/screens/report_viewer_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/savings/screens/savings_screen.dart';
import '../../features/share_out/screens/share_out_screen.dart';
import '../../features/sync/screens/sync_status_screen.dart';
import '../l10n/l10n_extension.dart';
import '../widgets/main_shell.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const pinSetup = '/pin-setup';
  static const home = '/home';
  static const groups = '/groups';
  static const members = '/members';
  static const savings = '/savings';
  static const loanApply = '/loans/apply';
  static const loanApprove = '/loans/approve';
  static const meetings = '/meetings';
  static const reports = '/reports';
  static const reportView = '/reports/view';
  static const notifications = '/notifications';
  static const shareOut = '/share-out';
  static const profile = '/profile';
  static const sync = '/sync';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.error)),
      body: Center(child: Text(state.error?.toString() ?? l10n.pageNotFound)),
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) => OtpScreen(
        phone: state.uri.queryParameters['phone'] ?? '',
        purpose: state.uri.queryParameters['purpose'] ?? 'register',
      ),
    ),
    GoRoute(
      path: AppRoutes.pinSetup,
      builder: (context, state) => const PinSetupScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.groups,
          builder: (context, state) => const GroupListScreen(),
        ),
        GoRoute(
          path: AppRoutes.members,
          builder: (context, state) => const MemberManagementScreen(),
        ),
        GoRoute(
          path: AppRoutes.savings,
          builder: (context, state) => const SavingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.loanApply,
          builder: (context, state) => const LoanApplicationScreen(),
        ),
        GoRoute(
          path: AppRoutes.loanApprove,
          builder: (context, state) => const LoanApprovalScreen(),
        ),
        GoRoute(
          path: AppRoutes.meetings,
          builder: (context, state) => const MeetingScreen(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: AppRoutes.reportView,
          builder: (context, state) {
            final report = state.extra as SavedReport?;
            if (report == null) {
              return const ReportsScreen();
            }
            return ReportViewerScreen(report: report);
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.shareOut,
          builder: (context, state) => const ShareOutScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.sync,
          builder: (context, state) => const SyncStatusScreen(),
        ),
      ],
    ),
  ],
);
