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
    this.isPlatformOnly = false,
    this.governanceComplete = true,
    this.isInterimChair = false,
    this.mustChangePin = false,
  });

  final String primaryRole;
  final String dashboardType;
  final List<String> permissions;
  final int? groupId;
  final int? memberId;
  final String? userName;
  final bool isPlatformOnly;
  final bool governanceComplete;
  final bool isInterimChair;
  final bool mustChangePin;

  bool hasPermission(String slug) => permissions.contains(slug);

  /// Chairperson, secretary, or interim founder — full member list and registration.
  bool get canManageMembers =>
      canSetupGovernance || hasPermission('group.manage_members');

  bool get isPlatformRedirect => isPlatformOnly || dashboardType == 'platform_redirect';
  bool get isTreasurer => primaryRole == 'treasurer' || dashboardType == 'treasurer';
  bool get isProvisionalChair =>
      isInterimChair || primaryRole == 'provisional_chair' || dashboardType == 'provisional_chair';
  bool get isChairperson => primaryRole == 'chairperson' || dashboardType == 'chairperson';
  /// True when the group still needs members registered and leadership assigned.
  bool get needsGovernanceSetup => !governanceComplete;

  /// Interim founder during forming — may manage members before formal leadership exists.
  bool get canSetupGovernance =>
      isProvisionalChair || isInterimChair || hasPermission('group.manage_members');
  bool get isSecretary => primaryRole == 'secretary' || dashboardType == 'secretary';
  bool get isLeadership =>
      isChairperson || isTreasurer || isSecretary || primaryRole == 'money_counter' || primaryRole == 'key_holder';
  bool get isMember => !isTreasurer && !isLeadership && dashboardType == 'member';

  static AuthSession fromProfile(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    return AuthSession(
      primaryRole: data['primary_role'] as String? ?? 'member',
      dashboardType: data['dashboard_type'] as String? ?? 'member',
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      groupId: data['group_id'] as int?,
      memberId: data['member_id'] as int?,
      userName: user != null ? '${user['first_name']} ${user['last_name']}' : null,
      isPlatformOnly: data['is_platform_only'] as bool? ?? false,
      governanceComplete: _parseGovernanceComplete(data),
      isInterimChair: data['is_interim_chair'] as bool? ?? false,
      mustChangePin: _parseMustChangePin(data),
    );
  }

  static AuthSession fromLoginResponse(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    return AuthSession(
      primaryRole: data['primary_role'] as String? ?? 'member',
      dashboardType: data['dashboard_type'] as String? ?? 'member',
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      groupId: data['group_id'] as int?,
      memberId: data['member_id'] as int?,
      userName: user != null ? '${user['first_name']} ${user['last_name']}' : null,
      isPlatformOnly: data['is_platform_only'] as bool? ?? false,
      governanceComplete: _parseGovernanceComplete(data),
      isInterimChair: data['is_interim_chair'] as bool? ?? false,
      mustChangePin: _parseMustChangePin(data),
    );
  }

  static bool _parseMustChangePin(Map<String, dynamic> data) =>
      data['must_change_pin'] as bool? ?? data['requires_pin_change'] as bool? ?? false;

  /// Groups with a member record default to incomplete setup unless API says otherwise.
  static bool _parseGovernanceComplete(Map<String, dynamic> data) {
    if (data.containsKey('governance_complete')) {
      return data['governance_complete'] as bool? ?? false;
    }
    final groupId = data['group_id'] as int?;
    return groupId == null;
  }

  Map<String, dynamic> toJson() => {
        'primary_role': primaryRole,
        'dashboard_type': dashboardType,
        'permissions': permissions,
        'group_id': groupId,
        'member_id': memberId,
        'user_name': userName,
        'is_platform_only': isPlatformOnly,
        'governance_complete': governanceComplete,
        'is_interim_chair': isInterimChair,
        'must_change_pin': mustChangePin,
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
      isPlatformOnly: json['is_platform_only'] as bool? ?? false,
      governanceComplete: json.containsKey('governance_complete')
          ? (json['governance_complete'] as bool? ?? false)
          : json['group_id'] == null,
      isInterimChair: json['is_interim_chair'] as bool? ?? false,
      mustChangePin: json['must_change_pin'] as bool? ?? false,
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
