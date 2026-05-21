import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class MeetingScreen extends ConsumerStatefulWidget {
  const MeetingScreen({super.key});

  @override
  ConsumerState<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends ConsumerState<MeetingScreen> {
  Map<String, dynamic>? _meeting;
  List<Map<String, dynamic>> _allMeetings = [];
  List<Map<String, dynamic>> _members = [];
  final Map<int, bool> _attendance = {};
  String _searchQuery = '';
  int _tabIndex = 0;
  bool _loading = true;
  bool _starting = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final session = ref.read(authSessionProvider);
    final groupId = session?.groupId;
    if (groupId == null) {
      setState(() => _loading = false);
      return;
    }

    final api = ref.read(apiClientProvider);
    try {
      final meetingsRes = await api.get('/groups/$groupId/meetings');
      final data = meetingsRes.data['meetings'];
      final list = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : <dynamic>[]);

      final meetings = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      Map<String, dynamic>? active;
      for (final m in meetings) {
        if (m['status'] == 'scheduled' || m['status'] == 'in_progress') {
          active = m;
          break;
        }
      }

      final membersRes = await api.get('/groups/$groupId/members');
      final membersData = membersRes.data['members'];
      final memberList = (membersData is Map && membersData['data'] is List)
          ? membersData['data'] as List
          : (membersData is List ? membersData : <dynamic>[]);

      setState(() {
        _allMeetings = meetings;
        _meeting = active;
        _members = memberList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _attendance.clear();
        for (final m in _members) {
          final id = m['id'] as int?;
          if (id != null) _attendance[id] = false;
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  bool get _isInProgress => _meeting?['status'] == 'in_progress';

  int get _presentCount => _attendance.values.where((v) => v).length;

  int get _quorumRequired => (_meeting?['quorum_required'] as num?)?.toInt() ?? _members.length;

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    final q = _searchQuery.toLowerCase();
    return _members.where((m) {
      final name = '${m['first_name']} ${m['last_name']}'.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  String? _countdownText(AppLocalizations l10n) {
    final raw = _meeting?['scheduled_at'];
    if (raw == null || _isInProgress) return null;
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null || dt.isBefore(DateTime.now())) return null;
    final diff = dt.difference(DateTime.now());
    if (diff.inDays > 0) return l10n.startsIn('${diff.inDays} siku');
    if (diff.inHours > 0) return l10n.startsIn('${diff.inHours} saa');
    return l10n.startsIn('${diff.inMinutes} dak');
  }

  Future<void> _handleStartMeeting() async {
    final session = ref.read(authSessionProvider);
    final meeting = _meeting;
    final canManage = session?.hasPermission('group.manage_meetings') ?? false;

    if (meeting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noMeetingScheduled)),
      );
      return;
    }

    if (_isInProgress) {
      setState(() => _tabIndex = 1);
      return;
    }

    if (!canManage) {
      if (_isInProgress) {
        setState(() => _tabIndex = 1);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.waitForLeader)),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      final res = await ref.read(apiClientProvider).post('/meetings/${meeting['id']}/start');
      setState(() {
        _meeting = Map<String, dynamic>.from(res.data['meeting'] as Map);
        _tabIndex = 1;
        _starting = false;
      });
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] as String? ?? context.l10n.meetingStarted),
          backgroundColor: AppColors.savings,
        ),
      );
    } catch (e) {
      setState(() => _starting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.failed}: $e')),
      );
    }
  }

  Future<void> _saveAttendance() async {
    final session = ref.read(authSessionProvider);
    final meeting = _meeting;
    if (meeting == null || !_isInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.startMeetingFirst)),
      );
      return;
    }

    final canManage = session?.hasPermission('group.manage_meetings') ?? false;
    final myId = session?.memberId;

    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).post('/meetings/${meeting['id']}/attendance', data: {
        'attendance': _attendance.entries
            .where((e) => canManage || e.key == myId)
            .map((e) => {'member_id': e.key, 'status': e.value ? 'present' : 'absent'})
            .toList(),
      });
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.attendanceSaved), backgroundColor: AppColors.savings),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.failed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (final id in _attendance.keys) {
        _attendance[id] = true;
      }
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final localeCode = ref.watch(localeProvider).languageCode;
    final canManage = session?.hasPermission('group.manage_meetings') ?? false;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _MeetingsHeader(l10n: l10n, meeting: _meeting, isLive: _isInProgress)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _TabPill(
                      label: l10n.meetingTabUpcoming,
                      icon: Icons.event,
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    const SizedBox(width: 10),
                    _TabPill(
                      label: l10n.attendanceTab,
                      icon: Icons.how_to_reg,
                      selected: _tabIndex == 1,
                      badge: _isInProgress ? '!' : null,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ],
                ),
              ),
            ),
            if (_tabIndex == 0)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_meeting != null) ...[
                      _UpcomingMeetingCard(
                        meeting: _meeting!,
                        localeCode: localeCode,
                        countdown: _countdownText(l10n),
                        isLive: _isInProgress,
                        canStart: canManage,
                        starting: _starting,
                        onAction: _handleStartMeeting,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 20),
                    ] else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(l10n.noMeetingsYet, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    if (_allMeetings.where((m) => m['status'] == 'completed').isNotEmpty) ...[
                      Text(l10n.pastMeetings, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      ..._allMeetings
                          .where((m) => m['status'] == 'completed')
                          .take(5)
                          .map((m) => _PastMeetingTile(meeting: m, localeCode: localeCode, l10n: l10n)),
                    ],
                  ]),
                ),
              )
            else ...[
              if (!_isInProgress)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: AppColors.pending.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.pending),
                            const SizedBox(width: 10),
                            Expanded(child: Text(l10n.startMeetingHint)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _AttendanceStatsBar(
                      present: _presentCount,
                      total: _members.length,
                      quorum: _quorumRequired,
                      l10n: l10n,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: l10n.searchMember,
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _markAllPresent,
                            icon: const Icon(Icons.done_all),
                            tooltip: l10n.markAllPresent,
                            style: IconButton.styleFrom(backgroundColor: AppColors.savings),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList.builder(
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, i) {
                    final m = _filteredMembers[i];
                    final id = m['id'] as int? ?? i;
                    final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
                    final present = _attendance[id] ?? false;
                    final canMark = _isInProgress && (canManage || id == session?.memberId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: canMark
                            ? () {
                                setState(() => _attendance[id] = !present);
                                HapticFeedback.selectionClick();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: present ? AppColors.savings : Colors.grey.shade300,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: present ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name.isEmpty ? l10n.memberLabel(i + 1) : name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  present ? Icons.check_circle : Icons.radio_button_unchecked,
                                  key: ValueKey(present),
                                  color: present ? AppColors.savings : Colors.grey,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isInProgress)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveAttendance,
                      icon: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(canManage ? l10n.saveAttendance : l10n.saveMyAttendance),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.savings,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeetingsHeader extends StatelessWidget {
  const _MeetingsHeader({
    required this.l10n,
    required this.meeting,
    required this.isLive,
  });

  final AppLocalizations l10n;
  final Map<String, dynamic>? meeting;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
              : [const Color(0xFF00695C), const Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.meetings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.meetingLive,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.meetingsSubtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF00695C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: selected ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? Colors.white : const Color(0xFF00695C), size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF00695C),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingMeetingCard extends StatelessWidget {
  const _UpcomingMeetingCard({
    required this.meeting,
    required this.localeCode,
    required this.countdown,
    required this.isLive,
    required this.canStart,
    required this.starting,
    required this.onAction,
    required this.l10n,
  });

  final Map<String, dynamic> meeting;
  final String localeCode;
  final String? countdown;
  final bool isLive;
  final bool canStart;
  final bool starting;
  final VoidCallback onAction;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final raw = meeting['scheduled_at'];
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    final dateStr = dt != null
        ? DateFormat('EEEE, d MMM · HH:mm', localeCode).format(dt)
        : '';

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00695C).withValues(alpha: 0.15),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isLive ? Icons.play_circle_fill : Icons.event,
                        color: const Color(0xFF00695C),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting['agenda'] as String? ?? l10n.weeklyMeeting,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(dateStr, style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (countdown != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.pending.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.pending, size: 20),
                        const SizedBox(width: 8),
                        Text(countdown!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                if (meeting['location'] != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.place, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(child: Text(meeting['location'] as String)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      isLive ? l10n.inProgress : l10n.scheduled,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: isLive ? AppColors.savings : AppColors.pending,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: isLive ? AppColors.savings : const Color(0xFF00695C),
            child: InkWell(
              onTap: starting ? null : onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (starting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    else ...[
                      Icon(
                        isLive ? Icons.how_to_reg : (canStart ? Icons.play_arrow : Icons.visibility),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isLive
                            ? l10n.attendanceTab
                            : (canStart ? l10n.startMeeting : l10n.viewAttendance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatsBar extends StatelessWidget {
  const _AttendanceStatsBar({
    required this.present,
    required this.total,
    required this.quorum,
    required this.l10n,
  });

  final int present;
  final int total;
  final int quorum;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? present / total : 0.0;
    final quorumMet = present >= quorum;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: quorumMet ? AppColors.savings : AppColors.pending,
                  ),
                  Text(
                    '${(ratio * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.quorumLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(
                    l10n.attendanceProgress(present, total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quorumMet ? '✓ Quorum' : 'Quorum: $quorum',
                    style: TextStyle(
                      color: quorumMet ? AppColors.savings : AppColors.pending,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastMeetingTile extends StatelessWidget {
  const _PastMeetingTile({
    required this.meeting,
    required this.localeCode,
    required this.l10n,
  });

  final Map<String, dynamic> meeting;
  final String localeCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final raw = meeting['scheduled_at'];
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    final date = dt != null ? DateFormat('d MMM yyyy', localeCode).format(dt) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(Icons.event_available, color: Color(0xFF00695C)),
        ),
        title: Text(meeting['agenda'] as String? ?? l10n.weeklyMeeting, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(date),
        trailing: Chip(
          label: Text(l10n.completed, style: const TextStyle(fontSize: 11)),
          backgroundColor: AppColors.savings.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
