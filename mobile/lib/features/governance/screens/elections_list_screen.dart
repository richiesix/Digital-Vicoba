import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import 'governance_dashboard_screen.dart';

class ElectionsListScreen extends ConsumerStatefulWidget {
  const ElectionsListScreen({super.key});

  @override
  ConsumerState<ElectionsListScreen> createState() => _ElectionsListScreenState();
}

class _ElectionsListScreenState extends ConsumerState<ElectionsListScreen> {
  List<dynamic> _elections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groupId = ref.read(authSessionProvider)?.groupId;
    if (groupId == null) return;

    setState(() => _loading = true);
    try {
      final list = await ref.read(governanceRepositoryProvider).fetchElections(groupId);
      if (mounted) {
        setState(() {
          _elections = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.elections),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _elections.length,
                itemBuilder: (context, index) {
                  final e = _elections[index] as Map<String, dynamic>;
                  final id = e['id'] as int;
                  return Card(
                    child: ListTile(
                      title: Text(e['title'] as String? ?? ''),
                      subtitle: Text('${e['status']} · ${e['election_type'] ?? ''}'),
                      onTap: () => context.push('${AppRoutes.governanceElectionDetail}/$id'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
