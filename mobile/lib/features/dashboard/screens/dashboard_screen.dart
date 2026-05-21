import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/fund_breakdown_bar.dart';
import '../widgets/member_balance_ring.dart';
import '../widgets/metric_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/status_pill.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _widgets;
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadDashboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final session = ref.read(authSessionProvider);
      final api = ref.read(apiClientProvider);
      final res = await api.get('/dashboard', queryParameters: {
        if (session?.groupId != null) 'group_id': session!.groupId,
      });
      setState(() {
        _widgets = res.data['widgets'] as Map<String, dynamic>?;
        _loading = false;
      });
      _animController.forward(from: 0);
    } catch (_) {
      setState(() => _loading = false);
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final localeCode = ref.watch(localeProvider).languageCode;
    final currency = NumberFormat.currency(
      locale: localeCode == 'en' ? 'en_TZ' : 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    final firstName = (session?.userName ?? l10n.user).split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DashboardHeader(
                        greeting: l10n.greetingHello(firstName),
                        roleLabel: _roleLabel(session, l10n),
                        subtitle: _widgets?['group_name'] as String?,
                        gradientColors: _headerGradient(session),
                        badgeIcon: _roleIcon(session),
                        onSync: () => context.push(AppRoutes.sync),
                        onSettings: () => context.push(AppRoutes.profile),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (session != null) ..._buildRoleBody(session, currency, l10n),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Color> _headerGradient(AuthSession? session) {
    if (session?.isSuperAdmin == true) {
      return [const Color(0xFF1B5E20), const Color(0xFF33691E)];
    }
    if (session?.isTreasurer == true) {
      return [const Color(0xFF2E7D32), const Color(0xFF43A047)];
    }
    return [const Color(0xFF388E3C), const Color(0xFF66BB6A)];
  }

  IconData? _roleIcon(AuthSession? session) {
    if (session?.isSuperAdmin == true) return Icons.admin_panel_settings;
    if (session?.isTreasurer == true) return Icons.account_balance;
    return Icons.person;
  }

  String _roleLabel(AuthSession? session, AppLocalizations l10n) {
    if (session?.isSuperAdmin == true) return l10n.roleSuperAdmin;
    if (session?.isTreasurer == true) return l10n.roleTreasurer;
    return l10n.roleMember;
  }

  List<Widget> _buildRoleBody(AuthSession session, NumberFormat currency, AppLocalizations l10n) {
    if (session.isSuperAdmin) return _superAdminBody(l10n, currency);
    if (session.isTreasurer) return _treasurerBody(session, l10n, currency);
    return _memberBody(session, l10n, currency);
  }

  List<Widget> _superAdminBody(AppLocalizations l10n, NumberFormat currency) {
    final fraud = _widgets?['fraud_alerts'] ?? 0;
    final mmStatus = _widgets?['mobile_money_status'] as String? ?? 'operational';
    final apiHealth = _widgets?['api_health'] as String? ?? 'healthy';

    return [
      _sectionTitle(l10n.platformOverview, Icons.public),
      const SizedBox(height: 12),
      MetricCard(
        title: l10n.nationalSavings,
        value: currency.format(_widgets?['total_savings'] ?? 0),
        icon: Icons.savings,
        color: AppColors.savings,
        onTap: () => context.push(AppRoutes.reports),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 130,
        child: Row(
          children: [
            Expanded(
              child: MetricCard(
                title: l10n.totalGroups,
                value: '${_widgets?['total_groups'] ?? '—'}',
                icon: Icons.groups,
                color: AppColors.primary,
                compact: true,
                onTap: () => context.push(AppRoutes.groups),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: l10n.totalMembers,
                value: '${_widgets?['total_members'] ?? '—'}',
                icon: Icons.people,
                color: AppColors.savings,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: l10n.activeLoans,
                value: '${_widgets?['active_loans'] ?? '—'}',
                icon: Icons.account_balance,
                color: AppColors.pending,
                compact: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            StatusPill(
              icon: Icons.warning_amber,
              label: l10n.fraudAlerts,
              value: '$fraud',
              color: fraud > 0 ? AppColors.overdue : AppColors.savings,
              onTap: () => context.push(AppRoutes.reports),
            ),
            const SizedBox(width: 10),
            StatusPill(
              icon: Icons.phone_android,
              label: l10n.mobileMoneyStatus,
              value: mmStatus == 'operational' ? l10n.operational : mmStatus,
              color: AppColors.savings,
            ),
            const SizedBox(width: 10),
            StatusPill(
              icon: Icons.cloud_done,
              label: l10n.systemHealth,
              value: apiHealth == 'healthy' ? l10n.healthy : apiHealth,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ..._quickActionSection(session: null, l10n: l10n, isAdmin: true),
    ];
  }

  List<Widget> _treasurerBody(AuthSession session, AppLocalizations l10n, NumberFormat currency) {
    final balance = (_widgets?['group_balance'] as num?)?.toDouble() ?? 0;
    final emergency = (_widgets?['emergency_fund'] as num?)?.toDouble() ?? 0;
    final social = (_widgets?['social_fund'] as num?)?.toDouble() ?? 0;
    final total = balance + emergency + social;

    return [
      _sectionTitle(l10n.groupFinances, Icons.account_balance_wallet),
      const SizedBox(height: 12),
      MetricCard(
        title: l10n.groupBalance,
        value: currency.format(balance),
        icon: Icons.savings,
        color: AppColors.savings,
        subtitle: l10n.tapToOpen,
        onTap: () => context.push(AppRoutes.savings),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.groupFinances, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              FundBreakdownBar(
                label: l10n.savings,
                amount: balance,
                total: total > 0 ? total : 1,
                color: AppColors.savings,
              ),
              FundBreakdownBar(
                label: l10n.emergencyFund,
                amount: emergency,
                total: total > 0 ? total : 1,
                color: AppColors.pending,
              ),
              FundBreakdownBar(
                label: l10n.socialFund,
                amount: social,
                total: total > 0 ? total : 1,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 118,
        child: Row(
          children: [
            Expanded(
              child: MetricCard(
                title: l10n.pendingRepayments,
                value: '${_widgets?['pending_repayments'] ?? 0}',
                icon: Icons.schedule,
                color: AppColors.pending,
                compact: true,
                onTap: () => context.push(AppRoutes.loanApprove),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: l10n.overdue,
                value: '${_widgets?['overdue_loans'] ?? 0}',
                icon: Icons.warning,
                color: AppColors.overdue,
                compact: true,
                onTap: () => context.push(AppRoutes.loanApprove),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ..._quickActionSection(session: session, l10n: l10n, isAdmin: false),
    ];
  }

  List<Widget> _memberBody(AuthSession session, AppLocalizations l10n, NumberFormat currency) {
    final savings = (_widgets?['current_savings'] as num?)?.toDouble() ?? 0;
    final loan = (_widgets?['loan_balance'] as num?)?.toDouble() ?? 0;
    final meetings = _widgets?['upcoming_meetings'] ?? 0;
    final alerts = _widgets?['notifications_unread'] ?? 0;

    return [
      _sectionTitle(l10n.myWallet, Icons.wallet),
      const SizedBox(height: 12),
      MemberBalanceRing(
        savingsLabel: l10n.mySavings,
        savingsValue: currency.format(savings),
        loanLabel: l10n.loanDebt,
        loanValue: currency.format(loan),
        savingsAmount: savings,
        loanAmount: loan,
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 118,
        child: Row(
          children: [
            Expanded(
              child: MetricCard(
                title: l10n.shares,
                value: '${_widgets?['total_shares'] ?? 0}',
                icon: Icons.pie_chart,
                color: AppColors.primary,
                compact: true,
                onTap: () => context.push(AppRoutes.savings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: l10n.meetingsSoon,
                value: '$meetings',
                icon: Icons.event,
                color: AppColors.savings,
                compact: true,
                onTap: () => context.push(AppRoutes.meetings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: l10n.unreadAlerts,
                value: '$alerts',
                icon: Icons.notifications_active,
                color: AppColors.pending,
                compact: true,
                onTap: () => context.push(AppRoutes.notifications),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ..._quickActionSection(session: session, l10n: l10n, isAdmin: false),
    ];
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<Widget> _quickActionSection({
    required AuthSession? session,
    required AppLocalizations l10n,
    required bool isAdmin,
  }) {
    final actions = _widgets?['quick_actions'] as List? ?? [];
    final tiles = <Widget>[];

    for (final raw in actions) {
      final a = raw as Map<String, dynamic>;
      final perm = a['permission'] as String?;
      if (session != null && perm != null && !session.hasPermission(perm)) {
        continue;
      }
      final key = a['key'] as String?;
      final meta = _actionMeta(key, l10n, isAdmin);
      if (meta == null) continue;

      tiles.add(
        QuickActionTile(
          icon: meta.$1,
          label: meta.$2,
          color: meta.$3,
          onTap: () => _navigateAction(key),
        ),
      );
    }

    if (tiles.isEmpty) return [];

    return [
      _sectionTitle(l10n.quickActionsTitle, Icons.touch_app),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
        children: tiles,
      ),
    ];
  }

  (IconData, String, Color)? _actionMeta(String? key, AppLocalizations l10n, bool isAdmin) {
    return switch (key) {
      'record_contribution' => (Icons.add_card, l10n.recordShare, AppColors.savings),
      'buy_shares' => (Icons.savings, l10n.contributeBuyShares, AppColors.savings),
      'apply_loan' => (Icons.request_quote, l10n.applyLoan, AppColors.pending),
      'verify_repayment' => (Icons.payments, l10n.payments, AppColors.primary),
      'users' => (Icons.people, l10n.manageUsers, AppColors.primary),
      'groups' => (Icons.groups, l10n.groups, AppColors.savings),
      'analytics' || 'reports' => (Icons.analytics, l10n.reports, AppColors.primary),
      'fraud' => (Icons.shield, l10n.fraudMonitor, AppColors.overdue),
      'logs' => (Icons.history, l10n.systemLogs, Colors.blueGrey),
      'share_out' => (Icons.pie_chart, l10n.shareOutAction, AppColors.pending),
      'history' => (Icons.receipt_long, l10n.historyAction, AppColors.savings),
      'meetings' => (Icons.event, l10n.meetings, AppColors.savings),
      _ => isAdmin ? null : (Icons.touch_app, key ?? '', AppColors.primary),
    };
  }

  void _navigateAction(String? key) {
    switch (key) {
      case 'record_contribution':
      case 'buy_shares':
      case 'history':
        context.push(AppRoutes.savings);
      case 'apply_loan':
        context.push(AppRoutes.loanApply);
      case 'verify_repayment':
        context.push(AppRoutes.loanApprove);
      case 'users':
        context.push(AppRoutes.members);
      case 'groups':
        context.push(AppRoutes.groups);
      case 'analytics':
      case 'reports':
      case 'fraud':
        context.push(AppRoutes.reports);
      case 'logs':
        context.push(AppRoutes.sync);
      case 'share_out':
        context.push(AppRoutes.shareOut);
      case 'meetings':
        context.push(AppRoutes.meetings);
      default:
        break;
    }
  }
}
