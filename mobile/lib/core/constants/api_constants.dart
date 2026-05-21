import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    if (Platform.isAndroid) {
      // Android emulator → host machine localhost
      return 'http://10.0.2.2:8000/api/v1';
    }

    // Windows, macOS, Linux desktop, iOS simulator
    return 'http://127.0.0.1:8000/api/v1';
  }

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
}
