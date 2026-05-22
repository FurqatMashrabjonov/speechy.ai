import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
const _kIntroPage    = 0;
const _kQuestionCount = 6;
const _kRoadmapPage  = _kIntroPage + 1 + _kQuestionCount; // 7
const _kWidgetPage   = _kRoadmapPage + 1;                  // 8
const _kNotifPage    = _kWidgetPage + 1;                   // 9
const _kLoginPage    = _kNotifPage + 1;                    // 10

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
  String _recommendedTemplateId = 'well_rounded';
  String _selectedTemplateId    = 'well_rounded';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  void _goTo(int page) => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );

  void _next() => _goTo(_currentPage + 1);

  Future<void> _goToLogin() async {
    HapticFeedback.lightImpact();
    await _markOnboardingDone();
    _goTo(_kLoginPage);
  }

  void _onOptionSelected(String questionId, String optionId, {required bool isLast}) {
    isLast
        ? HapticFeedback.mediumImpact()
        : HapticFeedback.selectionClick();
    setState(() => _answers[questionId] = optionId);

    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      if (isLast) {
        // Compute recommendation, go to roadmap selection
        final answers = _answers.entries
            .map((e) => AssessmentAnswer(questionId: e.key, optionId: e.value))
            .toList();
        final recommended = matchTemplate(answers);
        setState(() {
          _recommendedTemplateId = recommended;
          _selectedTemplateId = recommended;
        });
        _next();
      } else {
        _next();
      }
    });
  }

  Future<void> _confirmRoadmap() async {
    HapticFeedback.heavyImpact();
    setState(() => _generatingPlan = true);
    try {
      final answers = _answers.entries
          .map((e) => AssessmentAnswer(questionId: e.key, optionId: e.value))
          .toList();
      await ref
          .read(learningPlanProvider.notifier)
          .generateForTemplate(_selectedTemplateId, answers);
    } catch (_) {}
    if (mounted) {
      setState(() => _generatingPlan = false);
      _next();
    }
  }

  Future<void> _requestNotifications() async {
    HapticFeedback.mediumImpact();
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

  Future<void> _onLoginDone() async {
    await _markOnboardingDone();
    if (!mounted) return;
    context.go('/home');
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
                    if (_currentPage > _kIntroPage &&
                        _currentPage <= _kRoadmapPage)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _goTo(_currentPage - 1);
                        },
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
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
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
                    onGetStarted: () {
                      HapticFeedback.heavyImpact();
                      _next();
                    },
                    onAlreadyHaveAccount: _goToLogin,
                  ),

                  // 1-6 — Questions
                  for (int i = 0; i < _kQuestionCount; i++)
                    _QuestionPage(
                      question: assessmentQuestions[i],
                      selectedOptionId: _answers[assessmentQuestions[i].id],
                      isLast: i == _kQuestionCount - 1,
                      onSelect: (optionId) => _onOptionSelected(
                        assessmentQuestions[i].id,
                        optionId,
                        isLast: i == _kQuestionCount - 1,
                      ),
                    ),

                  // 7 — Roadmap selection
                  _RoadmapSelectionPage(
                    recommendedId: _recommendedTemplateId,
                    selectedId: _selectedTemplateId,
                    isGenerating: _generatingPlan,
                    onSelect: (id) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTemplateId = id);
                    },
                    onConfirm: _confirmRoadmap,
                  ),

                  // 8 — Widget
                  _WidgetPage(
                    onContinue: () {
                      HapticFeedback.lightImpact();
                      _next();
                    },
                  ),

                  // 9 — Notifications
                  _NotifPage(
                    onAllow: _requestNotifications,
                    onSkip: () {
                      HapticFeedback.lightImpact();
                      _next();
                    },
                  ),

                  // 10 — Login
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

