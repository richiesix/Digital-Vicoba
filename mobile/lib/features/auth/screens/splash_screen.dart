import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final api = ref.read(apiClientProvider);
    final hasToken = await api.hasToken();

    if (!hasToken) {
      if (mounted) context.go(AppRoutes.welcome);
      return;
    }

    try {
      final res = await api.get('/auth/me');
      final session = AuthSession.fromProfile(res.data as Map<String, dynamic>);
      await ref.read(authSessionProvider.notifier).setSession(session);

      if (!mounted) return;
      if (session.isPlatformRedirect) {
        await api.clearTokens();
        await ref.read(authSessionProvider.notifier).clear();
        if (mounted) context.go(AppRoutes.welcome);
        return;
      }

      if (session.mustChangePin) {
        context.go('${AppRoutes.pinSetup}?forced=1');
      } else if (session.groupId == null) {
        context.go(AppRoutes.onboarding);
      } else if (session.needsGovernanceSetup) {
        context.go(AppRoutes.governance);
      } else {
        context.go(AppRoutes.home);
      }
    } on DioException catch (_) {
      await api.clearTokens();
      await ref.read(authSessionProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings, size: 80, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 24),
            Text(
              l10n.appTitle,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appTagline,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
