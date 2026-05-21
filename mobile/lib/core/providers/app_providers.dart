import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../reports/report_storage_service.dart';
import '../sync/sync_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(apiClientProvider));
});

final reportStorageProvider = Provider<ReportStorageService>((ref) {
  return ReportStorageService(ref.watch(sharedPreferencesProvider));
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'language';

  static Locale _load(SharedPreferences prefs) {
    final code = prefs.getString(_key) ?? 'sw';
    return Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    await _prefs.setString(_key, languageCode);
    state = Locale(languageCode);
  }

  bool get isSwahili => state.languageCode == 'sw';
}
