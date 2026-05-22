import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.forcedChange = false});

  final bool forcedChange;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pinFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _loading = false;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  bool get _pinsMatch {
    final pin = _pinController.text;
    final confirm = _confirmController.text;
    return pin.length == 4 && confirm.length == 4 && pin == confirm;
  }

  bool get _canFinish => _pinsMatch && !_loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pinMustBe4)),
      );
      return;
    }
    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pinMismatch)),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/auth/pin/setup', data: {
        'pin': pin,
        'pin_confirmation': confirm,
      });

      final me = await api.get('/auth/me');
      final session = AuthSession.fromProfile(me.data as Map<String, dynamic>);
      await ref.read(authSessionProvider.notifier).setSession(session);

      if (!mounted) return;
      HapticFeedback.mediumImpact();

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
    } on DioException catch (e) {
      if (!mounted) return;
      final errors = e.response?.data?['errors'] as Map<String, dynamic>?;
      final pinErr = errors?['pin'] is List ? (errors!['pin'] as List).first?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pinErr ?? e.response?.data?['message']?.toString() ?? context.l10n.pinCannotMatchTemporary,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPinChanged(String value) {
    setState(() {});
    if (value.length == 4) {
      HapticFeedback.selectionClick();
      _confirmFocus.requestFocus();
    }
  }

  void _onConfirmChanged(String value) {
    setState(() {});
    if (value.length == 4 && _pinsMatch) {
      HapticFeedback.selectionClick();
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pinLen = _pinController.text.length;
    final confirmLen = _confirmController.text.length;
    final showMatch = pinLen == 4 && confirmLen == 4;

    final forced = widget.forcedChange;

    return PopScope(
      canPop: !forced,
      child: Scaffold(
      body: Stack(
        children: [
          const _PinGlassBackground(),
          SafeArea(
            child: Column(
              children: [
                _PinTopBar(l10n: l10n, forced: forced),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                                      AppColors.primary.withValues(alpha: 0.3),
                                      AppColors.savings.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                forced ? l10n.changePinRequiredTitle : l10n.choosePinHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                forced ? l10n.changePinRequiredSubtitle : l10n.pinSetupSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _PinSectionLabel(
                          label: l10n.enterPin,
                          obscure: _obscurePin,
                          onToggle: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GlassCard(
                            blur: 14,
                            opacity: 0.55,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: _GlassPinInput(
                              controller: _pinController,
                              focusNode: _pinFocus,
                              obscure: _obscurePin,
                              enabled: !_loading,
                              onChanged: _onPinChanged,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PinSectionLabel(
                          label: l10n.confirmPin,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: GlassCard(
                            blur: 14,
                            opacity: 0.55,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: _GlassPinInput(
                              controller: _confirmController,
                              focusNode: _confirmFocus,
                              obscure: _obscureConfirm,
                              enabled: !_loading,
                              onChanged: _onConfirmChanged,
                            ),
                          ),
                        ),
                        if (showMatch) ...[
                          const SizedBox(height: 16),
                          AnimatedOpacity(
                            opacity: _pinsMatch ? 1 : 0.6,
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _pinsMatch ? Icons.check_circle : Icons.error_outline,
                                  color: _pinsMatch ? AppColors.savings : AppColors.overdue,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _pinsMatch ? l10n.pinMatches : l10n.pinMismatch,
                                  style: TextStyle(
                                    color: _pinsMatch ? AppColors.savings : AppColors.overdue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        _PinPrimaryButton(
                          label: l10n.finish,
                          loading: _loading,
                          enabled: _canFinish,
                          onPressed: _finish,
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
    ),
    );
  }
}

class _PinGlassBackground extends StatelessWidget {
  const _PinGlassBackground();

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
          Positioned(top: -40, left: -30, child: _GlowOrb(size: 150, alpha: 0.1)),
          Positioned(bottom: 60, right: -50, child: _GlowOrb(size: 190, alpha: 0.12)),
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

class _PinTopBar extends StatelessWidget {
  const _PinTopBar({required this.l10n, required this.forced});

  final AppLocalizations l10n;
  final bool forced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        forced ? l10n.changePinRequiredTitle : l10n.choosePinHint,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PinSectionLabel extends StatelessWidget {
  const _PinSectionLabel({
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white.withValues(alpha: 0.9),
            size: 22,
          ),
          tooltip: obscure ? 'Show' : 'Hide',
        ),
      ],
    );
  }
}

class _GlassPinInput extends StatefulWidget {
  const _GlassPinInput({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.enabled,
    required this.onChanged,
  });

  static const double boxSize = 40;
  static const double gap = 10;
  static const double rowWidth = boxSize * 4 + gap * 3;

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<_GlassPinInput> createState() => _GlassPinInputState();
}

class _GlassPinInputState extends State<_GlassPinInput> {
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

    return SizedBox(
      width: _GlassPinInput.rowWidth,
      height: _GlassPinInput.boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.01,
            child: SizedBox(
              width: _GlassPinInput.rowWidth,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: widget.obscure,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: _GlassPinInput.gap),
                  _PinDigitBox(
                    size: _GlassPinInput.boxSize,
                    digit: i < code.length && !widget.obscure
                        ? code[i]
                        : (i < code.length ? '•' : null),
                    isActive: focused && i == code.length,
                    isFilled: i < code.length,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDigitBox extends StatelessWidget {
  const _PinDigitBox({
    required this.size,
    required this.digit,
    required this.isActive,
    required this.isFilled,
  });

  final double size;
  final String? digit;
  final bool isActive;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
                fontSize: digit == '•' ? size * 0.55 : size * 0.48,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            )
          : isActive
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.savings,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
    );
  }
}

class _PinPrimaryButton extends StatelessWidget {
  const _PinPrimaryButton({
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
