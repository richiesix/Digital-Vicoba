import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_screen_background.dart';
import 'governance_dashboard_screen.dart';

class AssignLeadershipScreen extends ConsumerStatefulWidget {
  const AssignLeadershipScreen({super.key});

  @override
  ConsumerState<AssignLeadershipScreen> createState() => _AssignLeadershipScreenState();
}

class _AssignLeadershipScreenState extends ConsumerState<AssignLeadershipScreen> {
  String _role = 'chairperson';
  int? _selectedMemberId;
  final _reasonController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;
  bool _saving = false;

  static const _roles = [
    'chairperson',
    'secretary',
    'treasurer',
    'money_counter',
    'key_holder',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final groupId = ref.read(authSessionProvider)?.groupId;
    if (groupId == null) {
      setState(() => _loadingMembers = false);
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
        _loadingMembers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  String _roleLabel(String role) {
    final l10n = context.l10n;
    return switch (role) {
      'chairperson' => l10n.roleChairperson,
      'secretary' => l10n.roleSecretary,
      'treasurer' => l10n.roleTreasurer,
      'money_counter' => l10n.roleMoneyCounter,
      'key_holder' => l10n.roleKeyHolder,
      _ => role,
    };
  }

  Future<void> _submit() async {
    final groupId = ref.read(authSessionProvider)?.groupId;
    if (groupId == null || _selectedMemberId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(governanceRepositoryProvider).proposeAssignment(groupId, {
        'member_id': _selectedMemberId,
        'role_name': _role,
        'reason': _reasonController.text.trim(),
      });
      if (mounted) {
        final inSetup = ref.read(authSessionProvider)?.needsGovernanceSetup == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inSetup ? context.l10n.leadershipAssigned : context.l10n.assignmentProposed,
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inSetup = ref.watch(authSessionProvider)?.needsGovernanceSetup == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.assignLeadership, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          const GlassScreenBackground(),
          SafeArea(
            child: _loadingMembers
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      blur: 16,
                      opacity: 0.58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            inSetup ? l10n.assignLeadershipSetupHint : l10n.manualAssignmentHint,
                            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            decoration: InputDecoration(labelText: l10n.role),
                            items: _roles
                                .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                                .toList(),
                            onChanged: (v) => setState(() => _role = v ?? _role),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedMemberId,
                            decoration: InputDecoration(labelText: l10n.selectMember),
                            items: _members
                                .map((m) {
                                  final id = m['id'] as int;
                                  final name =
                                      '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
                                  return DropdownMenuItem(value: id, child: Text(name));
                                })
                                .toList(),
                            onChanged: (v) => setState(() => _selectedMemberId = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reasonController,
                            decoration: InputDecoration(labelText: l10n.reason),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _saving || _selectedMemberId == null ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(inSetup ? l10n.assignRole : l10n.submitForApproval),
                          ),
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
