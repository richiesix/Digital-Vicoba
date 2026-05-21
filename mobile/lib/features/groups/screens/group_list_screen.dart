import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
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

enum _GroupFilter { all, active, forming }

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _groups = [];
  _GroupFilter _filter = _GroupFilter.all;
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
    try {
      final res = await ref.read(apiClientProvider).get('/groups');
      final data = res.data;
      final list = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : <dynamic>[]);
      setState(() {
        _groups = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredGroups {
    var list = List<Map<String, dynamic>>.from(_groups);

    if (_searchQuery.isNotEmpty) {
      list = list.where((g) {
        final name = (g['name'] ?? '').toString().toLowerCase();
        final ward = (g['ward'] ?? '').toString().toLowerCase();
        final village = (g['village'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || ward.contains(_searchQuery) || village.contains(_searchQuery);
      }).toList();
    }

    return switch (_filter) {
      _GroupFilter.active => list.where((g) => g['status'] == 'active').toList(),
      _GroupFilter.forming => list.where((g) => g['status'] == 'forming').toList(),
      _ => list,
    };
  }

  int get _activeCount => _groups.where((g) => g['status'] == 'active').length;

  String _statusLabel(AppLocalizations l10n, String? status) => switch (status) {
        'forming' => l10n.groupStatusForming,
        'active' => l10n.groupStatusActive,
        'share_out' => l10n.groupStatusShareOut,
        'dormant' => l10n.groupStatusDormant,
        'closed' => l10n.groupStatusClosed,
        _ => status ?? '—',
      };

  Color _statusColor(String? status) => switch (status) {
        'active' => AppColors.savings,
        'forming' => AppColors.pending,
        'share_out' => const Color(0xFF1565C0),
        'dormant' => Colors.grey,
        'closed' => AppColors.overdue,
        _ => Colors.grey,
      };

  void _showGroupDetail(Map<String, dynamic> group) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GroupDetailSheet(
        group: group,
        statusLabel: _statusLabel(context.l10n, group['status'] as String?),
        statusColor: _statusColor(group['status'] as String?),
        onMembers: () {
          Navigator.pop(ctx);
          context.push(AppRoutes.members);
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _showCreateGroup() async {
    final session = ref.read(authSessionProvider);
    if (!(session?.hasPermission('platform.manage_groups') ?? false)) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateGroupSheet(),
    );

    if (created == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupCreated), backgroundColor: AppColors.savings),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final canCreate = session?.hasPermission('platform.manage_groups') ?? false;
    final currency = NumberFormat.currency(locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);
    final filtered = _filteredGroups;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreateGroup,
              backgroundColor: AppColors.savings,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, color: Colors.white, size: 26),
              label: Text(
                l10n.createGroup,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _GroupsHeader(l10n: l10n, onBack: () => context.pop()),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.groups,
                        label: l10n.totalGroups,
                        value: '${_groups.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.check_circle_outline,
                        label: l10n.activeGroupsLabel,
                        value: '$_activeCount',
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
                    hintText: l10n.searchGroupsHint,
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: l10n.filterAll,
                        selected: _filter == _GroupFilter.all,
                        onTap: () => setState(() => _filter = _GroupFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.statusActive,
                        selected: _filter == _GroupFilter.active,
                        onTap: () => setState(() => _filter = _GroupFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.filterForming,
                        selected: _filter == _GroupFilter.forming,
                        onTap: () => setState(() => _filter = _GroupFilter.forming),
                      ),
                    ],
                  ),
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
                        Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(l10n.noGroupsFound, style: TextStyle(color: Colors.grey.shade600)),
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
                    final g = filtered[i];
                    return _GroupCard(
                      group: g,
                      l10n: l10n,
                      currency: currency,
                      statusLabel: _statusLabel(l10n, g['status'] as String?),
                      statusColor: _statusColor(g['status'] as String?),
                      onTap: () => _showGroupDetail(g),
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

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({required this.l10n, required this.onBack});

  final AppLocalizations l10n;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF33691E)],
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
                            l10n.myGroups,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.groupsSubtitle,
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.l10n,
    required this.currency,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  final Map<String, dynamic> group;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = group['name'] as String? ?? '—';
    final members = _asInt(group['members_count']);
    final sharePrice = _asDouble(group['share_price']);
    final location = [group['ward'], group['village']].where((e) => e != null && '$e'.isNotEmpty).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.2),
                      AppColors.savings.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(
                  NavIcons.groups,
                  width: 28,
                  height: 28,
                  fit: BoxFit.scaleDown,
                  colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
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
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.membersCount(members), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.sharePriceLabel}: ${currency.format(sharePrice)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.place, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupDetailSheet extends ConsumerWidget {
  const _GroupDetailSheet({
    required this.group,
    required this.statusLabel,
    required this.statusColor,
    required this.onMembers,
    required this.onClose,
  });

  final Map<String, dynamic> group;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onMembers;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);
    final session = ref.watch(authSessionProvider);
    final canManageMembers = session?.hasPermission('group.manage_members') ?? false;
    final name = group['name'] as String? ?? '—';
    final members = _asInt(group['members_count']);
    final sharePrice = currency.format(_asDouble(group['share_price']));
    final interest = _asDouble(group['loan_interest_rate']);
    final meetingFreq = group['meeting_frequency']?.toString();
    final location = [group['ward'], group['village']].where((e) => e != null && '$e'.isNotEmpty).join(', ');

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.groupDetails,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -36,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        child: SvgPicture.asset(
                          NavIcons.groups,
                          width: 40,
                          height: 40,
                          colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.people,
                      label: l10n.members,
                      value: '$members',
                      color: AppColors.savings,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.savings_outlined,
                      label: l10n.sharePriceLabel,
                      value: sharePrice.replaceAll('TZS ', ''),
                      color: const Color(0xFF1565C0),
                      prefix: 'TZS ',
                    ),
                  ),
                  if (interest > 0) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.percent,
                        label: l10n.interestRateLabel,
                        value: '${interest.toStringAsFixed(0)}%',
                        color: AppColors.pending,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.groups,
                        iconColor: AppColors.savings,
                        label: l10n.members,
                        value: l10n.membersCount(members),
                        onTap: canManageMembers ? onMembers : null,
                        trailing: canManageMembers ? const Icon(Icons.chevron_right) : null,
                      ),
                      const Divider(height: 1, indent: 56),
                      _InfoTile(
                        icon: Icons.payments_outlined,
                        iconColor: const Color(0xFF1565C0),
                        label: l10n.sharePriceLabel,
                        value: sharePrice,
                      ),
                      if (interest > 0) ...[
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.trending_up,
                          iconColor: AppColors.pending,
                          label: l10n.interestRateLabel,
                          value: '${interest.toStringAsFixed(1)}%',
                        ),
                      ],
                      if (meetingFreq != null && meetingFreq.isNotEmpty) ...[
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.event,
                          iconColor: AppColors.primary,
                          label: l10n.meetingFrequencyLabel,
                          value: meetingFreq,
                        ),
                      ],
                      if (location.isNotEmpty) ...[
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.place,
                          iconColor: Colors.grey.shade700,
                          label: l10n.locationLabel,
                          value: location,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                children: [
                  if (canManageMembers)
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onMembers();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        l10n.viewMembers,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.savings,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onClose,
                    child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade700)),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.prefix,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                children: [
                  if (prefix != null) TextSpan(text: prefix, style: TextStyle(fontSize: 10, color: color)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sharePrice = TextEditingController(text: '5000');
  final _ward = TextEditingController();
  final _village = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _sharePrice.dispose();
    _ward.dispose();
    _village.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/groups', data: {
        'name': _name.text.trim(),
        'share_price': _asDouble(_sharePrice.text),
        if (_ward.text.trim().isNotEmpty) 'ward': _ward.text.trim(),
        if (_village.text.trim().isNotEmpty) 'village': _village.text.trim(),
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
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
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
              Text(l10n.createGroup, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.groupName),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sharePrice,
                      decoration: InputDecoration(labelText: l10n.sharePriceLabel),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (_asDouble(v) <= 0) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ward,
                      decoration: InputDecoration(labelText: l10n.wardLabel),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _village,
                      decoration: InputDecoration(labelText: l10n.villageLabel),
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
