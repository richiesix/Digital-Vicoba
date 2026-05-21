import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class _DemoRole {
  const _DemoRole({
    required this.id,
    required this.phone,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String phone;
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final Color color;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _loading = false;
  bool _obscurePin = true;
  String? _selectedDemoId;

  static const _demoPin = '1234';

  static final _demoRoles = [
    _DemoRole(
      id: 'super_admin',
      phone: '+255712000001',
      label: (l) => l.roleSuperAdmin,
      icon: Icons.admin_panel_settings,
      color: const Color(0xFF1B5E20),
    ),
    _DemoRole(
      id: 'treasurer',
      phone: '+255712000002',
      label: (l) => l.roleTreasurer,
      icon: Icons.account_balance,
      color: const Color(0xFF2E7D32),
    ),
    _DemoRole(
      id: 'member',
      phone: '+255712000003',
      label: (l) => l.roleMember,
      icon: Icons.person,
      color: const Color(0xFF43A047),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fillDemo(_demoRoles.last);
  }

  void _fillDemo(_DemoRole role) {
    setState(() {
      _selectedDemoId = role.id;
      _phoneController.text = role.phone;
      _pinController.text = _demoPin;
    });
    HapticFeedback.selectionClick();
  }

  String _normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length >= 12) {
      return '+${digits.substring(0, 12)}';
    }
    if (digits.startsWith('0') && digits.length == 10) {
      return '+255${digits.substring(1)}';
    }
    if (digits.length == 9) {
      return '+255$digits';
    }
    if (input.startsWith('+')) return input.trim();
    return '+$digits';
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    HapticFeedback.lightImpact();
    try {
      final api = ref.read(apiClientProvider);
      final phone = _normalizePhone(_phoneController.text.trim());
      final pin = _pinController.text.trim();

      if (pin.length != 4) {
        _showError(context.l10n.pinMustBe4);
        return;
      }

      final res = await api.post('/auth/login', data: {
        'phone_number': phone,
        'pin': pin,
      });

      await api.saveTokens(
        res.data['access_token'] as String,
        res.data['refresh_token'] as String,
      );

      final session = AuthSession.fromLoginResponse(res.data as Map<String, dynamic>);
      await ref.read(authSessionProvider.notifier).setSession(session);

      HapticFeedback.mediumImpact();
      if (mounted) context.go(AppRoutes.home);
    } on DioException catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _showError(
          'Haiwezi kuunganisha na seva.\n'
          'Hakikisha backend inaendesha:\n'
          'cd backend → php artisan serve\n'
          'URL: ${ApiConstants.baseUrl}',
        );
      } else if (e.response?.statusCode == 401) {
        _showError(l10n.invalidCredentials);
      } else {
        _showError(e.response?.data?['message']?.toString() ?? l10n.loginFailed);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('${context.l10n.error}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.overdue,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _LoginHeader(l10n: l10n),
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.tryDemoAccount,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: _demoRoles.map((role) {
                              final selected = _selectedDemoId == role.id;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: role.id != _demoRoles.last.id ? 8 : 0,
                                  ),
                                  child: _DemoRoleChip(
                                    role: role,
                                    label: role.label(l10n),
                                    selected: selected,
                                    onTap: () => _fillDemo(role),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.demoPinLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.phoneNumber,
                              hintText: '+255712000001',
                              prefixIcon: const Icon(Icons.phone, color: AppColors.savings),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _pinController,
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _loading ? null : _login(),
                            decoration: InputDecoration(
                              labelText: l10n.enterPin,
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.savings),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() => _obscurePin = !_obscurePin);
                                  HapticFeedback.selectionClick();
                                },
                              ),
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_outlined, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'API: ${ApiConstants.baseUrl}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _loading ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.login,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            child: Text(
                              l10n.noAccount,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.savings,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loginWelcome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.loginSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DemoRoleChip extends StatelessWidget {
  const _DemoRoleChip({
    required this.role,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _DemoRole role;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? role.color.withValues(alpha: 0.15) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? role.color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(role.icon, color: selected ? role.color : Colors.grey.shade600, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? role.color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
