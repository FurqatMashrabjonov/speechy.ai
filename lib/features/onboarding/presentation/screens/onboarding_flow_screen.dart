import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:speech_coach/app/constants/app_constants.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.record_voice_over_rounded,
      iconColor: AppColors.primary,
      title: 'Real Conversations, Real Feedback',
      description:
          'Talk out loud with an AI that responds in real-time voice — like a real interviewer, date, or boss. No scripts. Just natural conversation.',
      imagePath: AppImages.mascotWelcome,
    ),
    _OnboardingPage(
      icon: Icons.route_rounded,
      iconColor: AppColors.secondary,
      title: 'Your Personal Roadmap',
      description:
          'Get a 15-step path built around your goal — job interview, social confidence, public speaking. Easy to hard, one step at a time.',
      imagePath: AppImages.mascotAnalyze,
    ),
    _OnboardingPage(
      icon: Icons.insights_rounded,
      iconColor: AppColors.lime,
      title: 'See Yourself Improve',
      description:
          'After each session, get scored on clarity, confidence, and engagement. Track filler words, pass each step, unlock the next level.',
      imagePath: AppImages.mascotCelebrate,
    ),
  ];

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
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _pages.length - 1)
                    Tappable(
                      onTap: () => _completeOnboarding(),
                      child: Text(
                        'Skip',
                        style: AppTypography.labelLarge(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : context.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action button
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: DuoButton.primary(
                text: _currentPage < _pages.length - 1
                    ? 'Next'
                    : 'Get Started',
                width: double.infinity,
                onTap: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _requestMicPermission();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page.imagePath != null)
            Image.asset(
              page.imagePath!,
              width: 240,
              height: 240,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: page.iconColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(page.icon, color: page.iconColor, size: 48),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.easeOutBack,
                )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: page.iconColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(page.icon, color: page.iconColor, size: 48),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.easeOutBack,
                ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: AppTypography.displaySmall(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Text(
            page.description,
            style: AppTypography.bodyLarge(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Future<void> _requestMicPermission() async {
    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    await recorder.dispose();

    if (hasPermission || !mounted) {
      _completeOnboarding();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone access is needed for voice conversations. You can enable it in Settings.'),
          ),
        );
        _completeOnboarding();
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
    if (mounted) {
      // Route to Speaker DNA quiz if not already taken
      final hasDNA = prefs.getString('speaker_dna') != null;
      if (hasDNA) {
        context.go('/home');
      } else {
        context.go('/speaker-dna-quiz');
      }
    }
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? imagePath;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.imagePath,
  });
}
