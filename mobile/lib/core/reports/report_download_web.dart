// Web-only CSV download helper (Chrome, Edge, etc.).
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void triggerCsvDownload(String filename, String csvContent) {
  // UTF-8 BOM helps Excel open Swahili text correctly.
  final bytes = utf8.encode('\uFEFF$csvContent');
  final blob = html.Blob([bytes], 'text/csv', 'native');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  // Revoke after click so Chrome can start the download.
  unawaited(
    Future<void>.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(url);
    }),
  );
}
