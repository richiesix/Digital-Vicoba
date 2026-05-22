import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_screen_background.dart';
import 'governance_dashboard_screen.dart';

class ElectionDetailScreen extends ConsumerStatefulWidget {
  const ElectionDetailScreen({super.key, required this.electionId});

  final int electionId;

  @override
  ConsumerState<ElectionDetailScreen> createState() => _ElectionDetailScreenState();
}

class _ElectionDetailScreenState extends ConsumerState<ElectionDetailScreen> {
  Map<String, dynamic>? _election;
  Map<String, dynamic>? _results;
  bool _loading = true;
  bool _hasVoted = false;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider);
    final repo = ref.read(governanceRepositoryProvider);

    setState(() => _loading = true);
    try {
      final election = await repo.fetchElection(widget.electionId);
      var hasVoted = false;
      if (session?.memberId != null) {
        hasVoted = await repo.hasVoted(widget.electionId, session!.memberId!);
      }
      Map<String, dynamic>? results;
      if (['closed', 'completed'].contains(election['status'])) {
        results = await repo.fetchResults(widget.electionId);
      }
      if (mounted) {
        setState(() {
          _election = election;
          _hasVoted = hasVoted;
          _results = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _castVote(int candidateId) async {
    final session = ref.read(authSessionProvider);
    if (session?.memberId == null) return;

    HapticFeedback.lightImpact();
    setState(() => _voting = true);
    try {
      await ref.read(governanceRepositoryProvider).castVote(widget.electionId, {
        'member_id': session!.memberId,
        'candidate_id': candidateId,
        'client_id': const Uuid().v4(),
      });
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.voteRecorded),
            backgroundColor: AppColors.savings,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.overdue),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  String _roleLabel(String? role, dynamic l10n) => switch (role) {
        'chairperson' => l10n.roleChairperson,
        'secretary' => l10n.roleSecretary,
        'treasurer' => l10n.roleTreasurer,
        'money_counter' => l10n.roleMoneyCounter,
        'key_holder' => l10n.roleKeyHolder,
        _ => role ?? '',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final status = _election?['status'] as String? ?? '';
    final canVote = status == 'open' && !_hasVoted && session?.hasPermission('member.participate_governance') == true;
    final canManage = session?.hasPermission('group.manage_elections') == true
        || session?.isProvisionalChair == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _election?['title'] as String? ?? l10n.elections,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GlassScreenBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 32),
                  children: [
                    GlassCard(
                      blur: 16,
                      opacity: 0.55,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.how_to_vote, color: AppColors.primary, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _election?['title'] as String? ?? l10n.elections,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ),
                              _StatusBadge(status: status),
                            ],
                          ),
                          if ((_election?['description'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Text(
                              _election?['description'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                          if (_hasVoted) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.savings, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.voteRecorded,
                                  style: const TextStyle(
                                    color: AppColors.savings,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.candidates,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._candidateList(canVote, l10n),
                    if (_results != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        l10n.electionResults,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        blur: 12,
                        opacity: 0.5,
                        child: Text(
                          _formatResults(_results!),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (canManage && status == 'draft')
                      _ElectionActionButton(
                        label: l10n.openElection,
                        icon: Icons.play_arrow_rounded,
                        primary: true,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await ref.read(governanceRepositoryProvider).openElection(widget.electionId);
                          await _load();
                        },
                      ),
                    if (canManage && status == 'open')
                      _ElectionActionButton(
                        label: l10n.closeElection,
                        icon: Icons.fact_check_outlined,
                        primary: true,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await ref.read(governanceRepositoryProvider).closeElection(widget.electionId);
                          await _load();
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatResults(Map<String, dynamic> results) {
    final tally = results['results'];
    if (tally is List && tally.isNotEmpty) {
      return tally.map((e) {
        final m = e as Map<String, dynamic>;
        return '${m['position'] ?? ''}: ${m['votes'] ?? 0}';
      }).join('\n');
    }
    return results.toString();
  }

  List<Widget> _candidateList(bool canVote, dynamic l10n) {
    final candidates = _election?['candidates'] as List? ?? [];
    if (candidates.isEmpty) {
      return [
        GlassCard(
          blur: 10,
          opacity: 0.42,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              Icon(Icons.person_off_outlined, size: 40, color: Colors.grey.shade500),
              const SizedBox(height: 10),
              Text(
                l10n.noCandidatesYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ];
    }

    return candidates.map((c) {
      final map = c as Map<String, dynamic>;
      final member = map['member'] as Map<String, dynamic>?;
      final name = member != null
          ? '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim()
          : '—';
      final position = _roleLabel(map['position'] as String?, l10n);
      final candidateId = map['id'] as int;

      return GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        blur: 12,
        opacity: 0.52,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.savings.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (position.isNotEmpty)
                    Text(
                      position,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            if (canVote)
              _voting
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _castVote(candidateId),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.how_to_vote, color: Colors.white, size: 22),
                        ),
                      ),
                    )
            else if (_hasVoted)
              const Icon(Icons.check_circle, color: AppColors.savings, size: 28),
          ],
        ),
      );
    }).toList();
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'open' => (AppColors.savings, AppColors.savings.withValues(alpha: 0.15)),
      'draft' => (Colors.grey.shade700, Colors.grey.withValues(alpha: 0.15)),
      'closed' || 'completed' => (AppColors.primary, AppColors.primary.withValues(alpha: 0.12)),
      _ => (Colors.grey.shade700, Colors.grey.withValues(alpha: 0.12)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ElectionActionButton extends StatelessWidget {
  const _ElectionActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      onTap: onPressed,
      blur: 10,
      opacity: 0.5,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
