import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class LoanApplicationScreen extends ConsumerStatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  ConsumerState<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends ConsumerState<LoanApplicationScreen> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _amountFocus = FocusNode();

  int _termWeeks = 12;
  double _maxEligible = 500000;
  double _shareValue = 0;
  final Set<int> _selectedGuarantors = {};
  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;
  bool _submitting = false;

  static const _quickAmounts = [50000, 100000, 200000, 500000];
  static const _termOptions = [4, 8, 12, 24];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadContext();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  Future<void> _loadContext() async {
    final session = ref.read(authSessionProvider);
    final groupId = session?.groupId;
    if (groupId == null) {
      setState(() => _loadingMembers = false);
      return;
    }

    final api = ref.read(apiClientProvider);
    try {
      final dash = await api.get('/dashboard', queryParameters: {'group_id': groupId});
      final widgets = dash.data['widgets'] as Map<String, dynamic>?;
      final shares = (widgets?['total_shares'] as num?)?.toInt() ?? 0;
      _shareValue = shares * 5000.0;
      _maxEligible = _shareValue * 3;
      if (_maxEligible < 100000) _maxEligible = 500000;

      final membersRes = await api.get('/groups/$groupId/members');
      final data = membersRes.data['members'];
      final list = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : <dynamic>[]);

      final myId = session?.memberId;
      final members = <Map<String, dynamic>>[];
      for (final item in list) {
        final m = Map<String, dynamic>.from(item as Map);
        if (m['id'] != myId) members.add(m);
      }

      setState(() {
        _members = members;
        _loadingMembers = false;
      });
    } catch (_) {
      setState(() => _loadingMembers = false);
    }
  }

  double get _amount => double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  double get _weeklyRepayment {
    if (_amount <= 0) return 0;
    return (_amount * 1.1) / _termWeeks;
  }

  double get _eligibilityRatio =>
      _maxEligible > 0 ? (_amount / _maxEligible).clamp(0.0, 1.0) : 0;

  bool get _canSubmit =>
      _amount >= 1000 &&
      _amount <= _maxEligible &&
      _selectedGuarantors.isNotEmpty &&
      !_submitting;

  void _selectQuickAmount(int value) {
    _amountController.text = value.toString();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _toggleGuarantor(int id) {
    setState(() {
      if (_selectedGuarantors.contains(id)) {
        _selectedGuarantors.remove(id);
      } else {
        _selectedGuarantors.add(id);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    final session = ref.read(authSessionProvider);
    final groupId = session?.groupId;
    final memberId = session?.memberId;
    if (groupId == null || memberId == null) return;

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/groups/$groupId/loans', data: {
        'member_id': memberId,
        'principal_amount': _amount,
        'term_weeks': _termWeeks,
        'purpose': _purposeController.text.trim(),
        'guarantor_ids': _selectedGuarantors.toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loanSubmitted),
          backgroundColor: AppColors.savings,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.loanSubmitFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = ref.watch(localeProvider).languageCode;
    final currency = NumberFormat.currency(
      locale: localeCode == 'en' ? 'en_TZ' : 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _LoanHeader(
            title: l10n.applyLoan,
            maxLabel: l10n.maxEligible,
            maxValue: currency.format(_maxEligible),
            ratio: _eligibilityRatio,
            amount: _amount,
            currency: currency,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  l10n.quickAmounts,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _quickAmounts.map((a) {
                    final selected = _amount == a.toDouble();
                    return FilterChip(
                      label: Text(currency.format(a)),
                      selected: selected,
                      onSelected: (_) => _selectQuickAmount(a),
                      selectedColor: AppColors.pending.withValues(alpha: 0.25),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? AppColors.primary : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: l10n.loanAmountLabel,
                    prefixIcon: const Icon(Icons.payments, color: AppColors.pending),
                    suffixText: 'TZS',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.loanTermWeeks,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _termOptions.map((w) {
                    final selected = _termWeeks == w;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: w != _termOptions.last ? 8 : 0),
                        child: Material(
                          color: selected
                              ? AppColors.pending
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: selected ? 2 : 0,
                          child: InkWell(
                            onTap: () {
                              setState(() => _termWeeks = w);
                              HapticFeedback.selectionClick();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                l10n.weeksCount(w),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppColors.savings.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate, color: AppColors.savings),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.estimatedRepayment,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              Text(
                                currency.format(_weeklyRepayment),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.savings,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _purposeController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.loanPurposeLabel,
                    prefixIcon: const Icon(Icons.edit_note, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: AppColors.pending.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.pending, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.loanLimit,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(l10n.loanLimitHint, style: const TextStyle(fontSize: 13)),
                              if (_shareValue > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.yourSharesValue(currency.format(_shareValue)),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.selectGuarantors,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      l10n.guarantorsSelected(_selectedGuarantors.length),
                      style: TextStyle(color: AppColors.savings, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loadingMembers)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ))
                else if (_members.isEmpty)
                  Text(l10n.noGuarantorsAvailable, style: TextStyle(color: Colors.grey.shade600))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members.map((m) {
                      final id = m['id'] as int;
                      final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
                      final selected = _selectedGuarantors.contains(id);
                      return FilterChip(
                        avatar: CircleAvatar(
                          backgroundColor: selected
                              ? AppColors.savings
                              : Colors.grey.shade300,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        label: Text(name.isEmpty ? l10n.memberLabel(id) : name),
                        selected: selected,
                        onSelected: (_) => _toggleGuarantor(id),
                        selectedColor: AppColors.savings.withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.route, color: Colors.grey.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.approvalFlow,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pending,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(l10n.submitLoan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _LoanHeader extends StatelessWidget {
  const _LoanHeader({
    required this.title,
    required this.maxLabel,
    required this.maxValue,
    required this.ratio,
    required this.amount,
    required this.currency,
  });

  final String title;
  final String maxLabel;
  final String maxValue;
  final double ratio;
  final double amount;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final overLimit = ratio > 1.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF57F17), Color(0xFFF9A825)],
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
                  const Icon(Icons.request_quote, color: Colors.white, size: 32),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maxLabel,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                          Text(
                            maxValue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (amount > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(ratio * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: overLimit ? Colors.red.shade200 : Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: overLimit ? Colors.red.shade300 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
