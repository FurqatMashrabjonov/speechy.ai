import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/app/constants/app_constants.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/assessment/data/assessment_data.dart';
import 'package:speech_coach/features/assessment/domain/assessment_entity.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

// Page indices
const _kIntroPage = 0;
const _kQuestionCount = 6; // assessmentQuestions.length
const _kWidgetPage = _kIntroPage + 1 + _kQuestionCount; // 7
const _kNotifPage = _kWidgetPage + 1;                    // 8
const _kLoginPage = _kNotifPage + 1;                     // 9

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final Map<String, String> _answers = {};
  bool _generatingPlan = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _goTo(_currentPage + 1);

  // Called when user taps "I already have an account"
  Future<void> _goToLogin() async {
    await _markOnboardingDone();
    _goTo(_kLoginPage);
  }

  // Called after answering last question
  Future<void> _generatePlan() async {
    if (_generatingPlan) return;
    setState(() => _generatingPlan = true);
    try {
      final answers = _answers.entries
          .map((e) => AssessmentAnswer(questionId: e.key, optionId: e.value))
          .toList();
      await ref.read(learningPlanProvider.notifier).generateFromAssessment(answers);
    } catch (_) {}
    if (mounted) {
      setState(() => _generatingPlan = false);
      _next(); // go to widget page
    }
  }

  void _onOptionSelected(String questionId, String optionId) {
    HapticFeedback.lightImpact();
    setState(() => _answers[questionId] = optionId);

    final questionIndex = _currentPage - 1; // page 1 = question 0
    final isLastQuestion = questionIndex == _kQuestionCount - 1;

    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      if (isLastQuestion) {
        _generatePlan();
      } else {
        _next();
      }
    });
  }

  Future<void> _onLoginDone() async {
    await _markOnboardingDone();
    if (!mounted) return;
    context.go('/home');
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
    if (mounted) _next();
  }

  bool get _showProgressBar =>
      _currentPage > _kIntroPage && _currentPage < _kLoginPage;

  double get _progressValue {
    if (_currentPage <= _kIntroPage) return 0;
    if (_currentPage >= _kLoginPage) return 1;
    return _currentPage / (_kLoginPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            if (_showProgressBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    if (_currentPage > _kIntroPage + 1 && _currentPage < _kWidgetPage)
                      GestureDetector(
                        onTap: () => _goTo(_currentPage - 1),
                        child: const Icon(Icons.arrow_back_rounded, size: 22),
                      )
                    else
                      const SizedBox(width: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          minHeight: 6,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Pages ─────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // 0 — Intro
                  _IntroPage(
                    onGetStarted: _next,
                    onAlreadyHaveAccount: _goToLogin,
                  ),

                  // 1-6 — Assessment questions
                  for (int i = 0; i < _kQuestionCount; i++)
                    _QuestionPage(
                      question: assessmentQuestions[i],
                      selectedOptionId: _answers[assessmentQuestions[i].id],
                      isGenerating: _generatingPlan && i == _kQuestionCount - 1,
                      onSelect: (optionId) =>
                          _onOptionSelected(assessmentQuestions[i].id, optionId),
                    ),

                  // 7 — Widget
                  _WidgetPage(onContinue: _next),

                  // 8 — Notifications
                  _NotifPage(
                    onAllow: _requestNotifications,
                    onSkip: _next,
                  ),

                  // 9 — Login
                  _LoginPage(
                    onDone: _onLoginDone,
                    onAlreadyHaveAccount: _goToLogin,
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

// ─── Intro Page ──────────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onAlreadyHaveAccount;

  const _IntroPage({
    required this.onGetStarted,
    required this.onAlreadyHaveAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Mascot
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 56),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          Text(
            'Speechy AI',
            style: AppTypography.displayLarge(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 10),

          Text(
            'Your personal AI speaking coach',
            style: AppTypography.bodyLarge(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),

          const Spacer(flex: 2),

          // Get Started
          DuoButton.primary(
            text: 'Get Started',
            width: double.infinity,
            onTap: onGetStarted,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),

          const SizedBox(height: 14),

          // Already have account
          Tappable(
            onTap: onAlreadyHaveAccount,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.divider, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'I already have an account',
                style: AppTypography.titleMedium(color: context.textSecondary),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Question Page ────────────────────────────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  final AssessmentQuestion question;
  final String? selectedOptionId;
  final bool isGenerating;
  final ValueChanged<String> onSelect;

  const _QuestionPage({
    required this.question,
    required this.selectedOptionId,
    required this.isGenerating,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Mascot + speech bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: context.divider),
                  ),
                  child: Text(
                    question.text,
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 28),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            final isSelected = option.id == selectedOptionId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: isGenerating ? null : () => onSelect(option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(option.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option.label,
                          style: AppTypography.titleMedium(
                            color: isSelected ? AppColors.primary : context.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 80 + i * 60)).slideY(begin: 0.1);
          }),

          if (isGenerating) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Widget Page ──────────────────────────────────────────────────────────────

class _WidgetPage extends StatelessWidget {
  final VoidCallback onContinue;

  const _WidgetPage({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),

          // Mascot + speech bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: context.divider),
                  ),
                  child: Text(
                    "I'll support you from your home screen!",
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 32),

          // Widget preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 10),
                Text(
                  'Speechy AI',
                  style: AppTypography.titleMedium(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to practice today',
                  style: AppTypography.bodySmall(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('0 day streak',
                        style: AppTypography.labelSmall(color: Colors.white)),
                    const SizedBox(width: 16),
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('0 XP',
                        style: AppTypography.labelSmall(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).scale(
                begin: const Offset(0.9, 0.9),
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 12),
          Text(
            'Add the widget from your home screen by long-pressing an empty area.',
            style: AppTypography.bodySmall(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms),

          const Spacer(),

          DuoButton.primary(
            text: 'Continue',
            width: double.infinity,
            onTap: onContinue,
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Notification Page ────────────────────────────────────────────────────────

class _NotifPage extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _NotifPage({required this.onAllow, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),

          // Mascot + speech bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: context.divider),
                  ),
                  child: Text(
                    "Can I remind you to practice every day?",
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 32),

          // Notification preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Speechy AI', style: AppTypography.labelMedium()),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to practice? Step 1 of Interview Prep is waiting.',
                        style: AppTypography.bodySmall(color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),
          Text(
            'Daily reminders + streak alerts. No spam.',
            style: AppTypography.bodySmall(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),

          const Spacer(),

          DuoButton.primary(
            text: 'Allow Notifications',
            width: double.infinity,
            onTap: onAllow,
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 14),

          TextButton(
            onPressed: onSkip,
            child: Text(
              'Not now',
              style: AppTypography.bodyMedium(color: context.textSecondary),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Login Page ───────────────────────────────────────────────────────────────

class _LoginPage extends ConsumerStatefulWidget {
  final Future<void> Function() onDone;
  final VoidCallback onAlreadyHaveAccount;

  const _LoginPage({
    required this.onDone,
    required this.onAlreadyHaveAccount,
  });

  @override
  ConsumerState<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<_LoginPage> {
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

  Future<void> _afterLogin() => widget.onDone();

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

          // Mascot + speech bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: context.divider),
                  ),
                  child: Text(
                    'Save your progress — create a free account!',
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 32),

          // Google
          _SocialButton(
            label: 'Continue with Google',
            isLoading: authState.isLoading,
            onTap: () async {
              final success =
                  await ref.read(authNotifierProvider.notifier).signInWithGoogle();
              if (success && mounted) _afterLogin();
            },
          ).animate().fadeIn(delay: 100.ms),

          // Apple (iOS release only)
          if (Platform.isIOS && kReleaseMode) ...[
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Continue with Apple',
              icon: Icons.apple_rounded,
              isLoading: authState.isLoading,
              onTap: () async {
                final success =
                    await ref.read(authNotifierProvider.notifier).signInWithApple();
                if (success && mounted) _afterLogin();
              },
            ).animate().fadeIn(delay: 150.ms),
          ],

          const SizedBox(height: 20),

          // Email toggle
          if (!_showEmailForm)
            Tappable(
              onTap: () => setState(() => _showEmailForm = true),
              child: Text(
                'Sign in with email',
                style: AppTypography.labelMedium(color: context.textSecondary),
              ),
            ).animate().fadeIn(delay: 200.ms)
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
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
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter password' : null,
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

          const SizedBox(height: 32),
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

// ─── Social Button ────────────────────────────────────────────────────────────

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
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                  ),
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
