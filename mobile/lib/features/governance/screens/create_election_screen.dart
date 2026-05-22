import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_screen_background.dart';
import 'governance_dashboard_screen.dart';

class CreateElectionScreen extends ConsumerStatefulWidget {
  const CreateElectionScreen({super.key});

  @override
  ConsumerState<CreateElectionScreen> createState() => _CreateElectionScreenState();
}

class _CreateElectionScreenState extends ConsumerState<CreateElectionScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _quorum = 50;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final groupId = ref.read(authSessionProvider)?.groupId;
    if (groupId == null) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await ref.read(governanceRepositoryProvider).createElection(groupId, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'election_type': 'leadership',
        'quorum_percent': _quorum,
        'start_date': now.toIso8601String(),
        'end_date': now.add(const Duration(days: 7)).toIso8601String(),
        'positions': ['chairperson', 'secretary', 'treasurer', 'money_counter', 'key_holder'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.electionCreated)),
        );
        context.pop();
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.createElection, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          const GlassScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                blur: 16,
                opacity: 0.58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: l10n.electionTitle),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: l10n.description),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text('${l10n.quorumPercent}: $_quorum%'),
                    Slider(
                      value: _quorum.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 9,
                      label: '$_quorum%',
                      onChanged: (v) => setState(() => _quorum = v.round()),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
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
                          : Text(l10n.save),
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
