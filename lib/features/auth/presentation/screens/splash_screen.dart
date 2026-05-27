import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/app/constants/app_constants.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';

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
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    // currentUser is synchronous and available immediately after Firebase.initializeApp()
    // Do NOT use authStateProvider here — it's a stream and may still be AsyncLoading
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      context.go('/home');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
    if (mounted) {
      context.go(onboardingDone ? '/login' : '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5)),
            const SizedBox(height: 24),
            Text(
              'Speechy AI',
              style: AppTypography.displayLarge(color: context.textPrimary),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Your AI Speaking Coach',
              style: AppTypography.bodyLarge(color: context.textSecondary),
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
