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
import '../../../core/widgets/language_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _sharePriceController = TextEditingController(text: '5000');
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  bool _creating = false;

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fieldRequired)),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _creating = true);
    try {
      final res = await ref.read(apiClientProvider).post('/groups', data: {
        'name': _nameController.text.trim(),
        'share_price': double.tryParse(_sharePriceController.text) ?? 5000,
        'meeting_frequency': 'weekly',
      });

      final isInterim = res.data['is_interim_chair'] as bool? ?? true;
      final me = await ref.read(apiClientProvider).get('/auth/me');
      final session = AuthSession.fromProfile(me.data as Map<String, dynamic>);
      await ref.read(authSessionProvider.notifier).setSession(
            AuthSession(
              primaryRole: isInterim ? 'provisional_chair' : session.primaryRole,
              dashboardType: isInterim ? 'provisional_chair' : session.dashboardType,
              permissions: session.permissions,
              groupId: session.groupId,
              memberId: session.memberId,
              userName: session.userName,
              governanceComplete: false,
              isInterimChair: isInterim || session.isInterimChair,
            ),
          );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupCreated)),
      );
      if (isInterim || session.needsGovernanceSetup) {
        context.go(AppRoutes.governance);
      } else {
        context.go(AppRoutes.home);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? e.message ?? '')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showInviteInfo() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.inviteComingSoon)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sharePriceController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = ref.watch(localeProvider).languageCode;
    final localeLabel = localeCode == 'en' ? l10n.english : l10n.swahili;

    return Scaffold(
      body: Stack(
        children: [
          const _OnboardingGlassBackground(),
          SafeArea(
            child: Column(
              children: [
                _OnboardingTopBar(l10n: l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          blur: 10,
                          opacity: 0.38,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.language, size: 20, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localeLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => LanguagePickerSheet.show(context),
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
                                  Icons.groups_rounded,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.onboardingTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.onboardingSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Colors.grey.shade700,
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.savings.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add_business_outlined,
                                      color: AppColors.savings,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.createYourGroup,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.createGroupHint,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _GlassOnboardingField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                label: l10n.groupName,
                                icon: Icons.groups_outlined,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _priceFocus.requestFocus(),
                              ),
                              const SizedBox(height: 14),
                              _GlassOnboardingField(
                                controller: _sharePriceController,
                                focusNode: _priceFocus,
                                label: l10n.sharePriceLabel,
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _creating ? null : _createGroup(),
                              ),
                              const SizedBox(height: 20),
                              _OnboardingPrimaryButton(
                                label: l10n.createGroup,
                                loading: _creating,
                                enabled: !_creating,
                                onPressed: _createGroup,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          onTap: _showInviteInfo,
                          blur: 12,
                          opacity: 0.42,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.joinWithInvite,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: Colors.grey.shade600),
                            ],
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

class _OnboardingGlassBackground extends StatelessWidget {
  const _OnboardingGlassBackground();

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
          Positioned(top: -70, right: -30, child: _GlowOrb(size: 170, alpha: 0.11)),
          Positioned(bottom: 40, left: -50, child: _GlowOrb(size: 210, alpha: 0.1)),
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

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        l10n.onboardingTitle,
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

class _GlassOnboardingField extends StatefulWidget {
  const _GlassOnboardingField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_GlassOnboardingField> createState() => _GlassOnboardingFieldState();
}

class _GlassOnboardingFieldState extends State<_GlassOnboardingField> {
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
          color: _focused ? AppColors.savings : Colors.white.withValues(alpha: 0.5),
          width: _focused ? 2 : 1,
        ),
        boxShadow: _focused
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
          prefixIcon: Icon(
            widget.icon,
            color: _focused ? AppColors.savings : Colors.grey.shade600,
          ),
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

class _OnboardingPrimaryButton extends StatelessWidget {
  const _OnboardingPrimaryButton({
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
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Container(
            alignment: Alignment.center,
            height: 52,
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
