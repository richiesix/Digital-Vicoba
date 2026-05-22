import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_screen_background.dart';
import '../repositories/governance_repository.dart';

final governanceRepositoryProvider = Provider<GovernanceRepository>((ref) {
  return GovernanceRepository(ref.watch(apiClientProvider));
});

class GovernanceDashboardScreen extends ConsumerStatefulWidget {
  const GovernanceDashboardScreen({super.key});

  @override
  ConsumerState<GovernanceDashboardScreen> createState() => _GovernanceDashboardScreenState();
}

class _GovernanceDashboardScreenState extends ConsumerState<GovernanceDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refreshSession() async {
    try {
      final me = await ref.read(apiClientProvider).get('/auth/me');
      final session = AuthSession.fromProfile(me.data as Map<String, dynamic>);
      await ref.read(authSessionProvider.notifier).setSession(session);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _syncSessionFromDashboard(Map<String, dynamic> data) async {
    final apiGovernanceComplete = data['governance_complete'] as bool?;
    if (apiGovernanceComplete == null) return;

    final current = ref.read(authSessionProvider);
    if (current == null) return;

    final sessionStale = current.governanceComplete != apiGovernanceComplete
        || (!apiGovernanceComplete &&
            current.primaryRole == 'member' &&
            !current.isInterimChair &&
            !current.hasPermission('group.manage_members'));

    if (!sessionStale) return;

    await _refreshSession();
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider);
    final groupId = session?.groupId;
    if (groupId == null) {
      setState(() {
        _loading = false;
        _error = 'No group';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    if (session?.needsGovernanceSetup == true) {
      await _refreshSession();
    }

    try {
      final repo = ref.read(governanceRepositoryProvider);
      final data = await repo.fetchDashboard(groupId);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
      await _syncSessionFromDashboard(data);
      await _refreshSessionIfGovernanceComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshSessionIfGovernanceComplete() async {
    final current = ref.read(authSessionProvider);
    if (current == null || current.governanceComplete) return;

    try {
      final me = await ref.read(apiClientProvider).get('/auth/me');
      final session = AuthSession.fromProfile(me.data as Map<String, dynamic>);
      if (session.governanceComplete && mounted) {
        await ref.read(authSessionProvider.notifier).setSession(session);
      }
    } catch (_) {}
  }

  int get _memberCount => _data?['member_count'] as int? ?? 0;

  bool get _governanceIncomplete {
    final fromApi = _data?['governance_complete'] as bool?;
    if (fromApi != null) return !fromApi;
    return ref.read(authSessionProvider)?.needsGovernanceSetup == true;
  }

  bool get _canAssignLeadership => _data?['can_assign_leadership'] as bool? ?? _memberCount >= 2;

  bool get _canManageMembers {
    final fromApi = _data?['can_manage_members'] as bool?;
    if (fromApi != null) return fromApi;
    final session = ref.read(authSessionProvider);
    return session?.canSetupGovernance == true;
  }

  void _openRegisterMember() {
    final session = ref.read(authSessionProvider);
    final inSetup = _governanceIncomplete || session?.needsGovernanceSetup == true;

    if (!_canManageMembers && !inSetup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.governancePermissionHint)),
      );
      return;
    }

    if (!_canManageMembers && inSetup) {
      _refreshSession().then((_) {
        if (!mounted) return;
        context.go('${AppRoutes.members}?register=1');
      });
      return;
    }

    context.go('${AppRoutes.members}?register=1');
  }

  bool get _canAssignLeadershipAction {
    final session = ref.read(authSessionProvider);
    return session?.hasPermission('group.assign_leadership') == true || session?.isProvisionalChair == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final inSetup = _governanceIncomplete || session?.needsGovernanceSetup == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.governance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: inSetup
          ? FloatingActionButton.extended(
              onPressed: _openRegisterMember,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                l10n.registerMember,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Stack(
        children: [
          const GlassScreenBackground(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: GlassCard(
                            child: Text(_error!, textAlign: TextAlign.center),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, inSetup ? 88 : 24),
                          children: [
                            if (inSetup) ...[
                              if (session?.isProvisionalChair == true || session?.isInterimChair == true)
                                GlassCard(
                                  blur: 12,
                                  opacity: 0.5,
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.hourglass_top, color: Colors.grey.shade800, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l10n.interimChairBanner,
                                          style: TextStyle(height: 1.4, fontSize: 13, color: Colors.grey.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                GlassCard(
                                  blur: 12,
                                  opacity: 0.5,
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    l10n.governanceLockedMessage,
                                    style: TextStyle(height: 1.4, fontSize: 13, color: Colors.grey.shade800),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              _SetupStepsCard(
                                memberCount: _memberCount,
                                canAssign: _canAssignLeadership,
                                canManageMembers: _canManageMembers,
                                canAssignLeadership: _canAssignLeadershipAction,
                                onAddMember: _openRegisterMember,
                                onAssignLeadership: _canAssignLeadership && _canAssignLeadershipAction
                                    ? () => context.push(AppRoutes.governanceAssignLeadership)
                                    : null,
                              ),
                              if (!_canManageMembers) ...[
                                const SizedBox(height: 10),
                                GlassCard(
                                  blur: 10,
                                  opacity: 0.45,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l10n.governancePermissionHint,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: _refreshSession,
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: Text(l10n.governanceReloginHint),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              GlassCard(
                                blur: 14,
                                opacity: 0.55,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.savings.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.people, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.memberCountLabel,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            l10n.memberCountValue(_memberCount),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: _openRegisterMember,
                                      icon: const Icon(Icons.person_add, size: 18),
                                      label: Text(l10n.registerMember),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _SectionLabel(title: l10n.currentLeadership),
                            const SizedBox(height: 8),
                            ..._leadershipTiles(_data?['leadership'] as List? ?? []),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SectionLabel(title: l10n.elections),
                                if (session?.hasPermission('group.manage_elections') == true ||
                                    session?.hasPermission('group.call_elections') == true)
                                  TextButton(
                                    onPressed: () => context.push(AppRoutes.governanceElections),
                                    child: Text(l10n.viewAll, style: const TextStyle(color: Colors.white)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._electionTiles(context, _data?['open_elections'] as List? ?? []),
                            const SizedBox(height: 12),
                            if (session?.hasPermission('group.call_elections') == true ||
                                session?.hasPermission('group.manage_elections') == true)
                              _GlassActionButton(
                                icon: Icons.how_to_vote,
                                label: l10n.createElection,
                                onPressed: () => context.push(AppRoutes.governanceCreateElection),
                              ),
                            if (session?.hasPermission('group.assign_leadership') == true) ...[
                              const SizedBox(height: 10),
                              _GlassActionButton(
                                icon: Icons.assignment_ind,
                                label: l10n.assignLeadership,
                                outlined: true,
                                enabled: !inSetup || _canAssignLeadership,
                                onPressed: (inSetup && !_canAssignLeadership)
                                    ? null
                                    : () => context.push(AppRoutes.governanceAssignLeadership),
                              ),
                              if (inSetup && !_canAssignLeadership)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    l10n.membersNeededForLeadership,
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _leadershipTiles(List<dynamic> leadership) {
    if (leadership.isEmpty) {
      return [
        GlassCard(
          blur: 10,
          opacity: 0.42,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            context.l10n.noLeadershipYet,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ];
    }

    return leadership.map((item) {
      final map = item as Map<String, dynamic>;
      final member = map['member'] as Map<String, dynamic>?;
      final name = member != null
          ? '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim()
          : '—';
      return GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        blur: 10,
        opacity: 0.48,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Icon(_roleIcon(map['role_name'] as String?), color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _roleLabel(map['role_name'] as String?),
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                  ),
                  Text(name, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _electionTiles(BuildContext context, List<dynamic> elections) {
    if (elections.isEmpty) {
      return [
        GlassCard(
          blur: 10,
          opacity: 0.42,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            context.l10n.noOpenElections,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ];
    }

    return elections.map((item) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as int;
      return GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        blur: 10,
        opacity: 0.48,
        onTap: () => context.push('${AppRoutes.governanceElectionDetail}/$id'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    map['title'] as String? ?? '',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                  ),
                  Text(
                    map['status'] as String? ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      );
    }).toList();
  }

  IconData _roleIcon(String? role) => switch (role) {
        'chairperson' => Icons.star,
        'secretary' => Icons.edit_note,
        'treasurer' => Icons.account_balance,
        'money_counter' => Icons.payments,
        'key_holder' => Icons.key,
        _ => Icons.person,
      };

  String _roleLabel(String? role) {
    final l10n = context.l10n;
    return switch (role) {
      'chairperson' => l10n.roleChairperson,
      'secretary' => l10n.roleSecretary,
      'treasurer' => l10n.roleTreasurer,
      'money_counter' => l10n.roleMoneyCounter,
      'key_holder' => l10n.roleKeyHolder,
      _ => role ?? '',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

class _SetupStepsCard extends StatelessWidget {
  const _SetupStepsCard({
    required this.memberCount,
    required this.canAssign,
    required this.canManageMembers,
    required this.canAssignLeadership,
    required this.onAddMember,
    this.onAssignLeadership,
  });

  final int memberCount;
  final bool canAssign;
  final bool canManageMembers;
  final bool canAssignLeadership;
  final VoidCallback onAddMember;
  final VoidCallback? onAssignLeadership;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step1Done = memberCount >= 2;

    return GlassCard(
      blur: 16,
      opacity: 0.58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.governanceSetupTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 12),
          _SetupStep(
            step: 1,
            title: l10n.governanceStep1,
            done: step1Done,
            actionLabel: l10n.registerMember,
            onAction: onAddMember,
            hint: !canManageMembers ? l10n.governancePermissionHint : null,
          ),
          const SizedBox(height: 10),
          _SetupStep(
            step: 2,
            title: l10n.governanceStep2,
            done: false,
            enabled: canAssign && canAssignLeadership,
            actionLabel: l10n.assignLeadership,
            onAction: canAssignLeadership ? onAssignLeadership : null,
            hint: !canAssign
                ? l10n.membersNeededForLeadership
                : (!canAssignLeadership ? l10n.governancePermissionHint : null),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.step,
    required this.title,
    required this.done,
    this.enabled = true,
    this.actionLabel,
    this.onAction,
    this.hint,
  });

  final int step;
  final String title;
  final bool done;
  final bool enabled;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: done ? AppColors.savings : Colors.grey.shade300,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('$step', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(hint!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: enabled && onAction != null ? onAction : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 12,
      opacity: 0.5,
      onTap: enabled ? onPressed : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: enabled ? AppColors.primary : Colors.grey, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.grey.shade900 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
