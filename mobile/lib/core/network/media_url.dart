import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/api_constants.dart';

/// Authenticated API endpoint that streams the current user's profile photo.
String profilePhotoApiUrl() => '${ApiConstants.baseUrl}/auth/profile/photo';

/// Resolves stored profile paths or legacy absolute URLs for display.
String? resolveProfilePhotoUrl(String? stored) {
  if (stored == null || stored.isEmpty) return null;

  // Always load via API (JWT + CORS-safe) when user has a photo on record.
  return profilePhotoApiUrl();
}

/// Resolves general media URLs (group assets, etc.).
String? resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  var resolved = url;
  if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
    final origin = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final path = resolved.startsWith('/') ? resolved : '/$resolved';
    resolved = '$origin$path';
  }

  resolved = _normalizeHost(resolved);

  return resolved;
}

String _normalizeHost(String url) {
  if (kIsWeb) {
    return url.replaceAll('localhost', '127.0.0.1');
  }

  if (!kIsWeb && Platform.isAndroid) {
    return url
        .replaceAll('127.0.0.1', '10.0.2.2')
        .replaceAll('localhost', '10.0.2.2');
  }

  return url;
}