// ─── Intro Page ───────────────────────────────────────────────────────────────

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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 56),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text('Speechy AI', style: AppTypography.displayLarge(), textAlign: TextAlign.center)
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
          Text(
            'Your personal AI speaking coach',
            style: AppTypography.bodyLarge(color: context.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const Spacer(flex: 2),
          DuoButton.primary(
            text: 'Get Started',
            width: double.infinity,
            onTap: onGetStarted,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),
          const SizedBox(height: 14),
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
  final bool isLast;
  final ValueChanged<String> onSelect;

  const _QuestionPage({
    required this.question,
    required this.selectedOptionId,
    required this.isLast,
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
              _MascotIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: context.divider),
                  ),
                  child: Text(question.text, style: AppTypography.titleMedium()),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 28),
          ...question.options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            final isSelected = option.id == selectedOptionId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFE5E5E5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(option.emoji,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option.label,
                          style: AppTypography.titleMedium(
                            color: isSelected
                                ? AppColors.primary
                                : context.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE5E5E5),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(
                delay: Duration(milliseconds: 60 + i * 60)).slideY(begin: 0.1);
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Roadmap Selection Page ───────────────────────────────────────────────────

class _RoadmapSelectionPage extends StatelessWidget {
  final String recommendedId;
  final String selectedId;
  final bool isGenerating;
  final ValueChanged<String> onSelect;
  final VoidCallback onConfirm;

  const _RoadmapSelectionPage({
    required this.recommendedId,
    required this.selectedId,
    required this.isGenerating,
    required this.onSelect,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Mascot + speech bubble
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MascotIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                    'I picked the best track for you — but you can change it!',
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allRoadmapMetas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final meta = allRoadmapMetas[i];
              final isRecommended = meta.id == recommendedId;
              final isSelected = meta.id == selectedId;

              return GestureDetector(
                onTap: () => onSelect(meta.id),
                child: isRecommended
                    ? _ExpandedRoadmapCard(
                        meta: meta,
                        isSelected: isSelected,
                      )
                    : _CompactRoadmapCard(
                        meta: meta,
                        isSelected: isSelected,
                      ),
              ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50));
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
          child: isGenerating
              ? const Center(child: CircularProgressIndicator())
              : DuoButton.primary(
                  text: 'Start My Journey',
                  icon: Icons.rocket_launch_rounded,
                  width: double.infinity,
                  onTap: onConfirm,
                ).animate().fadeIn(delay: 300.ms),
        ),
      ],
    );
  }
}

// ─── Roadmap Cards ────────────────────────────────────────────────────────────

class _ExpandedRoadmapCard extends StatelessWidget {
  final RoadmapMeta meta;
  final bool isSelected;

