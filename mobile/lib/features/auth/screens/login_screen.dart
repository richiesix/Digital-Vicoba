import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/phone_utils.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_screen_background.dart';
import '../../../core/widgets/language_picker_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _pinFocus = FocusNode();
  bool _loading = false;
  bool _obscurePin = true;

  Future<void> _login() async {
    setState(() => _loading = true);
    HapticFeedback.lightImpact();
    try {
      final api = ref.read(apiClientProvider);
      final phone = normalizePhone(_phoneController.text.trim());
      final pin = _pinController.text.trim();

      if (!isValidTzPhone(phone)) {
        _showError(context.l10n.invalidPhone);
        return;
      }
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
      if (!mounted) return;
      if (session.isPlatformRedirect) {
        _showError(context.l10n.platformAdminWebOnly);
        await ref.read(authSessionProvider.notifier).clear();
        await api.clearTokens();
        return;
      }
      _goAfterAuth(session);
    } on DioException catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _showError(l10n.connectionError);
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

  void _goAfterAuth(AuthSession session) {
    if (session.mustChangePin) {
      context.go('${AppRoutes.pinSetup}?forced=1');
      return;
    }
    if (session.groupId == null) {
      context.go(AppRoutes.onboarding);
    } else if (session.needsGovernanceSetup) {
      context.go(AppRoutes.governance);
    } else {
      context.go(AppRoutes.home);
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
    _phoneFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = ref.watch(localeProvider).languageCode;
    final localeLabel = localeCode == 'en' ? l10n.english : l10n.swahili;

    return Scaffold(
      body: GlassScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => LanguagePickerSheet.show(context),
                    icon: Icon(Icons.language, size: 18, color: Colors.white.withValues(alpha: 0.95)),
                    label: Text(
                      localeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GlassCard(
                  blur: 16,
                  opacity: 0.48,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.25),
                              AppColors.savings.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.savings, color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.loginWelcome,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  blur: 16,
                  opacity: 0.58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GlassLoginField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        label: l10n.phoneNumber,
                        hint: '0712 345 678',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _pinFocus.requestFocus(),
                      ),
                      const SizedBox(height: 14),
                      _GlassLoginField(
                        controller: _pinController,
                        focusNode: _pinFocus,
                        label: l10n.enterPin,
                        icon: Icons.lock_outline,
                        keyboardType: TextInputType.number,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _loading ? null : _login(),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: _pinFocus.hasFocus ? AppColors.savings : Colors.grey.shade600,
                          ),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.savings.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.devOtpHint,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _LoginPrimaryButton(
                        label: l10n.login,
                        loading: _loading,
                        onPressed: _login,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: Text(
                      l10n.noAccount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.welcome),
                    child: Text(
                      l10n.backToWelcome,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassLoginField extends StatefulWidget {
  const _GlassLoginField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  State<_GlassLoginField> createState() => _GlassLoginFieldState();
}

class _GlassLoginFieldState extends State<_GlassLoginField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.savings : Colors.white.withValues(alpha: 0.5),
          width: focused ? 2 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.savings.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade900,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(
            widget.icon,
            color: focused ? AppColors.savings : Colors.grey.shade600,
          ),
          suffixIcon: widget.suffix,
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  const _LoginPrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            height: 52,
            child: loading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
