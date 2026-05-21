import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/permission_gate.dart';

class ShareOutScreen extends ConsumerWidget {
  const ShareOutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareOutTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppColors.savings.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(l10n.poolTotal, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text(
                      'TZS 5,250,000',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.savings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.multiSignRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            PermissionGate(
              permission: 'group.share_out_verify',
              fallback: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.shareOutLeaderOnly, textAlign: TextAlign.center),
                ),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calculate),
                    label: Text(l10n.calculateShareOut),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check),
                    label: Text(l10n.approveShareOut),
                  ),
                ],
              ),
            ),
            PermissionGate(
              permission: 'group.approve_treasury',
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payments),
                  label: Text(l10n.payShareOut),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
