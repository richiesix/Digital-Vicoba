import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../l10n/l10n_extension.dart';
import '../router/app_router.dart';
import 'modern_bottom_nav.dart';
import 'nav_icons.dart';
import 'offline_banner.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final location = GoRouterState.of(context).uri.path;
    final destinations = _destinationsFor(session, l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            if (session != null)
              Material(
                color: _roleColor(session.primaryRole),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Icon(_roleIcon(session.primaryRole), color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _roleLabel(session.primaryRole, l10n),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: destinations.length > 1
          ? ModernBottomNav(
              destinations: destinations,
              selectedIndex: _indexFromLocation(location, destinations),
              onSelected: (i) => context.go(destinations[i].route),
            )
          : null,
    );
  }

  int _indexFromLocation(String location, List<NavDestination> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  List<NavDestination> _destinationsFor(AuthSession? session, dynamic l10n) {
    if (session == null) {
      return [NavDestination(route: AppRoutes.home, iconAsset: NavIcons.home, label: l10n.home)];
    }

    if (session.isSuperAdmin) {
      return [
        NavDestination(route: AppRoutes.home, iconAsset: NavIcons.dashboard, label: l10n.dashboard),
        NavDestination(route: AppRoutes.groups, iconAsset: NavIcons.groups, label: l10n.groups),
        NavDestination(route: AppRoutes.reports, iconAsset: NavIcons.reports, label: l10n.analytics),
        NavDestination(route: AppRoutes.notifications, iconAsset: NavIcons.notifications, label: l10n.notifications),
        NavDestination(route: AppRoutes.profile, iconAsset: NavIcons.profile, label: l10n.profile),
      ];
    }

    if (session.isTreasurer) {
      return [
        NavDestination(route: AppRoutes.home, iconAsset: NavIcons.finance, label: l10n.finance),
        if (session.hasPermission('group.record_contribution'))
          NavDestination(route: AppRoutes.savings, iconAsset: NavIcons.savings, label: l10n.savings),
        if (session.hasPermission('group.verify_repayments'))
          NavDestination(route: AppRoutes.loanApprove, iconAsset: NavIcons.payments, label: l10n.payments),
        NavDestination(route: AppRoutes.reports, iconAsset: NavIcons.reports, label: l10n.reports),
        NavDestination(route: AppRoutes.profile, iconAsset: NavIcons.profile, label: l10n.profile),
      ];
    }

    return [
      NavDestination(route: AppRoutes.home, iconAsset: NavIcons.home, label: l10n.home),
      if (session.hasPermission('member.buy_shares'))
        NavDestination(route: AppRoutes.savings, iconAsset: NavIcons.savings, label: l10n.savings),
      if (session.hasPermission('member.apply_loan'))
        NavDestination(route: AppRoutes.loanApply, iconAsset: NavIcons.loans, label: l10n.loans),
      if (session.hasPermission('member.view_meetings'))
        NavDestination(route: AppRoutes.meetings, iconAsset: NavIcons.meetings, label: l10n.meetings),
      NavDestination(route: AppRoutes.profile, iconAsset: NavIcons.profile, label: l10n.profile),
    ];
  }

  Color _roleColor(String role) => switch (role) {
        'super_admin' => const Color(0xFF1B5E20),
        'treasurer' => const Color(0xFF2E7D32),
        _ => const Color(0xFF388E3C),
      };

  IconData _roleIcon(String role) => switch (role) {
        'super_admin' => Icons.admin_panel_settings,
        'treasurer' => Icons.account_balance,
        _ => Icons.person,
      };

  String _roleLabel(String role, dynamic l10n) => switch (role) {
        'super_admin' => l10n.roleSuperAdmin,
        'treasurer' => l10n.roleTreasurer,
        'chairperson' => l10n.roleChairperson,
        'secretary' => l10n.roleSecretary,
        _ => l10n.roleMember,
      };
}
