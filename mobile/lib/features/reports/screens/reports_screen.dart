import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/reports/report_download.dart';
import '../../../core/reports/report_storage_service.dart';
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

class _ReportType {
  const _ReportType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) subtitle;
  final IconData icon;
  final Color color;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<String, dynamic>? _analytics;
  List<SavedReport> _downloaded = [];
  bool _loading = true;
  String? _generatingId;

  static final _reportTypes = [
    _ReportType(
      id: 'savings_growth',
      title: (l) => l.reportSavingsGrowth,
      subtitle: (l) => l.tapToGenerate,
      icon: Icons.trending_up,
      color: AppColors.savings,
    ),
    _ReportType(
      id: 'loan_performance',
      title: (l) => l.reportLoanPerformance,
      subtitle: (l) => l.tapToGenerate,
      icon: Icons.account_balance,
      color: const Color(0xFF1565C0),
    ),
    _ReportType(
      id: 'payment_trends',
      title: (l) => l.reportPaymentTrends,
      subtitle: (l) => l.tapToGenerate,
      icon: Icons.payment,
      color: const Color(0xFF6A1B9A),
    ),
    _ReportType(
      id: 'default_risk',
      title: (l) => l.reportDefaultRisk,
      subtitle: (l) => l.tapToGenerate,
      icon: Icons.warning_amber_rounded,
      color: AppColors.overdue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = ref.read(reportStorageProvider);
    _downloaded = await storage.listReports();

    final groupId = ref.read(authSessionProvider)?.groupId;
    if (groupId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await ref.read(apiClientProvider).get('/groups/$groupId/analytics');
      setState(() {
        _analytics = res.data as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateReport(_ReportType type) async {
    final groupId = ref.read(authSessionProvider)?.groupId;
    if (groupId == null) return;

    setState(() => _generatingId = type.id);
    HapticFeedback.lightImpact();

    try {
      final res = await ref.read(apiClientProvider).get('/groups/$groupId/reports/${type.id}');
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>?;
      final reportPayload = data?['report'] as Map<String, dynamic>?;
      if (reportPayload == null) return;

      final saved = await ref.read(reportStorageProvider).saveFromApi(reportPayload);
      _downloaded = await ref.read(reportStorageProvider).listReports();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {});
      _showReportResult(type, saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.failed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _generatingId = null);
    }
  }

  void _openReport(SavedReport report) {
    HapticFeedback.lightImpact();
    context.push(AppRoutes.reportView, extra: report);
  }

  void _downloadCsv(SavedReport report) {
    HapticFeedback.lightImpact();
    final buffer = StringBuffer();
    buffer.writeln(report.columns.join(','));
    for (final row in report.rows) {
      buffer.writeln(row.join(','));
    }
    triggerCsvDownload(report.filename, buffer.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb ? context.l10n.reportDownloadBrowser : context.l10n.downloadReport,
        ),
        backgroundColor: AppColors.savings,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showReportResult(_ReportType type, SavedReport saved) {
    final l10n = context.l10n;
    final date = DateTime.tryParse(saved.generatedAt);
    final dateStr = date != null ? DateFormat('d MMM yyyy, HH:mm').format(date.toLocal()) : '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: type.color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              saved.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l10n.reportSaved, style: TextStyle(color: Colors.grey.shade600)),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
            Text(
              l10n.reportRows(saved.rows.length),
              style: TextStyle(fontSize: 13, color: type.color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openReport(saved);
              },
              icon: const Icon(Icons.visibility, color: Colors.white),
              label: Text(
                l10n.viewReport,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: type.color,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _downloadCsv(saved);
              },
              icon: Icon(Icons.download, color: type.color),
              label: Text(l10n.downloadReport),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalSavings = _asDouble(_analytics?['total_savings']);
    final activeLoans = _asInt(_analytics?['active_loans']);
    final overdueLoans = _asInt(_analytics?['overdue_loans']);
    final memberCount = _asInt(_analytics?['member_count']);
    final insights = _analytics?['insights'] as Map<String, dynamic>?;
    final recommendation = insights?['recommendation'] as String?;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ReportsHeader(l10n: l10n),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnalyticsChip(
                        icon: Icons.savings_outlined,
                        label: l10n.totalSavings,
                        value: currency.format(totalSavings),
                        color: AppColors.savings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AnalyticsChip(
                        icon: Icons.people,
                        label: l10n.members,
                        value: '$memberCount',
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnalyticsChip(
                        icon: Icons.request_quote,
                        label: l10n.activeLoans,
                        value: '$activeLoans',
                        color: AppColors.pending,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AnalyticsChip(
                        icon: Icons.warning_amber,
                        label: l10n.overdue,
                        value: '$overdueLoans',
                        color: AppColors.overdue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (recommendation != null && recommendation.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    color: AppColors.savings.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, color: AppColors.savings),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.riskInsight,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.savings),
                                ),
                                const SizedBox(height: 4),
                                Text(recommendation),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  l10n.reports,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList.builder(
                itemCount: _reportTypes.length,
                itemBuilder: (context, i) {
                  final type = _reportTypes[i];
                  final isGenerating = _generatingId == type.id;
                  return _ReportCard(
                    type: type,
                    l10n: l10n,
                    isGenerating: isGenerating,
                    onTap: isGenerating ? null : () => _generateReport(type),
                  );
                },
              ),
            ),
            if (_downloaded.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.downloadedReports,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: _downloaded.length,
                  itemBuilder: (context, i) {
                    final saved = _downloaded[i];
                    final date = DateTime.tryParse(saved.generatedAt);
                    final dateStr = date != null
                        ? DateFormat('d MMM yyyy').format(date.toLocal())
                        : '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.savings.withValues(alpha: 0.15),
                          child: const Icon(Icons.description, color: AppColors.savings),
                        ),
                        title: Text(saved.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('$dateStr · ${l10n.reportRows(saved.rows.length)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () => _downloadCsv(saved),
                              tooltip: l10n.downloadReport,
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _openReport(saved),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              SvgPicture.asset(
                NavIcons.reports,
                width: 36,
                height: 36,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reports,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.reportsSubtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
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

class _AnalyticsChip extends StatelessWidget {
  const _AnalyticsChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

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
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.type,
    required this.l10n,
    required this.isGenerating,
    required this.onTap,
  });

  final _ReportType type;
  final AppLocalizations l10n;
  final bool isGenerating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      type.color.withValues(alpha: 0.25),
                      type.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(type.icon, color: type.color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title(l10n),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGenerating ? l10n.generatingReport : type.subtitle(l10n),
                      style: TextStyle(
                        fontSize: 13,
                        color: isGenerating ? type.color : Colors.grey.shade600,
                        fontWeight: isGenerating ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isGenerating)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: type.color),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.download_rounded, color: type.color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
