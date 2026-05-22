import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_screen_background.dart';
import '../../../core/widgets/nav_icons.dart';
import '../../../l10n/app_localizations.dart';

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? _asDouble(value).toInt();
  return fallback;
}

enum _MemberFilter { all, active, withLoan }

enum _MemberSort { name, savings }

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends ConsumerState<MemberManagementScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  _MemberFilter _filter = _MemberFilter.all;
  _MemberSort _sort = _MemberSort.name;
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _load().then((_) => _maybeOpenRegisterFromQuery());
  }

  void _maybeOpenRegisterFromQuery() {
    if (!mounted) return;
    final register = GoRouterState.of(context).uri.queryParameters['register'];
    if (register != '1') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showAddMember();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final session = ref.read(authSessionProvider);
    final groupId = session?.groupId;
    if (groupId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await ref.read(apiClientProvider).get('/groups/$groupId/members');
      final data = res.data['members'];
      final list = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : <dynamic>[]);
      setState(() {
        _members = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    var list = List<Map<String, dynamic>>.from(_members);

    if (_searchQuery.isNotEmpty) {
      list = list.where((m) {
        final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.toLowerCase();
        final phone = (m['phone_number'] ?? '').toString().toLowerCase();
        final num = (m['member_number'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || phone.contains(_searchQuery) || num.contains(_searchQuery);
      }).toList();
    }

    list = switch (_filter) {
      _MemberFilter.active => list.where((m) => m['status'] == 'active').toList(),
      _MemberFilter.withLoan => list.where((m) => _asDouble(m['loan_balance']) > 0).toList(),
      _ => list,
    };

    list.sort((a, b) {
      if (_sort == _MemberSort.savings) {
        return _asDouble(b['savings_balance']).compareTo(_asDouble(a['savings_balance']));
      }
      final na = '${a['first_name']} ${a['last_name']}';
      final nb = '${b['first_name']} ${b['last_name']}';
      return na.compareTo(nb);
    });

    return list;
  }

  int get _activeCount => _members.where((m) => m['status'] == 'active').length;

  double get _totalSavings => _members.fold(0, (s, m) => s + _asDouble(m['savings_balance']));

  void _showMemberDetail(Map<String, dynamic> member) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberDetailSheet(member: member, onClose: () => Navigator.pop(ctx)),
    );
  }

  Future<void> _showAddMember() async {
    final session = ref.read(authSessionProvider);
    final inSetup = session?.needsGovernanceSetup == true;
    final canManage = session?.canManageMembers == true || inSetup;

    if (!canManage) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.governancePermissionHint)),
      );
      return;
    }

    var activeSession = session;
    if (inSetup && activeSession != null && !activeSession.hasPermission('group.manage_members')) {
      try {
        final me = await ref.read(apiClientProvider).get('/auth/me');
        final refreshed = AuthSession.fromProfile(me.data as Map<String, dynamic>);
        await ref.read(authSessionProvider.notifier).setSession(refreshed);
        activeSession = refreshed;
      } catch (_) {}
    }

    if (!mounted || activeSession?.groupId == null) return;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberSheet(groupId: activeSession!.groupId!),
    );

    if (added == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.memberAdded), backgroundColor: AppColors.savings),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final canManage = session?.canManageMembers == true;
    final currency = NumberFormat.currency(locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);
    final filtered = _filteredMembers;

    if (_loading) {
      return Scaffold(
        body: GlassScreenBackground(
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddMember();
              },
              elevation: 6,
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                l10n.addMember,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: GlassScreenBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          color: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _MembersHeader(
                  l10n: l10n,
                  showBack: context.canPop(),
                  onBack: () => context.pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          icon: Icons.people_outline,
                          label: l10n.activeMembers,
                          value: '$_activeCount/${_members.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.savings_outlined,
                          label: l10n.totalGroupSavings,
                          value: currency.format(_totalSavings),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _GlassSearchField(
                    controller: _searchController,
                    hint: l10n.searchMembersHint,
                    onClear: () {
                      _searchController.clear();
                      HapticFeedback.selectionClick();
                    },
                    showClear: _searchQuery.isNotEmpty,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: l10n.filterAll,
                              selected: _filter == _MemberFilter.all,
                              onTap: () => setState(() => _filter = _MemberFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: l10n.filterActive,
                              selected: _filter == _MemberFilter.active,
                              onTap: () => setState(() => _filter = _MemberFilter.active),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: l10n.filterWithLoan,
                              selected: _filter == _MemberFilter.withLoan,
                              onTap: () => setState(() => _filter = _MemberFilter.withLoan),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortButton(
                      sortName: l10n.sortByName,
                      sortSavings: l10n.sortBySavings,
                      current: _sort,
                      onChanged: (s) => setState(() => _sort = s),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    blur: 12,
                    opacity: 0.5,
                    child: Column(
                      children: [
                        Icon(Icons.person_search, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noMembersFound,
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    return _MemberCard(
                      member: m,
                      index: i,
                      currency: currency,
                      l10n: l10n,
                      onTap: () => _showMemberDetail(m),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({
    required this.l10n,
    required this.showBack,
    required this.onBack,
  });

  final AppLocalizations l10n;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                if (showBack)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  )
                else
                  const SizedBox(width: 48),
                const Spacer(),
              ],
            ),
            GlassCard(
              blur: 14,
              opacity: 0.48,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.savings.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                    child: SvgPicture.asset(
                      NavIcons.groups,
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.members,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.membersSubtitle,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                        ),
                      ],
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

class _GlassSearchField extends StatelessWidget {
  const _GlassSearchField({
    required this.controller,
    required this.hint,
    required this.onClear,
    required this.showClear,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 10,
      opacity: 0.45,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
          suffixIcon: showClear
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade600, size: 20),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 12,
      opacity: 0.52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.savings.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.35),
          border: Border.all(
            color: selected ? AppColors.savings : Colors.white.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: selected ? AppColors.primary : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sortName,
    required this.sortSavings,
    required this.current,
    required this.onChanged,
  });

  final String sortName;
  final String sortSavings;
  final _MemberSort current;
  final ValueChanged<_MemberSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MemberSort>(
      initialValue: current,
      onSelected: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      icon: GlassCard(
        blur: 8,
        opacity: 0.5,
        padding: const EdgeInsets.all(10),
        borderRadius: 12,
        child: const Icon(Icons.sort_rounded, color: AppColors.primary, size: 20),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(value: _MemberSort.name, child: Text(sortName)),
        PopupMenuItem(value: _MemberSort.savings, child: Text(sortSavings)),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.index,
    required this.currency,
    required this.l10n,
    required this.onTap,
  });

  final Map<String, dynamic> member;
  final int index;
  final NumberFormat currency;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
    final displayName = name.isEmpty ? l10n.memberLabel(index + 1) : name;
    final shares = _asInt(member['total_shares']);
    final savings = _asDouble(member['savings_balance']);
    final loan = _asDouble(member['loan_balance']);
    final isActive = member['status'] == 'active';
    final memberNo = member['member_number']?.toString() ?? '${index + 1}';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      blur: 12,
      opacity: 0.55,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.savings.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.savings.withValues(alpha: 0.15)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? l10n.statusActive : l10n.statusInactive,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.savings : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.memberIdLabel(memberNo),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.sharesAndSavings(shares, currency.format(savings)),
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (loan > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.loanBalance}: ${currency.format(loan)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.pending, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
    );
  }
}

class _MemberDetailSheet extends StatelessWidget {
  const _MemberDetailSheet({required this.member, required this.onClose});

  final Map<String, dynamic> member;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);
    final name = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
    final phone = member['phone_number']?.toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.memberDetails, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.savings.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28, color: AppColors.savings, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (member['member_number'] != null)
              Text(
                l10n.memberIdLabel(member['member_number'].toString()),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            const SizedBox(height: 20),
            _DetailRow(label: l10n.shares, value: '${_asInt(member['total_shares'])}'),
            _DetailRow(label: l10n.totalSavings, value: currency.format(_asDouble(member['savings_balance']))),
            _DetailRow(
              label: l10n.loanBalance,
              value: currency.format(_asDouble(member['loan_balance'])),
              highlight: _asDouble(member['loan_balance']) > 0,
            ),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // tel: launch can be added with url_launcher; show snackbar for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(phone)),
                  );
                },
                icon: const Icon(Icons.phone),
                label: Text(l10n.callMember),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: onClose, child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.pending : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet({required this.groupId});

  final int groupId;

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final res = await ref.read(apiClientProvider).post('/groups/${widget.groupId}/members', data: {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone_number': _phone.text.trim(),
      });
      HapticFeedback.mediumImpact();
      if (!mounted) return;

      final tempPin = res.data['temporary_pin']?.toString();
      final memberName =
          '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();

      if (tempPin != null && tempPin.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.temporaryPinTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.temporaryPinMessage(memberName)),
                const SizedBox(height: 16),
                SelectableText(
                  context.l10n.temporaryPinValue(tempPin),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.temporaryPinDevHint,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.finish),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.memberActivationLogin),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.failed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scroll) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    Colors.white.withValues(alpha: 0.88),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                ),
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.savings.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.addMember,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            Text(
                              l10n.governanceStep1,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _GlassMemberField(
                          controller: _firstName,
                          focusNode: _firstNameFocus,
                          label: l10n.firstName,
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _lastNameFocus.requestFocus(),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                        ),
                        const SizedBox(height: 12),
                        _GlassMemberField(
                          controller: _lastName,
                          focusNode: _lastNameFocus,
                          label: l10n.lastName,
                          icon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _phoneFocus.requestFocus(),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                        ),
                        const SizedBox(height: 12),
                        _GlassMemberField(
                          controller: _phone,
                          focusNode: _phoneFocus,
                          label: l10n.phoneNumber,
                          hint: '0712 345 678',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitting ? null : _submit(),
                          validator: (v) =>
                              (v == null || v.trim().length < 9) ? l10n.fieldRequired : null,
                        ),
                        const SizedBox(height: 24),
                        _MembersPrimaryButton(
                          label: l10n.save,
                          loading: _submitting,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMemberField extends StatefulWidget {
  const _GlassMemberField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.validator,
    this.icon,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  State<_GlassMemberField> createState() => _GlassMemberFieldState();
}

class _GlassMemberFieldState extends State<_GlassMemberField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.savings : Colors.grey.shade300,
          width: focused ? 2 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.savings.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade900),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: focused ? AppColors.savings : Colors.grey.shade600)
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _MembersPrimaryButton extends StatelessWidget {
  const _MembersPrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
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
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            height: 52,
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
