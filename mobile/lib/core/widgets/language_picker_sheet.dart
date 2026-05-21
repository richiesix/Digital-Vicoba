import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_extension.dart';
import '../providers/app_providers.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider).languageCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.languageSettings,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chooseLanguage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _LanguageTile(
              code: 'sw',
              label: l10n.swahili,
              subtitle: 'Kiswahili',
              selected: current == 'sw',
              onSelect: () => _select(ref, context, 'sw'),
            ),
            _LanguageTile(
              code: 'en',
              label: l10n.english,
              subtitle: 'English',
              selected: current == 'en',
              onSelect: () => _select(ref, context, 'en'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, BuildContext context, String code) async {
    await ref.read(localeProvider.notifier).setLocale(code);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.languageChanged)),
      );
    }
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
  });

  final String code;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(code.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
        onTap: onSelect,
      ),
    );
  }
}
