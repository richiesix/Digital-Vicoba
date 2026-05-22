import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/phone_utils.dart';
import '../../../core/auth/registration_draft.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';

enum _RegisterStep { language, details }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();

  _RegisterStep _step = _RegisterStep.language;
  String? _pendingLocale;
  bool _loading = false;
  late final AnimationController _stepAnim;

  @override
  void initState() {
    super.initState();
    _pendingLocale = ref.read(localeProvider).languageCode;
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _stepAnim.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  Future<void> _continueFromLanguage() async {
    final code = _pendingLocale;
    if (code == null) return;

    HapticFeedback.selectionClick();
    await ref.read(localeProvider.notifier).setLocale(code);
    if (!mounted) return;

    setState(() => _step = _RegisterStep.details);
    _stepAnim.forward(from: 0);
  }

  void _backToLanguage() {
    HapticFeedback.lightImpact();
    setState(() {
      _step = _RegisterStep.language;
      _pendingLocale = ref.read(localeProvider).languageCode;
    });
    _stepAnim.forward(from: 0);
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = normalizePhone(_phoneController.text.trim());
    if (!isValidTzPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidPhone)),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).post('/auth/otp/send', data: {
        'phone_number': phone,
        'purpose': 'register',
      });

      ref.read(registrationDraftProvider.notifier).state = RegistrationDraft(
        phoneNumber: phone,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.push(
        '${AppRoutes.otp}?phone=${Uri.encodeComponent(phone)}&purpose=register',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data?['message']?.toString() ?? context.l10n.otpSendFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Stack(
        children: [
          const _RegisterGlassBackground(),
          SafeArea(
            child: Column(
              children: [
                _RegisterTopBar(
                  l10n: l10n,
                  onBack: _step == _RegisterStep.details ? _backToLanguage : () => context.pop(),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _stepAnim,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: _stepAnim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    },
                    child: _step == _RegisterStep.language
                        ? _LanguageStep(
                            l10n: l10n,
                            selected: _pendingLocale,
                            onSelect: (code) {
                              HapticFeedback.selectionClick();
                              setState(() => _pendingLocale = code);
                            },
                            onContinue: _pendingLocale != null ? _continueFromLanguage : null,
                          )
                        : _DetailsStep(
                            l10n: l10n,
                            formKey: _formKey,
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            phoneController: _phoneController,
                            firstNameFocus: _firstNameFocus,
                            lastNameFocus: _lastNameFocus,
                            phoneFocus: _phoneFocus,
                            loading: _loading,
                            onSubmit: _continue,
                            onChangeLanguage: _backToLanguage,
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

class _RegisterGlassBackground extends StatelessWidget {
  const _RegisterGlassBackground();

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
          Positioned(
            top: -60,
            right: -30,
            child: _GlowOrb(size: 180, alpha: 0.12),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _GlowOrb(size: 220, alpha: 0.1),
          ),
          Positioned(
            top: 200,
            left: 40,
            child: _GlowOrb(size: 100, alpha: 0.08),
          ),
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

class _RegisterTopBar extends StatelessWidget {
  const _RegisterTopBar({
    required this.l10n,
    required this.onBack,
  });

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
            tooltip: l10n.backToWelcome,
          ),
          Expanded(
            child: Text(
              l10n.register,
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

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.l10n,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
  });

  final AppLocalizations l10n;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            blur: 16,
            opacity: 0.5,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.savings.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.translate, color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.registerChooseLanguageTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.registerChooseLanguageSubtitle,
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
          _GlassLanguageOption(
            label: l10n.swahili,
            subtitle: 'Kiswahili',
            flag: '🇹🇿',
            selected: selected == 'sw',
            onTap: () => onSelect('sw'),
          ),
          const SizedBox(height: 14),
          _GlassLanguageOption(
            label: l10n.english,
            subtitle: 'English',
            flag: '🇬🇧',
            selected: selected == 'en',
            onTap: () => onSelect('en'),
          ),
          const SizedBox(height: 32),
          _GlassPrimaryButton(
            label: l10n.registerContinue,
            loading: false,
            enabled: onContinue != null,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _GlassLanguageOption extends StatelessWidget {
  const _GlassLanguageOption({
    required this.label,
    required this.subtitle,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
        onTap: onTap,
        blur: selected ? 18 : 12,
        opacity: selected ? 0.72 : 0.48,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.savings
                    : Colors.grey.withValues(alpha: 0.2),
                border: Border.all(
                  color: selected ? AppColors.savings : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.l10n,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.phoneFocus,
    required this.loading,
    required this.onSubmit,
    required this.onChangeLanguage,
  });

  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;
  final FocusNode phoneFocus;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onChangeLanguage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              blur: 14,
              opacity: 0.45,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.language, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      refLocaleLabel(context, l10n),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onChangeLanguage,
                    child: Text(
                      l10n.changeLanguage,
                      style: const TextStyle(
                        color: AppColors.savings,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              blur: 16,
              opacity: 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.registerSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassTextField(
                    controller: firstNameController,
                    focusNode: firstNameFocus,
                    label: l10n.firstName,
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => lastNameFocus.requestFocus(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 14),
                  _GlassTextField(
                    controller: lastNameController,
                    focusNode: lastNameFocus,
                    label: l10n.lastName,
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => phoneFocus.requestFocus(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 14),
                  _GlassTextField(
                    controller: phoneController,
                    focusNode: phoneFocus,
                    label: l10n.phoneNumber,
                    hint: '0712 345 678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => loading ? null : onSubmit(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.devOtpHint,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            _GlassPrimaryButton(
              label: l10n.sendOtp,
              loading: loading,
              enabled: !loading,
              onPressed: loading ? null : onSubmit,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  l10n.alreadyHaveAccountLogin,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String refLocaleLabel(BuildContext context, AppLocalizations l10n) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? l10n.english : l10n.swahili;
  }
}

class _GlassTextField extends StatefulWidget {
  const _GlassTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.validator,
    this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() => _focused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? AppColors.savings
              : Colors.white.withValues(alpha: 0.5),
          width: _focused ? 2 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.savings.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade900,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.55),
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: _focused ? AppColors.savings : Colors.grey.shade600)
              : null,
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

class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback? onPressed;

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
