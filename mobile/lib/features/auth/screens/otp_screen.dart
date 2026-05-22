import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/registration_draft.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.purpose});

  final String phone;
  final String purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  bool _loading = false;
  int _resendSeconds = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        setState(() => _resendSeconds = 0);
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds -= 1);
    });
  }

  String get _otp => _otpController.text.trim();

  Future<void> _verifyAndRegister() async {
    final draft = ref.read(registrationDraftProvider);
    if (draft == null && widget.purpose == 'register') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.registrationExpired)),
      );
      context.go(AppRoutes.register);
      return;
    }

    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.otpMustBe6)),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);

      if (widget.purpose == 'register' && draft != null) {
        final res = await api.post('/auth/register', data: {
          'phone_number': draft.phoneNumber,
          'otp': _otp,
          'first_name': draft.firstName,
          'last_name': draft.lastName,
          'preferred_language': ref.read(localeProvider).languageCode,
        });

        await api.saveTokens(
          res.data['access_token'] as String,
          res.data['refresh_token'] as String,
        );

        ref.read(registrationDraftProvider.notifier).state = null;

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.pinSetup);
        return;
      }

      final verify = await api.post('/auth/otp/verify', data: {
        'phone_number': widget.phone,
        'otp': _otp,
        'purpose': widget.purpose,
      });

      if (verify.data['verified'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invalidOtp)),
        );
        return;
      }

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.go(AppRoutes.pinSetup);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data?['message']?.toString() ?? context.l10n.invalidOtp,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    HapticFeedback.selectionClick();
    try {
      await ref.read(apiClientProvider).post('/auth/otp/send', data: {
        'phone_number': widget.phone,
        'purpose': widget.purpose,
      });
      if (!mounted) return;
      _otpController.clear();
      _otpFocus.requestFocus();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.otpResent)),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? '')),
      );
    }
  }

  void _onOtpChanged(String value) {
    setState(() {});
    if (value.length == 6 && !_loading) {
      _verifyAndRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Stack(
        children: [
          const _OtpGlassBackground(),
          SafeArea(
            child: Column(
              children: [
                _OtpTopBar(l10n: l10n, onBack: () => context.pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          blur: 16,
                          opacity: 0.5,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.savings.withValues(alpha: 0.3),
                                      AppColors.primary.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.sms_outlined,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.verifyOtp,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.otpSentTo(widget.phone),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.otpEnterSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.35,
                                ),
                              ),
                              if (kDebugMode) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.savings.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.savings.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.devOtpHint,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.savings,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        GlassCard(
                          blur: 14,
                          opacity: 0.55,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: _GlassOtpInput(
                            controller: _otpController,
                            focusNode: _otpFocus,
                            enabled: !_loading,
                            onChanged: _onOtpChanged,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _OtpPrimaryButton(
                          label: l10n.verifyOtp,
                          loading: _loading,
                          enabled: _otp.length == 6 && !_loading,
                          onPressed: _verifyAndRegister,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _resendSeconds > 0
                              ? Text(
                                  l10n.resendIn(_resendSeconds),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : TextButton(
                                  onPressed: _resendOtp,
                                  child: Text(
                                    l10n.resendOtp,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpGlassBackground extends StatelessWidget {
  const _OtpGlassBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF81C784), Color(0xFFA5D6A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -20, child: _GlowOrb(size: 160, alpha: 0.12)),
          Positioned(bottom: 100, left: -40, child: _GlowOrb(size: 200, alpha: 0.1)),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _OtpTopBar extends StatelessWidget {
  const _OtpTopBar({required this.l10n, required this.onBack});

  final AppLocalizations l10n;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              l10n.verifyOtp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GlassOtpInput extends StatefulWidget {
  const _GlassOtpInput({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<_GlassOtpInput> createState() => _GlassOtpInputState();
}

class _GlassOtpInputState extends State<_GlassOtpInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final focused = widget.focusNode.hasFocus;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          right: 0,
          height: 56,
          child: Opacity(
            opacity: 0.01,
            child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.enabled ? () => widget.focusNode.requestFocus() : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              final hasDigit = i < code.length;
              final isActive = focused && i == code.length;
              return _OtpDigitBox(
                digit: hasDigit ? code[i] : null,
                isActive: isActive,
                isFilled: hasDigit,
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.digit,
    required this.isActive,
    required this.isFilled,
  });

  final String? digit;
  final bool isActive;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: isFilled ? 0.75 : 0.45),
        border: Border.all(
          color: isActive
              ? AppColors.savings
              : isFilled
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.6),
          width: isActive ? 2.5 : 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.savings.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: digit != null
          ? Text(
              digit!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            )
          : isActive
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.savings,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
    );
  }
}

class _OtpPrimaryButton extends StatelessWidget {
  const _OtpPrimaryButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !loading ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: enabled
                  ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
                  : [Colors.grey.shade500, Colors.grey.shade600],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Container(
            alignment: Alignment.center,
            height: 54,
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
