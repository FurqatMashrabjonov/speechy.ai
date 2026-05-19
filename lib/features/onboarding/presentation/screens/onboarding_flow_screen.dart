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
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
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
  String? _selectedEventDate;

  static const _totalPages = 4;

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
    final isLastPage = _currentPage == _totalPages - 1;
    final canProceed = !isLastPage || _selectedEventDate != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLastPage)
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

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildInfoPage(_pages[index]);
                  }
                  return _buildEventDatePage();
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
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

            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: DuoButton(
                text: isLastPage ? 'Build My Plan' : 'Next',
                width: double.infinity,
                color: AppColors.primary,
                shadowColor: AppColors.primaryDark,
                disabled: !canProceed,
                onTap: () {
                  if (!isLastPage) {
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

  Widget _buildInfoPage(_OnboardingPage page) {
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

  Widget _buildEventDatePage() {
    final options = [
      _EventDateOption(
        id: 'this_week',
        emoji: '🔥',
        label: 'This week',
        sublabel: 'Intensive mode — 3 sessions/day',
        color: AppColors.error,
      ),
      _EventDateOption(
        id: 'this_month',
        emoji: '📅',
        label: 'This month',
        sublabel: '1 session/day, steady pace',
        color: AppColors.primary,
      ),
      _EventDateOption(
        id: 'two_months',
        emoji: '🗓️',
        label: 'In 2+ months',
        sublabel: 'Relaxed — every other day',
        color: AppColors.secondary,
      ),
      _EventDateOption(
        id: 'no_date',
        emoji: '🎯',
        label: 'Just exploring',
        sublabel: 'Go at your own pace',
        color: AppColors.lime,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When\'s your next big moment?',
            style: AppTypography.displaySmall(),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'We\'ll build your roadmap around your timeline.',
            style: AppTypography.bodyLarge(color: context.textSecondary),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 32),
          ...options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final selected = _selectedEventDate == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Tappable(
                onTap: () => setState(() => _selectedEventDate = opt.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? opt.color.withValues(alpha: 0.08)
                        : context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? opt.color
                          : context.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(opt.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: AppTypography.titleMedium(
                                color: selected ? opt.color : null,
                              ),
                            ),
                            Text(
                              opt.sublabel,
                              style: AppTypography.labelSmall(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: opt.color,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(
                  delay: (200 + i * 80).ms,
                  duration: 300.ms,
                );
          }),
        ],
      ),
    );
  }

  Future<void> _requestMicPermission() async {
    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    await recorder.dispose();

    if (!mounted) return;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone access is needed for voice conversations. Enable it in Settings.',
          ),
        ),
      );
    }
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
    if (_selectedEventDate != null) {
      await prefs.setString('onboarding_event_date', _selectedEventDate!);
    }
    if (!mounted) return;
    final hasAssessment = ref.read(hasAssessmentProvider);
    if (hasAssessment) {
      context.go('/home');
    } else {
      context.go('/assessment');
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

class _EventDateOption {
  final String id;
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;

  const _EventDateOption({
    required this.id,
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
  });
}
