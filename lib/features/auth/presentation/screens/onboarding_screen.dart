import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/app/constants/app_constants.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

// Step indices
const _kFeatureCount = 3;
const _kStepNotification = _kFeatureCount;     // index 3
const _kStepLogin = _kFeatureCount + 1;         // index 4
const _kTotalSteps = _kFeatureCount + 2;        // 5 total

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _features = [
    _FeaturePage(
      icon: Icons.people_rounded,
      color: AppColors.primary,
      title: 'Talk to AI characters',
      description: 'Practice real conversations — job interviews, presentations, dates — with AI partners that respond like real people.',
    ),
    _FeaturePage(
      icon: Icons.auto_awesome_rounded,
      color: AppColors.secondary,
      title: 'Get honest feedback',
      description: 'Our AI listens to your actual voice and scores clarity, confidence, pace, and engagement in real time.',
    ),
    _FeaturePage(
      icon: Icons.trending_up_rounded,
      color: AppColors.skyBlue,
      title: 'Follow your roadmap',
      description: 'Unlock harder scenarios as you improve. Track your progress and see yourself grow step by step.',
    ),
  ];

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  void _next() {
    if (_currentPage < _kTotalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _requestNotifications() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (Platform.isIOS) {
        await plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (Platform.isAndroid) {
        await plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (_) {}
    if (!mounted) return;
    _next();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress + Skip ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _kTotalSteps,
                        minHeight: 4,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  if (_currentPage < _kStepLogin) ...[
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () async {
                        await _markOnboardingDone();
                        if (mounted) {
                          _pageController.jumpToPage(_kStepLogin);
                        }
                      },
                      child: Text(
                        'Skip',
                        style: AppTypography.bodyMedium(color: context.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Feature slides
                  for (final f in _features)
                    _FeatureSlide(page: f),

                  // Notification permission
                  _NotificationStep(
                    onAllow: _requestNotifications,
                    onSkip: _next,
                  ),

                  // Login (last)
                  _LoginStep(onDone: _markOnboardingDone),
                ],
              ),
            ),

            // ── Bottom CTA (feature slides only) ─────────────────────────
            if (_currentPage < _kStepNotification)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: DuoButton.primary(
                  text: _currentPage == _kStepNotification - 1 ? 'Continue' : 'Next',
                  width: double.infinity,
                  onTap: _next,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Slide ───────────────────────────────────────────────────────────

class _FeatureSlide extends StatelessWidget {
  final _FeaturePage page;
  const _FeatureSlide({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(page.icon, color: page.color, size: 64),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: AppTypography.displaySmall(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: AppTypography.bodyLarge(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── Notification Step ───────────────────────────────────────────────────────

class _NotificationStep extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _NotificationStep({required this.onAllow, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppColors.secondary,
              size: 64,
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 40),
          Text(
            'Stay on track',
            style: AppTypography.displaySmall(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
          Text(
            'Get daily reminders to practice and streak alerts so you never lose your momentum.',
            style: AppTypography.bodyLarge(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 48),
          DuoButton.primary(
            text: 'Allow Notifications',
            width: double.infinity,
            onTap: onAllow,
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Not now',
              style: AppTypography.bodyMedium(color: context.textSecondary),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

// ─── Login Step ──────────────────────────────────────────────────────────────

class _LoginStep extends ConsumerStatefulWidget {
  final Future<void> Function() onDone;
  const _LoginStep({required this.onDone});

  @override
  ConsumerState<_LoginStep> createState() => _LoginStepState();
}

class _LoginStepState extends ConsumerState<_LoginStep> {
  bool _showEmailForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterLogin() async {
    await widget.onDone();
    if (mounted) context.go('/home');
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) _afterLogin();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.error != null) {
        context.showSnackBar(next.error!, isError: true);
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 48),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 28),
          Text(
            'Create your account',
            style: AppTypography.displaySmall(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'Save your progress and continue on any device.',
            style: AppTypography.bodyMedium(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 40),

          // Google
          _SocialButton(
            label: 'Continue with Google',
            isLoading: authState.isLoading,
            onTap: () async {
              final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
              if (success && mounted) _afterLogin();
            },
          ).animate().fadeIn(delay: 260.ms),

          // Apple (iOS release only)
          if (Platform.isIOS && kReleaseMode) ...[
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Continue with Apple',
              icon: Icons.apple_rounded,
              isLoading: authState.isLoading,
              onTap: () async {
                final success = await ref.read(authNotifierProvider.notifier).signInWithApple();
                if (success && mounted) _afterLogin();
              },
            ).animate().fadeIn(delay: 310.ms),
          ],

          const SizedBox(height: 24),

          // Email toggle
          if (!_showEmailForm)
            Tappable(
              onTap: () => setState(() => _showEmailForm = true),
              child: Text(
                'Sign in with email',
                style: AppTypography.labelMedium(color: context.textSecondary),
              ),
            ).animate().fadeIn(delay: 360.ms)
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter email';
                      if (!v.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 16),
                  DuoButton.primary(
                    text: 'Sign In',
                    width: double.infinity,
                    onTap: authState.isLoading ? null : _signInWithEmail,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),
          Text(
            'By continuing, you agree to our Terms & Privacy Policy.',
            style: AppTypography.labelSmall(color: context.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Social Button ───────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 22)
            else
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: const Center(
                  child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                ),
              ),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.titleMedium()),
          ],
        ),
      ),
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────────────

class _FeaturePage {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeaturePage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
