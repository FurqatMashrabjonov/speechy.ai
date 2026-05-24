import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/conversation/domain/conversation_entity.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/conversation/presentation/providers/conversation_provider.dart';
import 'package:speech_coach/features/feedback/presentation/providers/feedback_provider.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_coach/shared/services/sound_service.dart';

const _kDarkBg = Color(0xFF0D0D0D);
const _kDarkSurface = Color(0xFF1C1C1E);
const _kDarkBorder = Color(0xFF2A2A2A);
const _kDarkTextPrimary = Colors.white;
const _kDarkTextSecondary = Color(0xFF9A9A9A);

const _personaInfo = <String, (String, String)>{
  'Presentations':       ('David Chen',      'Senior VP of Product'),
  'Interviews':          ('Rachel Torres',   'Head of Talent · Vertex Labs'),
  'Public Speaking':     ('Marcus Webb',     'Speech Coach'),
  'Conversations':       ('Jamie',           'Graphic Designer'),
  'Debates':             ('Prof. Vasquez',   'Political Science Professor'),
  'Storytelling':        ('Nadia',           'Writer & Podcast Host'),
  'Phone Anxiety':       ('Support Agent',   'On the other end of the line'),
  'Dating & Social':     ('Alex',            'Marketing · New connection'),
  'Conflict & Boundaries': ('Your contact',  'Difficult conversation'),
  'Social Situations':   ('Chris',           'Teacher · New acquaintance'),
};

