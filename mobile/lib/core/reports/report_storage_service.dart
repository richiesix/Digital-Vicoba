import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'report_file_writer_stub.dart'
    if (dart.library.io) 'report_file_writer_io.dart' as file_writer;

class SavedReport {
  SavedReport({
    required this.id,
    required this.type,
    required this.title,
    required this.filename,
    required this.generatedAt,
    required this.summary,
    required this.columns,
    required this.rows,
    this.localPath,
    this.groupName,
  });

  final String id;
  final String type;
  final String title;
  final String filename;
  final String generatedAt;
  final Map<String, dynamic> summary;
  final List<String> columns;
  final List<List<String>> rows;
  final String? localPath;
  final String? groupName;

  factory SavedReport.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List? ?? [];
    return SavedReport(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      filename: json['filename'] as String? ?? 'report.csv',
      generatedAt: json['generated_at'] as String? ?? '',
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
      columns: (json['columns'] as List? ?? []).map((e) => e.toString()).toList(),
      rows: rawRows
          .map((row) => (row as List).map((cell) => cell.toString()).toList())
          .toList(),
      localPath: json['local_path'] as String?,
      groupName: json['group_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'filename': filename,
        'generated_at': generatedAt,
        'summary': summary,
        'columns': columns,
        'rows': rows,
        'local_path': localPath,
        'group_name': groupName,
      };
}

class ReportStorageService {
  ReportStorageService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'downloaded_reports_v1';

  Future<List<SavedReport>> listReports() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SavedReport.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  Future<SavedReport> saveFromApi(Map<String, dynamic> reportPayload) async {
    final csv = reportPayload['csv_content'] as String? ?? '';
    final filename = reportPayload['filename'] as String? ?? 'report.csv';
    String? localPath;

    if (csv.isNotEmpty) {
      localPath = await file_writer.writeReportFile(filename, csv);
    }

    final saved = SavedReport(
      id: reportPayload['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: reportPayload['type'] as String? ?? '',
      title: reportPayload['title'] as String? ?? '',
      filename: filename,
      generatedAt: reportPayload['generated_at'] as String? ?? DateTime.now().toIso8601String(),
      summary: Map<String, dynamic>.from(reportPayload['summary'] as Map? ?? {}),
      columns: (reportPayload['columns'] as List? ?? []).map((e) => e.toString()).toList(),
      rows: (reportPayload['rows'] as List? ?? [])
          .map((row) => (row as List).map((c) => c.toString()).toList())
          .toList(),
      localPath: localPath,
      groupName: reportPayload['group_name'] as String?,
    );

    final existing = await listReports();
    existing.removeWhere((r) => r.id == saved.id);
    existing.insert(0, saved);
    await _prefs.setString(
      _key,
      jsonEncode(existing.take(20).map((r) => r.toJson()).toList()),
    );

    return saved;
  }

  Future<void> deleteReport(String id) async {
    final existing = await listReports();
    existing.removeWhere((r) => r.id == id);
    await _prefs.setString(_key, jsonEncode(existing.map((r) => r.toJson()).toList()));
  }
}
