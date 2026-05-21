import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_providers.dart';

class AuthSession {
  const AuthSession({
    this.primaryRole = 'member',
    this.dashboardType = 'member',
    this.permissions = const [],
    this.groupId,
    this.memberId,
    this.userName,
  });

  final String primaryRole;
  final String dashboardType;
  final List<String> permissions;
  final int? groupId;
  final int? memberId;
  final String? userName;

  bool hasPermission(String slug) {
    if (permissions.contains('platform.full_access')) return true;
    return permissions.contains(slug);
  }

  bool get isSuperAdmin => primaryRole == 'super_admin' || dashboardType == 'super_admin';
  bool get isTreasurer => primaryRole == 'treasurer' || dashboardType == 'treasurer';
  bool get isMember => dashboardType == 'member' && !isSuperAdmin && !isTreasurer;

  static AuthSession fromLoginResponse(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    return AuthSession(
      primaryRole: data['primary_role'] as String? ?? 'member',
      dashboardType: data['dashboard_type'] as String? ?? 'member',
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      groupId: data['group_id'] as int?,
      memberId: data['member_id'] as int?,
      userName: user != null ? '${user['first_name']} ${user['last_name']}' : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'primary_role': primaryRole,
        'dashboard_type': dashboardType,
        'permissions': permissions,
        'group_id': groupId,
        'member_id': memberId,
        'user_name': userName,
      };

  static AuthSession? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AuthSession(
      primaryRole: json['primary_role'] as String? ?? 'member',
      dashboardType: json['dashboard_type'] as String? ?? 'member',
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      groupId: json['group_id'] as int?,
      memberId: json['member_id'] as int?,
      userName: json['user_name'] as String?,
    );
  }
}

final authSessionProvider = StateNotifierProvider<AuthSessionNotifier, AuthSession?>((ref) {
  return AuthSessionNotifier(ref.watch(sharedPreferencesProvider));
});

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier(this._prefs) : super(null) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'auth_session';

  Future<void> _load() async {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      state = AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<void> setSession(AuthSession session) async {
    state = session;
    await _prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    state = null;
    await _prefs.remove(_key);
  }
}
