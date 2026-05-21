import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/reports/report_download.dart';
import '../../../core/reports/report_storage_service.dart';
import '../../../core/theme/app_theme.dart';

class ReportViewerScreen extends StatelessWidget {
  const ReportViewerScreen({super.key, required this.report});

  final SavedReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = DateTime.tryParse(report.generatedAt);
    final dateStr = date != null ? DateFormat('d MMM yyyy, HH:mm').format(date.toLocal()) : report.generatedAt;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(report.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.downloadReport,
            onPressed: () {
              HapticFeedback.lightImpact();
              final csv = _buildCsv();
              triggerCsvDownload(report.filename, csv);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(kIsWeb ? l10n.reportDownloadBrowser : l10n.downloadReport),
                  backgroundColor: AppColors.savings,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.groupName != null)
                    Text(report.groupName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(dateStr, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: report.summary.entries.map((e) {
                      return Chip(
                        label: Text('${e.key}: ${e.value}'),
                        backgroundColor: AppColors.savings.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.reports, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.savings.withValues(alpha: 0.12)),
                columns: report.columns
                    .map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))))
                    .toList(),
                rows: report.rows
                    .map(
                      (row) => DataRow(
                        cells: row.map((cell) => DataCell(Text(cell))).toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (report.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.noMembersFound, style: TextStyle(color: Colors.grey.shade600))),
            ),
        ],
      ),
    );
  }

  String _buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln(report.columns.join(','));
    for (final row in report.rows) {
      buffer.writeln(row.join(','));
    }
    return buffer.toString();
  }
}