class ConversationScreen extends ConsumerStatefulWidget {
  final String category;
  final String? scenarioId;
  final String? scenarioTitle;
  final String? scenarioPrompt;
  final int? durationMinutes;
  final String? userRole;
  const ConversationScreen({
    super.key,
    required this.category,
    this.scenarioId,
    this.scenarioTitle,
    this.scenarioPrompt,
    this.durationMinutes,
    this.userRole,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  bool _hasNavigatedToScoreCard = false;
  bool _showBriefing = true;
  bool _showCaptions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(conversationProvider(widget.category).notifier);

      if (widget.scenarioId != null) {
        notifier.setScenario(
          scenarioId: widget.scenarioId!,
          scenarioTitle: widget.scenarioTitle ?? widget.category,
          scenarioPrompt: widget.scenarioPrompt ?? '',
          durationMinutes: widget.durationMinutes ?? 3,
          voiceName: 'Puck',
        );
      }

      // For freestyle (no scenario), skip briefing and auto-start
      if (widget.scenarioId == null) {
        setState(() => _showBriefing = false);
        notifier.startConversation();
      }
    });
  }

  void _onReady() {
    setState(() => _showBriefing = false);
    SoundService.instance.sessionStart();
    ref
        .read(conversationProvider(widget.category).notifier)
        .startConversation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider(widget.category));

    ref.listen(conversationProvider(widget.category), (prev, next) {
      // Timer auto-end path: navigate immediately when analyzing begins
      if (next.status == ConversationStatus.analyzing &&
          next.scenarioId != null &&
          !_hasNavigatedToScoreCard) {
        _hasNavigatedToScoreCard = true;
        _endAndNavigate(next);
      }
    });

    if (_showBriefing) {
      return _buildBriefingScreen(context);
    }

    return _buildMeetScreen(context, state);
  }

  // ── Role Briefing Screen ──────────────────────────────────────────────

  Widget _buildBriefingScreen(BuildContext context) {
    final scenarioImage = widget.scenarioId != null
        ? AppImages.scenarioImageMap[widget.scenarioId]
        : null;
    final categoryImage = AppImages.categoryImageMap[widget.category];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Tappable(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, size: 24),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Scenario image
                    ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            scenarioImage ?? categoryImage ?? '',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: AppColors.primary,
                                size: 56,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 20),

                    // Scenario title
                    Text(
                      widget.scenarioTitle ?? widget.category,
                      style: AppTypography.headlineMedium(),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 20),

                    // Your Role card
                    if (widget.userRole != null && widget.userRole!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardPeach,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Role',
                                  style: AppTypography.titleMedium(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.userRole!,
                              style: AppTypography.bodyMedium(),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // AI Partner row
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Coach',
                                  style: AppTypography.titleMedium(),
                                ),
                                Text(
                                  'will speak first',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Timer badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.durationMinutes ?? 3} min',
                                  style: AppTypography.labelMedium(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // I'm Ready button
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: DuoButton.primary(
                text: "I'm Ready",
                icon: Icons.mic_rounded,
                width: double.infinity,
                onTap: _onReady,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }

  // ── Meet-Style Conversation Screen ────────────────────────────────────

  Widget _buildMeetScreen(BuildContext context, ConversationState state) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context, state),

            // Hero center area
            Expanded(child: _buildHeroCenter(context, state)),

            // Bottom control bar
            _buildControlBar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ConversationState state) {
    final scenarioImage = widget.scenarioId != null
        ? AppImages.scenarioImageMap[widget.scenarioId]
        : null;
    final categoryImage = AppImages.categoryImageMap[widget.category];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Scenario image (small) + title
          if (widget.scenarioId != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                scenarioImage ?? categoryImage ?? '',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.scenarioTitle ?? widget.category,
                style: AppTypography.labelMedium(color: _kDarkTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),

          // Timer pill
          if (state.isCountdown)
            _TimerPill(remaining: state.remaining, onDark: true)
          else if (state.status != ConversationStatus.idle &&
              state.status != ConversationStatus.ended)
            _TimerPill(elapsed: state.elapsed, onDark: true),

          if (widget.scenarioId == null) const Spacer(),
          if (widget.scenarioId != null) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeroCenter(BuildContext context, ConversationState state) {
    return Stack(
      children: [
        // Main content centered
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error state
              if (state.status == ConversationStatus.error) ...[
                _ErrorCard(
                  errorType: state.errorType,
                  message: state.error,
                  hasMessages: state.messages.isNotEmpty,
                  hasScenario: state.scenarioId != null,
                  onRetry: () => ref
                      .read(conversationProvider(widget.category).notifier)
                      .startConversation(),
                  onEndSession: state.scenarioId != null
                      ? () {
                          if (!_hasNavigatedToScoreCard) {
                            _hasNavigatedToScoreCard = true;
                            ref
                                .read(conversationProvider(widget.category).notifier)
                                .endConversation();
                            _endAndNavigate(state);
                          }
                        }
                      : null,
                ),
              ] else ...[
                // Orb hero
                _OrbWidget(
                  isAiSpeaking: state.status == ConversationStatus.aiSpeaking,
                  isUserSpeaking: state.status == ConversationStatus.userSpeaking,
                  isConnecting: state.status == ConversationStatus.connecting ||
                      state.status == ConversationStatus.analyzing,
                  micAmplitude: state.micAmplitude,
                  aiAmplitude: state.aiAmplitude,
                ),
              ],
            ],
          ),
        ),

        // Live captions overlay at bottom
        if (_showCaptions &&
            state.status != ConversationStatus.error &&
            state.status != ConversationStatus.connecting)
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: _CaptionOverlay(
              currentTranscription: state.currentTranscription,
            ),
          ),
      ],
    );
  }

  Widget _buildControlBar(BuildContext context, ConversationState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Captions toggle
          Tappable(
            onTap: () => setState(() => _showCaptions = !_showCaptions),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _showCaptions
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : _kDarkSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showCaptions
                    ? Icons.closed_caption_rounded
                    : Icons.closed_caption_off_rounded,
                color: _showCaptions ? AppColors.primary : _kDarkTextSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Large mic button
          GestureDetector(
            onTap: () => ref
                .read(conversationProvider(widget.category).notifier)
                .toggleMic(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: state.isMicMuted ? null : AppColors.primaryGradient,
                color: state.isMicMuted ? const Color(0xFF4A4A4A) : null,
                shape: BoxShape.circle,
                boxShadow: state.isMicMuted
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primaryDark,
                          blurRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                state.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // End call button
          Tappable(
            onTap: () => _showEndDialog(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndDialog(BuildContext context) {
    final currentState = ref.read(conversationProvider(widget.category));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Conversation?', style: AppTypography.headlineSmall()),
        content: Text(
          currentState.scenarioId != null
              ? 'This will end your session and generate your score card.'
              : 'This will end your current conversation session.',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final s = ref.read(conversationProvider(widget.category));
              if (s.scenarioId != null) {
                if (!_hasNavigatedToScoreCard) {
                  _hasNavigatedToScoreCard = true;
                  ref
                      .read(conversationProvider(widget.category).notifier)
                      .endConversation();
                  _endAndNavigate(s);
                }
              } else {
                ref
                    .read(conversationProvider(widget.category).notifier)
                    .endConversation();
                context.pop();
              }
            },
            child: Text(
              'End',
              style: AppTypography.labelLarge(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  bool _isTooShort(ConversationState state) {
    if (state.elapsed.inSeconds < 15) return true;
    final userLines = state.fullTranscript
        .split('\n')
        .where((l) => l.startsWith('User:') && l.trim().length > 6)
        .length;
    return userLines == 0;
  }

  void _endAndNavigate(ConversationState state) {
    if (_isTooShort(state)) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session too short — practice at least 15 seconds to get scored.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
      return;
    }

    ref.read(feedbackProvider.notifier).reset();
    ref.read(feedbackProvider.notifier).analyzeConversation(
      transcript: state.fullTranscript,
      category: widget.category,
      scenarioTitle: state.scenarioTitle ?? widget.category,
      scenarioPrompt: state.scenarioPrompt ?? '',
      scenarioId: state.scenarioId ?? '',
      durationSeconds: state.elapsed.inSeconds,
    );

    // Save session in background — don't block navigation
    _savePendingInBackground(state);

    if (mounted) {
      context.pushReplacement(
        '/score-card',
        extra: {
          'sessionId': null,
          'scenarioId': state.scenarioId ?? '',
          'scenarioTitle': state.scenarioTitle ?? widget.category,
          'category': widget.category,
          'transcript': state.fullTranscript,
        },
      );
    }
  }

  Future<String?> _savePendingInBackground(ConversationState state) async {
    try {
      return await ref
          .read(pendingSessionSaverProvider)
          .savePending(
            scenarioId: state.scenarioId ?? '',
            scenarioTitle: state.scenarioTitle ?? widget.category,
            category: widget.category,
            transcript: state.fullTranscript,
            durationSeconds: state.elapsed.inSeconds,
            scenarioPrompt: state.scenarioPrompt ?? '',
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Failed to save session to Firestore (non-blocking): $e');
      return null;
    }
  }

}

// ── Timer Pill ────────────────────────────────────────────────────────────

class _TimerPill extends StatelessWidget {
  final Duration? remaining;
  final Duration? elapsed;
  final bool onDark;

  const _TimerPill({this.remaining, this.elapsed, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final duration = remaining ?? elapsed ?? Duration.zero;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final isLow = remaining != null && remaining!.inSeconds <= 30;
    final isWarning = remaining != null &&
        remaining!.inSeconds <= 60 &&
        remaining!.inSeconds > 30;

    final Color pillColor;
    final Color contentColor;
    if (isLow) {
      pillColor = AppColors.error.withValues(alpha: 0.15);
      contentColor = AppColors.error;
    } else if (isWarning) {
      pillColor = AppColors.warning.withValues(alpha: 0.15);
      contentColor = AppColors.warning;
    } else {
      pillColor = onDark
          ? const Color(0xFF2A2A2A)
          : AppColors.primary.withValues(alpha: 0.1);
      contentColor = onDark ? _kDarkTextSecondary : context.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: contentColor),
          const SizedBox(width: 4),
          Text(
            '$minutes:$seconds',
            style: AppTypography.labelMedium(
              color: isLow || isWarning
                  ? contentColor
                  : (onDark ? Colors.white : context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Orb Widget (AI Coach visual) ─────────────────────────────────────────

class _OrbWidget extends StatefulWidget {
  final bool isAiSpeaking;
  final bool isUserSpeaking;
  final bool isConnecting;
  final double micAmplitude;
  final double aiAmplitude;

  const _OrbWidget({
    required this.isAiSpeaking,
    required this.isUserSpeaking,
    required this.isConnecting,
    required this.micAmplitude,
    required this.aiAmplitude,
  });

  @override
  State<_OrbWidget> createState() => _OrbWidgetState();
}

class _OrbWidgetState extends State<_OrbWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _idleDuration = Duration(milliseconds: 2200);
  static const _speakDuration = Duration(milliseconds: 850);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _idleDuration)
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_OrbWidget old) {
    super.didUpdateWidget(old);
    final wasActive = old.isAiSpeaking || old.isUserSpeaking;
    final isActive = widget.isAiSpeaking || widget.isUserSpeaking;
    if (isActive != wasActive) {
      _ctrl.duration = isActive ? _speakDuration : _idleDuration;
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value; // 0.0→1.0 slow breathe (idle) or fast pulse (speaking)

        final double orbDiam;
        final double glowAlpha;
        final double glowBlur;

        if (widget.isUserSpeaking) {
          orbDiam = 120.0 + t * 6.0 + widget.micAmplitude * 48.0;
          glowAlpha = 0.35 + widget.micAmplitude * 0.30;
          glowBlur = 36.0 + widget.micAmplitude * 32.0;
        } else if (widget.isAiSpeaking) {
          orbDiam = 120.0 + t * 8.0 + widget.aiAmplitude * 52.0;
          glowAlpha = 0.32 + widget.aiAmplitude * 0.30;
          glowBlur = 34.0 + widget.aiAmplitude * 34.0;
        } else {
          // Idle / connecting: gentle breathing only
          orbDiam = 130.0 + t * 6.0;
          glowAlpha = 0.28 + t * 0.12;
          glowBlur = 30.0 + t * 12.0;
        }

        return SizedBox(
          width: 230,
          height: 230,
          child: Center(
            child: Container(
              width: orbDiam,
              height: orbDiam,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(AppColors.primary, Colors.white, 0.38)!,
                    AppColors.primary,
                  ],
                  stops: const [0.0, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: widget.isConnecting
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

// ── Caption Overlay ───────────────────────────────────────────────────────

class _CaptionOverlay extends StatelessWidget {
  final String currentTranscription;

  const _CaptionOverlay({required this.currentTranscription});

  @override
  Widget build(BuildContext context) {
    if (currentTranscription.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kDarkSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDarkBorder),
      ),
      child: Text(
        currentTranscription,
        style: AppTypography.bodySmall(color: _kDarkTextPrimary),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final ConversationErrorType? errorType;
  final String? message;
  final bool hasMessages;
  final bool hasScenario;
  final VoidCallback onRetry;
  final VoidCallback? onEndSession;

  const _ErrorCard({
    required this.errorType,
    required this.message,
    required this.hasMessages,
    required this.hasScenario,
    required this.onRetry,
    this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = _iconForType(errorType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            _titleForType(errorType),
            style: AppTypography.titleLarge(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Something went wrong.\nPlease try again.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: context.textSecondary),
          ),
          const SizedBox(height: 28),
          if (errorType == ConversationErrorType.permission) ...[
            DuoButton.primary(
              text: 'Open Settings',
              icon: Icons.settings_rounded,
              onTap: () => launchUrl(Uri.parse('app-settings:')),
            ),
          ] else ...[
            DuoButton.primary(
              text: hasMessages ? 'Reconnect' : 'Try Again',
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
          ],
          if (hasMessages && hasScenario && onEndSession != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onEndSession,
              child: Text(
                'End & Get Score Card',
                style: AppTypography.labelLarge(color: context.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _titleForType(ConversationErrorType? type) => switch (type) {
    ConversationErrorType.network => 'No Internet',
    ConversationErrorType.permission => 'Microphone Needed',
    ConversationErrorType.appCheck => 'Connection Failed',
    ConversationErrorType.quota => 'Service Busy',
    ConversationErrorType.midSession => 'Connection Lost',
    _ => 'Something Went Wrong',
  };

  (IconData, Color) _iconForType(ConversationErrorType? type) => switch (type) {
    ConversationErrorType.network => (Icons.wifi_off_rounded, AppColors.error),
    ConversationErrorType.permission => (Icons.mic_off_rounded, AppColors.error),
    ConversationErrorType.appCheck => (Icons.lock_outline_rounded, AppColors.primary),
    ConversationErrorType.quota => (Icons.hourglass_empty_rounded, AppColors.primary),
    ConversationErrorType.midSession => (Icons.signal_wifi_statusbar_connected_no_internet_4_rounded, AppColors.error),
    _ => (Icons.error_outline_rounded, AppColors.error),
  };
}
