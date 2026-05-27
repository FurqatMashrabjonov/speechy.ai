import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/feedback/domain/feedback_entity.dart';
import 'package:speech_coach/shared/widgets/coach_tip_card.dart';
import 'package:speech_coach/shared/widgets/progress_bar.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/score_ring.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/feedback/presentation/providers/feedback_provider.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/assessment/domain/learning_plan_entity.dart';
import 'package:speech_coach/shared/utils/filler_detector.dart';
import 'package:speech_coach/shared/utils/hedging_detector.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/features/paywall/data/usage_service.dart';
import 'package:speech_coach/features/notifications/data/notification_service.dart';
import 'package:speech_coach/shared/services/sound_service.dart';
import 'package:speech_coach/core/analytics/analytics_service.dart';

class ScoreCardScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String scenarioId;
  final String scenarioTitle;
  final String category;
  final String transcript;
  final int? previousScore;
  final String scenarioPrompt;
  final int durationSeconds;

  const ScoreCardScreen({
    super.key,
    this.sessionId,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.category,
    this.transcript = '',
    this.previousScore,
    this.scenarioPrompt = '',
    this.durationSeconds = 0,
  });

  @override
  ConsumerState<ScoreCardScreen> createState() => _ScoreCardScreenState();
}

class _ScoreCardScreenState extends ConsumerState<ScoreCardScreen>
    with TickerProviderStateMixin {
  bool _xpAwarded = false;
  bool _sessionSaved = false;
  bool _reviewChecked = false;
  bool _celebrationShown = false;
  ChainResult? _chainResult;
  Map<String, int> _fillerWords = {};
  Map<String, int> _hedgingWords = {};
  int? _wpm;
  String? _trackId;
  int? _stepOrder;

  late ConfettiController _confettiController;
  final _scoreRingKey = GlobalKey();
  Offset? _confettiOrigin;

  // Loading animation state
  late AnimationController _pulseController;
  late AnimationController _progressController;
  int _currentStep = 0;
  int _currentTipIndex = 0;

  static const _analysisSteps = [
    ('Processing your conversation', Icons.chat_bubble_rounded),
    ('Evaluating clarity & structure', Icons.waves_rounded),
    ('Measuring confidence level', Icons.shield_rounded),
    ('Analyzing engagement', Icons.people_rounded),
    ('Checking relevance', Icons.track_changes_rounded),
    ('Generating personalized feedback', Icons.auto_awesome_rounded),
  ];

  static const _tips = [
    'Speaking at 120-150 words per minute is ideal for most conversations.',
    'Pausing before key points makes them 40% more memorable.',
    'Using specific examples makes your arguments twice as persuasive.',
    'Mirror the energy of your conversation partner to build rapport.',
    'Ending with a clear takeaway leaves a lasting impression.',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 100));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..forward();

    // Animate through steps
    _animateSteps();
  }

  void _animateSteps() async {
    for (var i = 0; i < _analysisSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackProvider);

    if (feedbackState.status == FeedbackStatus.loaded &&
        feedbackState.feedback != null &&
        !_xpAwarded) {
      _xpAwarded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(progressProvider.notifier).addSession(feedbackState.feedback!);

        // Log session completed
        final fb = feedbackState.feedback!;
        AnalyticsService.instance.logSessionCompleted(
          scenarioId: widget.scenarioId,
          trackId: _trackId ?? '',
          score: fb.overallScore.round(),
          durationSeconds: fb.durationSeconds,
          result: fb.overallScore >= 75 ? 'passed' : 'needs_retry',
        );

        if (widget.transcript.isNotEmpty) {
          final fillers = FillerDetector.detect(widget.transcript);
          final userWords = widget.transcript
              .split('\n')
              .where((l) => l.startsWith('User:'))
              .map(
                (l) => l
                    .replaceFirst('User:', '')
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((w) => w.isNotEmpty)
                    .length,
              )
              .fold(0, (a, b) => a + b);
          final durationSecs = feedbackState.feedback!.durationSeconds;
          final wpm =
              durationSecs > 0 ? (userWords / (durationSecs / 60)).round() : null;
          final hedging = HedgingDetector.detect(widget.transcript);
          if (mounted) setState(() { _fillerWords = fillers; _wpm = wpm; _hedgingWords = hedging; });
        }

        // Record session against free quota — track per-step usage if in a track
        {
          final plan = ref.read(learningPlanProvider);
          PlanStep? matchingStep;
          if (plan != null && widget.scenarioId.isNotEmpty) {
            for (final s in plan.steps) {
              if (s.scenarioId == widget.scenarioId) {
                matchingStep = s;
                break;
              }
            }
          }
          if (matchingStep != null && plan != null) {
            setState(() {
              _trackId = plan.templateId;
              _stepOrder = matchingStep!.order;
            });
          }
          ref.read(usageServiceProvider).recordSession(
            trackId: matchingStep != null ? plan?.templateId : null,
            stepOrder: matchingStep?.order,
          );
        }

        // Mark learning plan step as completed, capture chain result
        ref
            .read(learningPlanProvider.notifier)
            .markCompleted(
              widget.scenarioId,
              feedbackState.feedback!.overallScore.toDouble(),
            )
            .then((result) {
              if (mounted) setState(() => _chainResult = result);
              if (result == ChainResult.passed) {
                SoundService.instance.stepPassed();
                NotificationService.scheduleStepUnlocked(widget.scenarioTitle);
              }
              // Reschedule daily reminder with updated next-step info
              final plan = ref.read(learningPlanProvider);
              if (plan != null) {
                final next = plan.nextStep;
                final stepNumber = next != null ? (next.order + 1) : plan.steps.length;
                NotificationService.scheduleDailyReminder(
                  currentStep: stepNumber,
                  trackTitle: plan.title,
                );
              }
            });

        if (!_sessionSaved) {
          _sessionSaved = true;
          // Save feedback to Firestore in background (non-blocking)
          if (widget.sessionId != null) {
            ref
                .read(pendingSessionSaverProvider)
                .completeFeedback(
                  sessionId: widget.sessionId!,
                  feedback: feedbackState.feedback!,
                )
                .timeout(const Duration(seconds: 5))
                .catchError((e) {
                  debugPrint(
                    'ScoreCard: completeFeedback failed (non-critical): $e',
                  );
                });
          } else {
            ref
                .read(saveSessionProvider)
                .save(
                  scenarioId: widget.scenarioId,
                  scenarioTitle: widget.scenarioTitle,
                  category: widget.category,
                  feedback: feedbackState.feedback!,
                  transcript: widget.transcript,
                )
                .timeout(const Duration(seconds: 5))
                .catchError((e) {
                  debugPrint(
                    'ScoreCard: saveSession failed (non-critical): $e',
                  );
                });
          }
        }

        if (!_reviewChecked) {
          _reviewChecked = true;
          _maybeRequestReview(feedbackState.feedback!);
        }

        if (!_celebrationShown && _confettiController.state != ConfettiControllerState.playing) {
          _celebrationShown = true;
          SoundService.instance.celebration();
          _burstConfettiFromScoreRing();
        }

      });
    }

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: switch (feedbackState.status) {
              FeedbackStatus.idle || FeedbackStatus.loading => _buildLoading(),
              FeedbackStatus.loaded => _buildScoreCard(feedbackState.feedback!),
              FeedbackStatus.error => _buildError(feedbackState.error),
            },
          ),
        ),
        if (_confettiOrigin != null)
          Positioned(
            left: _confettiOrigin!.dx,
            top: _confettiOrigin!.dy,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 6,
              gravity: 0.5,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.9,
              particleDrag: 0.1,
              colors: const [
                AppColors.primary,
                AppColors.success,
                AppColors.gold,
                Color(0xFF7C5CBF),
                Color(0xFF4FC3F7),
                Color(0xFFFF6B6B),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Pulsing AI icon with rings
          SizedBox(
            width: 130,
            height: 130,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                final outerOpacity = 0.08 + (_pulseController.value * 0.06);
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: 120 * scale,
                        height: 120 * scale,
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          color: AppColors.primary.withValues(
                            alpha: outerOpacity,
                          ),
                        ),
                      ),
                      // Inner ring
                      Container(
                        width: 90,
                        height: 90,
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const ShapeDecoration(
                          shape: CircleBorder(),
                          color: AppColors.primary,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Analyzing your speech...',
            style: AppTypography.headlineSmall(),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            'Our AI coach is reviewing your performance',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: context.textSecondary),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 32),

          // Animated progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                // Progress moves fast at first, slows down near end
                final t = _progressController.value;
                final eased = t < 0.7
                    ? (t / 0.7) * 0.85
                    : 0.85 + ((t - 0.7) / 0.3) * 0.1;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _currentStep < _analysisSteps.length
                                ? _analysisSteps[_currentStep].$1
                                : 'Almost done...',
                            style: AppTypography.labelSmall(
                              color: context.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(eased * 100).toInt()}%',
                          style: AppTypography.labelSmall(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          value: eased.clamp(0.0, 0.95),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5E5E5),
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Analysis steps checklist
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _analysisSteps.length; i++)
                  _AnalysisStepRow(
                    label: _analysisSteps[i].$1,
                    icon: _analysisSteps[i].$2,
                    state: i < _currentStep
                        ? _StepState.done
                        : i == _currentStep
                        ? _StepState.active
                        : _StepState.pending,
                    isLast: i == _analysisSteps.length - 1,
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Cycling pro tips
          _CyclingTipCard(
            tips: _tips,
            currentIndex: _currentTipIndex,
            onTick: () {
              if (mounted) {
                setState(
                  () =>
                      _currentTipIndex = (_currentTipIndex + 1) % _tips.length,
                );
              }
            },
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildError(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not analyze conversation',
              style: AppTypography.headlineSmall(),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: context.textSecondary),
            ),
            const SizedBox(height: 24),
            if (widget.transcript.isNotEmpty) ...[
              DuoButton.primary(
                text: 'Retry Analysis',
                icon: Icons.refresh_rounded,
                onTap: () {
                  ref.read(feedbackProvider.notifier).reset();
                  ref.read(feedbackProvider.notifier).analyzeConversation(
                    transcript: widget.transcript,
                    category: widget.category,
                    scenarioTitle: widget.scenarioTitle,
                    scenarioPrompt: widget.scenarioPrompt,
                    scenarioId: widget.scenarioId,
                    durationSeconds: widget.durationSeconds,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            Tappable(
              onTap: () => context.go('/home'),
              child: Text(
                'Go Home',
                style: AppTypography.labelMedium(color: context.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(ConversationFeedback feedback) {
    return Column(
      children: [
        // App bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Tappable(
                onTap: () => context.go('/home'),
                child: const Icon(Icons.close_rounded, size: 24),
              ),
              const Spacer(),
              Text('Session Feedback', style: AppTypography.titleMedium()),
              const Spacer(),
              const SizedBox(width: 24),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Decorative floating elements
                    SizedBox(
                          height: 40,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 30,
                                child: Transform.rotate(
                                  angle: -0.3,
                                  child:
                                      Icon(
                                            Icons.star_rounded,
                                            size: 20,
                                            color: AppColors.gold.withValues(
                                              alpha: 0.2,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) =>
                                                controller.repeat(),
                                          )
                                          .moveY(
                                            begin: 0,
                                            end: 8,
                                            duration: 2.seconds,
                                            curve: Curves.easeInOutSine,
                                          )
                                          .then()
                                          .moveY(
                                            begin: 8,
                                            end: 0,
                                            duration: 2.seconds,
                                            curve: Curves.easeInOutSine,
                                          ),
                                ),
                              ),
                              Positioned(
                                right: 40,
                                top: 10,
                                child: Transform.rotate(
                                  angle: 0.4,
                                  child:
                                      Icon(
                                            Icons.favorite_rounded,
                                            size: 16,
                                            color: AppColors.primary.withValues(
                                              alpha: 0.15,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) =>
                                                controller.repeat(),
                                          )
                                          .moveY(
                                            begin: 0,
                                            end: -6,
                                            duration: 1.8.seconds,
                                            curve: Curves.easeInOutSine,
                                          )
                                          .then()
                                          .moveY(
                                            begin: -6,
                                            end: 0,
                                            duration: 1.8.seconds,
                                            curve: Curves.easeInOutSine,
                                          ),
                                ),
                              ),
                              Positioned(
                                left: 80,
                                top: 5,
                                child: Transform.rotate(
                                  angle: 0.2,
                                  child:
                                      Icon(
                                            Icons.celebration_rounded,
                                            size: 18,
                                            color: AppColors.success.withValues(
                                              alpha: 0.15,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) =>
                                                controller.repeat(),
                                          )
                                          .moveY(
                                            begin: 0,
                                            end: 5,
                                            duration: 1.5.seconds,
                                            curve: Curves.easeInOutSine,
                                          )
                                          .then()
                                          .moveY(
                                            begin: 5,
                                            end: 0,
                                            duration: 1.5.seconds,
                                            curve: Curves.easeInOutSine,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.elasticOut,
                        ),

                    // Score Ring
                    Builder(
                          builder: (context) => ScoreRing(
                            key: _scoreRingKey,
                            score: feedback.overallScore,
                            size: 160,
                            strokeWidth: 6,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 4),

                    const SizedBox(height: 8),

                    // Label
                    Text(
                      _getScoreLabel(feedback.overallScore),
                      style: AppTypography.headlineMedium(
                        color: _getScoreColor(feedback.overallScore),
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    // Score delta (correction loop comparison)
                    if (widget.previousScore != null) ...[
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final delta = feedback.overallScore - widget.previousScore!;
                        final improved = delta > 0;
                        final color = improved ? AppColors.success : AppColors.warning;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                improved
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_flat_rounded,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                improved
                                    ? '+$delta from last attempt'
                                    : '$delta from last attempt',
                                style: AppTypography.labelMedium(color: color)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    ],
                    const SizedBox(height: 16),

                    // Focus Card — #1 priority
                    if (feedback.focusPriority != null &&
                        feedback.focusChallenge != null) ...[
                      _FocusCard(
                        priority: feedback.focusPriority!,
                        challenge: feedback.focusChallenge!,
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                    ],

                    // Delivery metrics
                    _DeliveryCard(
                      fillerWords: _fillerWords,
                      hedgingWords: _hedgingWords,
                      wpm: _wpm,
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // Content Breakdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Content', style: AppTypography.titleMedium()),
                          const SizedBox(height: 16),
                          ProgressBar(
                            value: feedback.clarity / 100,
                            label: 'Clarity',
                            trailingText: '${feedback.clarity}%',
                            icon: Icons.waves_rounded,
                            delay: const Duration(milliseconds: 50),
                          ),
                          const SizedBox(height: 14),
                          ProgressBar(
                            value: feedback.confidence / 100,
                            label: 'Confidence',
                            trailingText: '${feedback.confidence}%',
                            icon: Icons.shield_rounded,
                            delay: const Duration(milliseconds: 150),
                          ),
                          const SizedBox(height: 14),
                          ProgressBar(
                            value: feedback.engagement / 100,
                            label: 'Engagement',
                            trailingText: '${feedback.engagement}%',
                            icon: Icons.people_rounded,
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 14),
                          ProgressBar(
                            value: feedback.relevance / 100,
                            label: 'Relevance',
                            trailingText: '${feedback.relevance}%',
                            icon: Icons.track_changes_rounded,
                            delay: const Duration(milliseconds: 350),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // Transcript moment — AI-identified problem quote
                    if (feedback.transcriptMoment != null &&
                        feedback.transcriptMoment!.isNotEmpty) ...[
                      _TranscriptMomentCard(moment: feedback.transcriptMoment!)
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                    ],

                    // Coach summary
                    CoachTipCard(
                      tip: feedback.summary.isNotEmpty
                          ? feedback.summary
                          : 'Try to maintain eye contact and use pauses effectively to emphasize key points.',
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // Strengths
                    if (feedback.strengths.isNotEmpty)
                      _FeedbackList(
                        title: 'Strengths',
                        items: feedback.strengths,
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                      ),
                    if (feedback.strengths.isNotEmpty)
                      const SizedBox(height: 16),

                    // Improvements
                    if (feedback.improvements.isNotEmpty)
                      _FeedbackList(
                        title: 'Areas to Improve',
                        items: feedback.improvements,
                        icon: Icons.arrow_upward_rounded,
                        iconColor: AppColors.warning,
                      ),
                    if (feedback.improvements.isNotEmpty)
                      const SizedBox(height: 16),

                    // Transcript
                    if (widget.transcript.isNotEmpty) ...[
                      _TranscriptSection(transcript: widget.transcript)
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 16),
                    ],

                    // Chain Result Banner
                    if (_chainResult != null)
                      _ChainResultBanner(
                        result: _chainResult!,
                        canRetry: _canRetry,
                        onNextStep: () => context.go('/home'),
                        onRetry: () => _retryWithFocus(feedback),
                        onPaywall: _openPaywall,
                      ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
                          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                    if (_chainResult != null) const SizedBox(height: 16),

                    const SizedBox(height: 24),
                  ],
                ),
          ),
        ),

        // Bottom actions
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Builder(builder: (context) {
            final feedback = ref.watch(feedbackProvider).feedback;
            final hasFocus = feedback?.focusPriority != null;
            final passed = _chainResult == ChainResult.passed;
            final needsRetry = _chainResult == ChainResult.needsRetry;
            final noRetries = needsRetry && !_canRetry && _trackId != null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DuoButton.primary(
                  text: passed
                      ? 'Continue Track'
                      : noRetries
                          ? 'Unlock Retries'
                          : needsRetry
                              ? 'Try Again'
                              : 'Continue Learning',
                  icon: passed
                      ? Icons.rocket_launch_rounded
                      : noRetries
                          ? Icons.lock_open_rounded
                          : Icons.arrow_forward_rounded,
                  width: double.infinity,
                  onTap: () {
                    if (noRetries) {
                      _openPaywall();
                    } else if (needsRetry && feedback != null) {
                      _retryWithFocus(feedback);
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                // Practice Again — available after passing when we have focus context
                if (passed && hasFocus && feedback != null) ...[
                  const SizedBox(height: 8),
                  Tappable(
                    onTap: () => _retryWithFocus(feedback),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              size: 18, color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Text(
                            'Practice Again — Focus on ${feedback.focusPriority}',
                            style: AppTypography.labelMedium(
                                    color: const Color(0xFFE65100))
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: Tappable(
                    onTap: () => context.go('/home'),
                    child: Text(
                      'Go Home',
                      style: AppTypography.labelMedium(
                          color: context.textSecondary),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  void _retryWithFocus(ConversationFeedback feedback) {
    context.push(
      '/scenario/${Uri.encodeComponent(widget.scenarioId)}',
      extra: {
        if (_trackId != null) 'trackId': _trackId,
        if (_stepOrder != null) 'stepOrder': _stepOrder,
        if (feedback.focusPriority != null) 'focusPriority': feedback.focusPriority,
        if (feedback.focusChallenge != null) 'focusChallenge': feedback.focusChallenge,
        'previousScore': feedback.overallScore,
      },
    );
  }

  bool get _canRetry {
    if (_trackId == null || _stepOrder == null) return false;
    return ref.read(usageServiceProvider).canAttemptStep(_trackId!, _stepOrder!);
  }

  void _openPaywall() {
    final plan = ref.read(learningPlanProvider);
    if (plan == null) return;
    context.push('/paywall', extra: {
      'trackId': plan.templateId,
      'trackTitle': plan.title,
    });
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent Work!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Good Work!';
    if (score >= 50) return 'Keep Going!';
    return 'Keep Practicing!';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  void _burstConfettiFromScoreRing() {
    final box = _scoreRingKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final center = box.localToGlobal(box.size.center(Offset.zero));
      setState(() => _confettiOrigin = center);
    }
    _confettiController.play();
  }

  Future<void> _maybeRequestReview(ConversationFeedback feedback) async {
    if (feedback.overallScore < 75) return;

    final progress = ref.read(progressProvider);
    if (progress.totalSessions < 5) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_requested_review') == true) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await prefs.setBool('has_requested_review', true);
      await inAppReview.requestReview();
    }
  }

}

// --- Loading animation helpers ---

enum _StepState { pending, active, done }

class _AnalysisStepRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final _StepState state;
  final bool isLast;

  const _AnalysisStepRow({
    required this.label,
    required this.icon,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = state == _StepState.done
        ? AppColors.success
        : state == _StepState.active
        ? AppColors.primary.withValues(alpha: 0.15)
        : const Color(0xFFF0F0F0);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          // Status indicator — plain Container (no AnimatedContainer to avoid circle+borderRadius conflict)
          Container(
            width: 28,
            height: 28,
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: circleColor,
            ),
            alignment: Alignment.center,
            child: state == _StepState.done
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.white,
                  )
                : state == _StepState.active
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(icon, size: 14, color: const Color(0xFFBBBBBB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style:
                  AppTypography.bodySmall(
                    color: state == _StepState.done
                        ? AppColors.success
                        : state == _StepState.active
                        ? context.textPrimary
                        : context.textTertiary,
                  ).copyWith(
                    fontWeight: state == _StepState.active
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
            ),
          ),
          if (state == _StepState.done)
            Text(
                  'Done',
                  style: AppTypography.labelSmall(color: AppColors.success),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }
}

class _CyclingTipCard extends StatefulWidget {
  final List<String> tips;
  final int currentIndex;
  final VoidCallback onTick;

  const _CyclingTipCard({
    required this.tips,
    required this.currentIndex,
    required this.onTick,
  });

  @override
  State<_CyclingTipCard> createState() => _CyclingTipCardState();
}

class _CyclingTipCardState extends State<_CyclingTipCard> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex;
    _startCycling();
  }

  void _startCycling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.tips.length);
      widget.onTick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DID YOU KNOW?',
                  style: AppTypography.labelSmall(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    widget.tips[_index],
                    key: ValueKey(_index),
                    style: AppTypography.bodySmall(
                      color: context.textSecondary,
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

class _FeedbackList extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  const _FeedbackList({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: AppTypography.titleMedium()),
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyMedium(
                          color: context.textPrimary,
                        ).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
              .animate(delay: (200 + (index * 150)).ms)
              .fadeIn(duration: 400.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              );
        }),
      ],
    );
  }
}

// ── Focus Card ────────────────────────────────────────────────────────────────

class _FocusCard extends StatelessWidget {
  final String priority;
  final String challenge;

  const _FocusCard({required this.priority, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFF8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.center_focus_strong_rounded,
                color: Color(0xFFE65100), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'FOCUS THIS SESSION',
                      style: AppTypography.labelSmall(color: const Color(0xFFE65100))
                          .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  priority,
                  style: AppTypography.titleMedium(color: const Color(0xFF4E2600))
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  challenge,
                  style: AppTypography.bodySmall(color: const Color(0xFF6D3A00)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery Card ─────────────────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  final Map<String, int> fillerWords;
  final Map<String, int> hedgingWords;
  final int? wpm;

  const _DeliveryCard({
    required this.fillerWords,
    required this.hedgingWords,
    required this.wpm,
  });

  Color _fillerColor(int count) {
    if (count > 10) return AppColors.error;
    if (count > 4) return AppColors.warning;
    return AppColors.success;
  }

  Color _wpmColor(int wpm) {
    if (wpm >= 100 && wpm <= 165) return AppColors.success;
    if (wpm > 165 && wpm <= 185) return AppColors.warning;
    if (wpm < 100 && wpm >= 80) return AppColors.warning;
    return AppColors.error;
  }

  Color _hedgingColor(int count) {
    if (count > 6) return AppColors.error;
    if (count > 2) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final fillerTotal = fillerWords.values.fold(0, (a, b) => a + b);
    final hedgingTotal = HedgingDetector.totalCount(hedgingWords);
    final hasAny = fillerTotal > 0 || hedgingTotal > 0 || wpm != null;
    if (!hasAny) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery', style: AppTypography.titleMedium()),
          const SizedBox(height: 14),
          if (fillerTotal > 0)
            _DeliveryRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Filler words',
              value: '$fillerTotal',
              benchmark: 'target: <5',
              color: _fillerColor(fillerTotal),
              subItems: fillerWords.entries
                  .toList()
                ..sort((a, b) => b.value.compareTo(a.value)),
            ),
          if (fillerTotal > 0 && (wpm != null || hedgingTotal > 0))
            const SizedBox(height: 12),
          if (wpm != null)
            _DeliveryRow(
              icon: Icons.speed_rounded,
              label: 'Speaking pace',
              value: '$wpm wpm',
              benchmark: 'optimal: 100-165',
              color: _wpmColor(wpm!),
            ),
          if (wpm != null && hedgingTotal > 0) const SizedBox(height: 12),
          if (hedgingTotal > 0)
            _DeliveryRow(
              icon: Icons.do_not_disturb_on_rounded,
              label: 'Hedging phrases',
              value: '$hedgingTotal',
              benchmark: 'target: <3',
              color: _hedgingColor(hedgingTotal),
              subItems: hedgingWords.entries
                  .toList()
                ..sort((a, b) => b.value.compareTo(a.value)),
            ),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String benchmark;
  final Color color;
  final List<MapEntry<String, int>>? subItems;

  const _DeliveryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.benchmark,
    required this.color,
    this.subItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.bodySmall(color: context.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium(color: color)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  benchmark,
                  style: AppTypography.labelSmall(color: context.textTertiary)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        if (subItems != null && subItems!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: subItems!
                .take(5)
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Text(
                        '"${e.key}" ×${e.value}',
                        style: AppTypography.bodySmall(color: color)
                            .copyWith(fontSize: 11),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ── Transcript Moment Card ────────────────────────────────────────────────────

class _TranscriptMomentCard extends StatelessWidget {
  final String moment;

  const _TranscriptMomentCard({required this.moment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                'EXAMPLE FROM YOUR SESSION',
                style: AppTypography.labelSmall(color: AppColors.error)
                    .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$moment"',
            style: AppTypography.bodyMedium(color: context.textPrimary)
                .copyWith(fontStyle: FontStyle.italic, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ChainResultBanner extends StatelessWidget {
  final ChainResult result;
  final bool canRetry;
  final VoidCallback onNextStep;
  final VoidCallback onRetry;
  final VoidCallback onPaywall;

  const _ChainResultBanner({
    required this.result,
    required this.canRetry,
    required this.onNextStep,
    required this.onRetry,
    required this.onPaywall,
  });

  @override
  Widget build(BuildContext context) {
    final passed = result == ChainResult.passed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: passed
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: passed
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.warning.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Icon + headline
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  shape: const CircleBorder(),
                  color: passed
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                ),
                child: Icon(
                  passed ? Icons.lock_open_rounded : Icons.refresh_rounded,
                  color: passed ? AppColors.success : AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passed ? 'Step Unlocked!' : 'Almost There',
                      style: AppTypography.titleMedium(
                        color: passed ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passed
                          ? 'Next step is ready on your track.'
                          : 'Score a bit higher to advance.',
                      style: AppTypography.bodySmall(
                          color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!passed) ...[
            const SizedBox(height: 14),
            if (canRetry)
              Row(
                children: [
                  Expanded(
                    child: Tappable(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Try Again',
                            style: AppTypography.labelMedium(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tappable(
                    onTap: onNextStep,
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium(color: context.textSecondary),
                    ),
                  ),
                ],
              )
            else
              Tappable(
                onTap: onPaywall,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_open_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Unlock Retries',
                          style: AppTypography.labelMedium(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Transcript Section ────────────────────────────────────────────────────

class _TranscriptSection extends StatelessWidget {
  final String transcript;

  const _TranscriptSection({required this.transcript});

  @override
  Widget build(BuildContext context) {
    final lines = transcript
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Transcript', style: AppTypography.titleMedium()),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                children: lines.map((line) {
                  final isUser = line.startsWith('You:') || line.startsWith('User:');
                  final isAi = line.startsWith('AI:');
                  final text = isUser
                      ? (line.startsWith('User:')
                          ? line.substring(5)
                          : line.substring(4))
                          .trim()
                      : isAi
                          ? line.substring(3).trim()
                          : line;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUser || isAi)
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 8, top: 1),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                              size: 14,
                              color: isUser ? AppColors.primary : AppColors.accent,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTypography.bodySmall(color: context.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