  const _ExpandedRoadmapCard({required this.meta, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSelected
            ? meta.color.withValues(alpha: 0.09)
            : meta.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? meta.color : meta.color.withValues(alpha: 0.4),
          width: isSelected ? 2.5 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(meta.emoji,
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: meta.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Best match for you',
                        style: AppTypography.labelSmall(color: Colors.white)
                            .copyWith(
                                fontWeight: FontWeight.w700, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta.title,
                      style: AppTypography.headlineSmall(color: meta.color),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? meta.color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? meta.color : meta.color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 15, color: Colors.white)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meta.description,
            style: AppTypography.bodySmall(color: context.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.format_list_numbered_rounded,
                label: '${meta.stepCount} steps',
                color: meta.color,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.trending_up_rounded,
                label: meta.difficultyLabel,
                color: meta.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactRoadmapCard extends StatelessWidget {
  final RoadmapMeta meta;
  final bool isSelected;

  const _CompactRoadmapCard({required this.meta, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? meta.color.withValues(alpha: 0.08) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? meta.color : const Color(0xFFE5E5E5),
          width: isSelected ? 2.5 : 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child:
                  Text(meta.emoji, style: const TextStyle(fontSize: 21)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: AppTypography.titleMedium(
                      color: isSelected ? meta.color : context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  meta.description,
                  style:
                      AppTypography.bodySmall(color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isSelected ? meta.color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? meta.color : const Color(0xFFE5E5E5),
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    size: 13, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall(color: color)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
          ),
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mascot bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MascotIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    'We have a home screen widget — see your streak without opening the app!',
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 24),
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
                Row(
                  children: [
                    const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 8),
                    Text('Speechy AI',
                        style:
                            AppTypography.titleMedium(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Tap to practice today',
                    style: AppTypography.bodySmall(
                        color: Colors.white.withValues(alpha: 0.75))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('0 day streak',
                        style: AppTypography.labelSmall(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms).scale(
                begin: const Offset(0.92, 0.92),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),
          Text('How to add it',
                  style: AppTypography.titleMedium())
              .animate()
              .fadeIn(delay: 250.ms),
          const SizedBox(height: 12),
          ...[
            (
              icon: Icons.touch_app_rounded,
              step: '1',
              text: 'Long press empty area on your home screen',
            ),
            (
              icon: Icons.add_circle_outline_rounded,
              step: '2',
              text: 'Tap "+" or "Edit" → "Add Widget"',
            ),
            (
              icon: Icons.search_rounded,
              step: '3',
              text: 'Search for "Speechy"',
            ),
            (
              icon: Icons.widgets_rounded,
              step: '4',
              text: 'Select the widget and tap "Add Widget"',
            ),
          ].asMap().entries.map((e) {
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.icon,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.text,
                        style: AppTypography.bodyMedium(
                            color: context.textPrimary)),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 300 + e.key * 60))
                  .slideX(begin: 0.05),
            );
          }),
          const SizedBox(height: 28),
          DuoButton.primary(
            text: 'Got it!',
            icon: Icons.thumb_up_rounded,
            width: double.infinity,
            onTap: onContinue,
          ).animate().fadeIn(delay: 550.ms),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onContinue,
            child: Center(
              child: Text(
                'Maybe later',
                style: AppTypography.labelMedium(
                    color: context.textSecondary),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MascotIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                    'Can I remind you to practice every day?',
                    style: AppTypography.titleMedium(),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 28),
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
                  child:
                      const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Speechy AI', style: AppTypography.labelMedium()),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to practice? Step 1 is waiting for you.',
                        style: AppTypography.bodySmall(
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
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
            child: Text('Not now',
                style:
                    AppTypography.bodyMedium(color: context.textSecondary)),
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
  const _LoginPage({required this.onDone, required this.onAlreadyHaveAccount});

  @override
  ConsumerState<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<_LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscure = true;
  bool _isRegisterMode = true; // default register for new users from onboarding

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final notifier = ref.read(authNotifierProvider.notifier);
    final bool success;
    if (_isRegisterMode) {
      success = await notifier.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else {
      success = await notifier.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
    if (success && mounted) {
      HapticFeedback.heavyImpact();
      widget.onDone();
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 32),

            Text(
              _isRegisterMode ? 'Create Account' : 'Sign In',
              style: AppTypography.displaySmall(),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 6),

            Text(
              'Practice speaking. Build confidence.',
              style: AppTypography.bodyMedium(color: context.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 80.ms),

            const SizedBox(height: 28),

            // Google
            _OnboardingGoogleButton(
              isLoading: authState.isLoading,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
                if (success && mounted) {
                  HapticFeedback.heavyImpact();
                  widget.onDone();
                }
              },
            ).animate().fadeIn(delay: 120.ms),

            if (Platform.isIOS && kReleaseMode) ...[
              const SizedBox(height: 12),
              _OnboardingAppleButton(
                isLoading: authState.isLoading,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final success = await ref.read(authNotifierProvider.notifier).signInWithApple();
                  if (success && mounted) {
                    HapticFeedback.heavyImpact();
                    widget.onDone();
                  }
                },
              ).animate().fadeIn(delay: 160.ms),
            ],

            const SizedBox(height: 22),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: AppTypography.labelMedium(color: context.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 18),

            // Name (register only)
            if (_isRegisterMode) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
            ],

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Password
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
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (_isRegisterMode && v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isRegisterMode ? 'Create Account' : 'Sign In',
                        style: AppTypography.titleMedium(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRegisterMode ? 'Already have an account? ' : "Don't have an account? ",
                  style: AppTypography.bodyMedium(color: context.textSecondary),
                ),
                Tappable(
                  onTap: () => setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _nameController.clear();
                  }),
                  child: Text(
                    _isRegisterMode ? 'Sign In' : 'Sign Up',
                    style: AppTypography.bodyMedium(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'By continuing, you agree to our Terms & Privacy Policy.',
              style: AppTypography.labelSmall(color: context.textTertiary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Mascot Icon ───────────────────────────────────────────────────────

class _MascotIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
    );
  }
}

// ─── Onboarding Social Buttons ────────────────────────────────────────────────

class _OnboardingGoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _OnboardingGoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/google_logo.svg', width: 22, height: 22),
            const SizedBox(width: 12),
            Text('Continue with Google', style: AppTypography.titleMedium()),
          ],
        ),
      ),
    );
  }
}

class _OnboardingAppleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _OnboardingAppleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple_rounded, size: 24),
            const SizedBox(width: 12),
            Text('Continue with Apple', style: AppTypography.titleMedium()),
          ],
        ),
      ),
    );
  }
}
