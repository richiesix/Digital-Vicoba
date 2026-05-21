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
    _load();
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
    if (!(session?.hasPermission('group.manage_members') ?? false)) return;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberSheet(groupId: session!.groupId!),
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
    final canManage = session?.hasPermission('group.manage_members') ?? false;
    final currency = NumberFormat.currency(locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);
    final filtered = _filteredMembers;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddMember,
              backgroundColor: AppColors.savings,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, color: Colors.white, size: 26),
              label: Text(
                l10n.addMember,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _MembersHeader(l10n: l10n, onBack: () => context.pop())),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.people,
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchMembersHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              HapticFeedback.selectionClick();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
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
                child: SizedBox(
                  height: 280,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(l10n.noMembersFound, style: TextStyle(color: Colors.grey.shade600)),
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
    );
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({required this.l10n, required this.onBack});

  final AppLocalizations l10n;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      NavIcons.groups,
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.members,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.membersSubtitle,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.savings, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      selectedColor: AppColors.savings.withValues(alpha: 0.2),
      checkmarkColor: AppColors.savings,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.savings : null,
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
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.sort, color: AppColors.savings),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.savings.withValues(alpha: 0.15),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.savings,
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
              const Icon(Icons.chevron_right, color: AppColors.savings),
            ],
          ),
        ),
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
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/groups/${widget.groupId}/members', data: {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone_number': _phone.text.trim(),
      });
      HapticFeedback.mediumImpact();
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
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scroll,
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
              Text(l10n.addMember, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstName,
                      decoration: InputDecoration(labelText: l10n.firstName),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastName,
                      decoration: InputDecoration(labelText: l10n.lastName),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      decoration: InputDecoration(labelText: l10n.phoneNumber),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().length < 9) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.savings,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.save),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
