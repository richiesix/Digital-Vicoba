import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

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
  if (value is String) return int.tryParse(value) ?? _asDouble(value, fallback.toDouble()).toInt();
  return fallback;
}

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  final _amountController = TextEditingController();

  String _fundType = 'savings';
  String _paymentMethod = 'cash';
  String _mode = 'contribute';
  int _shareQuantity = 1;
  int? _selectedMemberId;
  double _sharePrice = 5000;
  double _savingsBalance = 0;
  double _emergencyBalance = 0;
  double _socialBalance = 0;
  int _totalShares = 0;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _recent = [];
  bool _loading = true;
  bool _submitting = false;

  static const _quickAmounts = [5000, 10000, 25000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
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

    final api = ref.read(apiClientProvider);
    try {
      final dash = await api.get('/dashboard', queryParameters: {'group_id': groupId});
      final w = dash.data['widgets'] as Map<String, dynamic>?;

      if (session?.isTreasurer == true) {
        _savingsBalance = _asDouble(w?['savings_total']);
        _emergencyBalance = _asDouble(w?['emergency_fund']);
        _socialBalance = _asDouble(w?['social_fund']);
      } else {
        _savingsBalance = _asDouble(w?['current_savings']);
        _totalShares = _asInt(w?['total_shares']);
      }

      final membersRes = await api.get('/groups/$groupId/members');
      final mData = membersRes.data['members'];
      final mList = (mData is Map && mData['data'] is List)
          ? mData['data'] as List
          : (mData is List ? mData : <dynamic>[]);
      _members = mList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _selectedMemberId ??= session?.memberId;

      final contribRes = await api.get('/groups/$groupId/contributions');
      final cData = contribRes.data['contributions'];
      final cList = (cData is Map && cData['data'] is List)
          ? cData['data'] as List
          : (cData is List ? cData : <dynamic>[]);
      _recent = cList.take(5).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final groupRes = await api.get('/groups/$groupId');
      final group = groupRes.data['group'] as Map<String, dynamic>?;
      _sharePrice = _asDouble(group?['share_price'], 5000);
    } catch (_) {
      // keep defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _amount => double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  double get _shareTotal => _shareQuantity * _sharePrice;

  Color get _fundColor => switch (_fundType) {
        'emergency' => AppColors.pending,
        'social' => const Color(0xFF1565C0),
        _ => AppColors.savings,
      };

  IconData get _fundIcon => switch (_fundType) {
        'emergency' => Icons.emergency,
        'social' => Icons.favorite,
        _ => Icons.savings,
      };

  bool get _canSubmit {
    if (_submitting) return false;
    if (_mode == 'shares') return _shareQuantity >= 1;
    return _amount >= 1;
  }

  void _selectQuickAmount(int value) {
    _amountController.text = value.toString();
    HapticFeedback.lightImpact();
  }

  Future<void> _submit(AuthSession session) async {
    final l10n = context.l10n;
    final groupId = session.groupId;
    final memberId = session.isTreasurer ? _selectedMemberId : session.memberId;
    if (groupId == null || memberId == null || !_canSubmit) return;

    setState(() => _submitting = true);
    final api = ref.read(apiClientProvider);

    try {
      if (_mode == 'shares') {
        await api.post('/groups/$groupId/shares', data: {
          'member_id': memberId,
          'quantity': _shareQuantity,
          'payment_method': _paymentMethod,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sharesPurchased), backgroundColor: AppColors.savings),
        );
      } else {
        await api.post('/groups/$groupId/contributions', data: {
          'member_id': memberId,
          'amount': _amount,
          'type': _fundType,
          'payment_method': _paymentMethod,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contributionSaved), backgroundColor: AppColors.savings),
        );
      }
      _amountController.clear();
      setState(() => _shareQuantity = 1);
      await _load();
    } catch (e) {
      final sync = ref.read(syncServiceProvider);
      await sync.queueOperation(
        entityType: _mode == 'shares' ? 'share' : 'contribution',
        operation: 'create',
        payload: {
          'group_id': groupId,
          'member_id': memberId,
          'amount': _mode == 'shares' ? _shareTotal : _amount,
          'type': _fundType,
          'quantity': _shareQuantity,
          'payment_method': _paymentMethod,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedWillSync)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final isTreasurer = session?.isTreasurer ?? false;
    final localeCode = ref.watch(localeProvider).languageCode;
    final currency = NumberFormat.currency(
      locale: localeCode == 'en' ? 'en_TZ' : 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _SavingsHeader(
            title: isTreasurer ? l10n.savingsManagement : l10n.savingsAndShares,
            isTreasurer: isTreasurer,
            savings: currency.format(_savingsBalance),
            emergency: isTreasurer ? currency.format(_emergencyBalance) : null,
            social: isTreasurer ? currency.format(_socialBalance) : null,
            shares: !isTreasurer ? '$_totalShares' : null,
            l10n: l10n,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (isTreasurer) ...[
                  Text(l10n.recordForMember, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _MemberDropdown(
                    members: _members,
                    selectedId: _selectedMemberId,
                    onChanged: (id) => setState(() => _selectedMemberId = id),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 16),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: _ModeChip(
                          label: l10n.contributeTab,
                          icon: Icons.volunteer_activism,
                          selected: _mode == 'contribute',
                          color: AppColors.savings,
                          onTap: () => setState(() => _mode = 'contribute'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeChip(
                          label: l10n.buySharesTab,
                          icon: Icons.pie_chart,
                          selected: _mode == 'shares',
                          color: AppColors.primary,
                          onTap: () => setState(() => _mode = 'shares'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (_mode == 'contribute' || isTreasurer) ...[
                  Text(l10n.yourBalances, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _FundTypeCard(
                        label: l10n.typeSavings,
                        icon: Icons.savings,
                        color: AppColors.savings,
                        selected: _fundType == 'savings',
                        onTap: () => setState(() => _fundType = 'savings'),
                      ),
                      const SizedBox(width: 8),
                      _FundTypeCard(
                        label: l10n.typeEmergency,
                        icon: Icons.emergency,
                        color: AppColors.pending,
                        selected: _fundType == 'emergency',
                        onTap: () => setState(() => _fundType = 'emergency'),
                      ),
                      const SizedBox(width: 8),
                      _FundTypeCard(
                        label: l10n.typeSocial,
                        icon: Icons.favorite,
                        color: const Color(0xFF1565C0),
                        selected: _fundType == 'social',
                        onTap: () => setState(() => _fundType = 'social'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.quickAmounts, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickAmounts.map((a) {
                      final sel = _amount == a.toDouble();
                      return FilterChip(
                        label: Text(currency.format(a)),
                        selected: sel,
                        onSelected: (_) => _selectQuickAmount(a),
                        selectedColor: _fundColor.withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: isTreasurer ? l10n.amountReceived : l10n.amountTzs,
                      prefixIcon: Icon(Icons.payments, color: _fundColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  Card(
                    color: _fundColor.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.sharePriceEach(currency.format(_sharePrice))),
                          const SizedBox(height: 16),
                          Text(l10n.shareQuantity, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton.filled(
                                onPressed: _shareQuantity > 1
                                    ? () => setState(() => _shareQuantity--)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Expanded(
                                child: Text(
                                  '$_shareQuantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton.filled(
                                onPressed: () => setState(() => _shareQuantity++),
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(backgroundColor: AppColors.savings),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.totalPayable, style: TextStyle(color: Colors.grey.shade700)),
                              Text(
                                currency.format(_shareTotal),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _fundColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(l10n.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _PaymentGrid(
                  selected: _paymentMethod,
                  onSelect: (m) {
                    setState(() => _paymentMethod = m);
                    HapticFeedback.selectionClick();
                  },
                  l10n: l10n,
                ),
                if (isTreasurer)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l10n.treasurerHint, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(l10n.recentActivity, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 10),
                if (_recent.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text(l10n.noRecentActivity)),
                    ),
                  )
                else
                  ..._recent.map((c) => _ActivityTile(item: c, currency: currency, l10n: l10n)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _canSubmit && session != null ? () => _submit(session) : null,
            icon: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(_mode == 'shares' ? Icons.pie_chart : _fundIcon),
            label: Text(
              isTreasurer
                  ? l10n.confirmAndRecord
                  : (_mode == 'shares' ? l10n.buySharesTab : l10n.contributeTab),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _fundColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsHeader extends StatelessWidget {
  const _SavingsHeader({
    required this.title,
    required this.isTreasurer,
    required this.savings,
    required this.l10n,
    this.emergency,
    this.social,
    this.shares,
  });

  final String title;
  final bool isTreasurer;
  final String savings;
  final String? emergency;
  final String? social;
  final String? shares;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.savings, color: Colors.white, size: 32),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: isTreasurer
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: _BalancePill(label: l10n.savings, value: savings),
                            ),
                            const SizedBox(width: 8),
                            if (emergency != null)
                              SizedBox(
                                width: 110,
                                child: _BalancePill(label: l10n.emergencyBalance, value: emergency!),
                              ),
                            const SizedBox(width: 8),
                            if (social != null)
                              SizedBox(
                                width: 110,
                                child: _BalancePill(label: l10n.socialBalance, value: social!),
                              ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _BalancePill(label: l10n.mySavings, value: savings, large: true),
                          ),
                          if (shares != null) ...[
                            const SizedBox(width: 12),
                            _BalancePill(label: l10n.shares, value: shares!, large: true),
                          ],
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

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.label, required this.value, this.large = false});

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: large ? 18 : 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
  }
}

class _FundTypeCard extends StatelessWidget {
  const _FundTypeCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: selected ? 3 : 0,
        child: InkWell(
          onTap: () {
            onTap();
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: selected ? Colors.white : color, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentGrid extends StatelessWidget {
  const _PaymentGrid({
    required this.selected,
    required this.onSelect,
    required this.l10n,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final dynamic l10n;

  static const _methods = [
    ('cash', Icons.payments, Color(0xFF5D4037)),
    ('mpesa', Icons.phone_android, Color(0xFFE53935)),
    ('airtel', Icons.sim_card, Color(0xFFD32F2F)),
    ('mixx', Icons.account_balance_wallet, Color(0xFF00897B)),
    ('halopesa', Icons.mobile_friendly, Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: _methods.map((m) {
        final isSel = selected == m.$1;
        return Material(
          color: isSel ? m.$3.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onSelect(m.$1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? m.$3 : Colors.grey.shade300,
                  width: isSel ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(m.$2, color: m.$3, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    m.$1 == 'cash' ? l10n.cash : m.$1.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MemberDropdown extends StatelessWidget {
  const _MemberDropdown({
    required this.members,
    required this.selectedId,
    required this.onChanged,
    required this.l10n,
  });

  final List<Map<String, dynamic>> members;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: l10n.selectMember,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: members.map((m) {
        final id = m['id'] as int;
        final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
        return DropdownMenuItem(
          value: id,
          child: Text(name.isEmpty ? l10n.memberLabel(id) : name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.currency,
    required this.l10n,
  });

  final Map<String, dynamic> item;
  final NumberFormat currency;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String? ?? 'savings';
    final amount = _asDouble(item['amount']);
    final color = switch (type) {
      'emergency' => AppColors.pending,
      'social' => const Color(0xFF1565C0),
      _ => AppColors.savings,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.receipt, color: color),
        ),
        title: Text(currency.format(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(type),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
