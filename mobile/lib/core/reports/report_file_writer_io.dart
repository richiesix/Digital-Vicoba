import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> writeReportFile(String filename, String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final reportsDir = p.join(dir.path, 'reports');
  await Directory(reportsDir).create(recursive: true);
  final path = p.join(reportsDir, filename);
  await File(path).writeAsString(content);
  return path;
}
