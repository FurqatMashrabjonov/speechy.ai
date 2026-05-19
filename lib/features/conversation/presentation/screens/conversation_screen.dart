import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/features/characters/domain/character_entity.dart';
import 'package:speech_coach/features/conversation/domain/conversation_entity.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/conversation/presentation/providers/conversation_provider.dart';
import 'package:speech_coach/features/profile/presentation/providers/settings_provider.dart';
import 'package:speech_coach/features/feedback/presentation/providers/feedback_provider.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String category;
  final String? scenarioId;
  final String? scenarioTitle;
  final String? scenarioPrompt;
  final int? durationMinutes;
  final String? userRole;
  final String? characterName;
  final String? characterVoice;
  final String? characterPersonality;

  const ConversationScreen({
    super.key,
    required this.category,
    this.scenarioId,
    this.scenarioTitle,
    this.scenarioPrompt,
    this.durationMinutes,
    this.userRole,
    this.characterName,
    this.characterVoice,
    this.characterPersonality,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasNavigatedToScoreCard = false;
  bool _showBriefing = true;
  bool _showCaptions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(conversationProvider(widget.category).notifier);

      if (widget.characterName != null && widget.scenarioId == null) {
        notifier.setCharacter(
          name: widget.characterName!,
          voiceName: widget.characterVoice ?? ref.read(defaultVoiceProvider),
          personality: widget.characterPersonality ?? '',
        );
      }

      if (widget.scenarioId != null) {
        notifier.setScenario(
          scenarioId: widget.scenarioId!,
          scenarioTitle: widget.scenarioTitle ?? widget.category,
          scenarioPrompt: widget.scenarioPrompt ?? '',
          durationMinutes: widget.durationMinutes ?? 3,
          characterName: widget.characterName,
          characterVoice: widget.characterVoice,
          characterPersonality: widget.characterPersonality,
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
    ref
        .read(conversationProvider(widget.category).notifier)
        .startConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider(widget.category));

    ref.listen(conversationProvider(widget.category), (prev, next) {
      if (prev != null && prev.messages.length != next.messages.length) {
        _scrollToBottom();
      }

      if (next.status == ConversationStatus.ended &&
          next.scenarioId != null &&
          !_hasNavigatedToScoreCard &&
          next.messages.isNotEmpty) {
        _hasNavigatedToScoreCard = true;
        _navigateToScoreCard(next);
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
                            errorBuilder: (_, __, ___) => Container(
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
                          // Character avatar
                          ClipOval(
                            child: _characterImagePath != null
                                ? Image.asset(
                                    _characterImagePath!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _defaultCharacterAvatar(36),
                                  )
                                : _defaultCharacterAvatar(36),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.characterName ?? 'AI Coach',
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

  static const _darkBg = Color(0xFF1A1715);

  Widget _buildMeetScreen(BuildContext context, ConversationState state) {
    return Scaffold(
      backgroundColor: _darkBg,
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
                errorBuilder: (_, __, ___) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.scenarioTitle ?? widget.category,
                style: AppTypography.labelMedium(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),

          // Timer pill (centered-ish)
          if (state.isCountdown)
            _TimerPill(remaining: state.remaining)
          else if (state.status != ConversationStatus.idle &&
              state.status != ConversationStatus.ended)
            _TimerPill(elapsed: state.elapsed),

          if (widget.scenarioId == null) const Spacer(),
          if (widget.scenarioId != null) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeroCenter(BuildContext context, ConversationState state) {
    // Determine status label
    String statusLabel;
    switch (state.status) {
      case ConversationStatus.aiSpeaking:
        statusLabel = 'Speaking...';
      case ConversationStatus.userSpeaking:
        statusLabel = 'Listening...';
      case ConversationStatus.connecting:
        statusLabel = 'Connecting...';
      case ConversationStatus.analyzing:
        statusLabel = 'Compiling Feedback...';
      case ConversationStatus.error:
        statusLabel = 'Error';
      default:
        statusLabel = 'Ready';
    }

    return Stack(
      children: [
        // Main content centered
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error state
              if (state.status == ConversationStatus.error) ...[
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  state.error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                DuoButton.primary(
                  text: 'Try Again',
                  onTap: () {
                    ref
                        .read(conversationProvider(widget.category).notifier)
                        .startConversation();
                  },
                ),
              ] else ...[
                // Character avatar as hero center
                _HeroAvatar(
                  imagePath: _characterImagePath,
                  isAiSpeaking: state.status == ConversationStatus.aiSpeaking,
                  isUserSpeaking:
                      state.status == ConversationStatus.userSpeaking,
                  isConnecting:
                      state.status == ConversationStatus.connecting ||
                      state.status == ConversationStatus.analyzing,
                ),
                const SizedBox(height: 16),

                // Character name
                Text(
                  widget.characterName ?? 'AI Coach',
                  style: AppTypography.titleLarge(color: Colors.white),
                ),
                const SizedBox(height: 4),

                // Status label
                Text(
                  statusLabel,
                  style: AppTypography.bodySmall(color: Colors.white54),
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
              messages: state.messages,
              currentTranscription: state.currentTranscription,
              scrollController: _scrollController,
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
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showCaptions
                    ? Icons.closed_caption_rounded
                    : Icons.closed_caption_off_rounded,
                color: _showCaptions ? Colors.white : Colors.white54,
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

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _defaultCharacterAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Icon(
        Icons.auto_awesome,
        color: AppColors.primary,
        size: size * 0.5,
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
                ref
                    .read(conversationProvider(widget.category).notifier)
                    .requestFeedbackAndEnd();
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

  Future<void> _navigateToScoreCard(ConversationState state) async {
    // Reset feedback provider to clean state before starting new analysis
    ref.read(feedbackProvider.notifier).reset();

    if (state.sessionFeedback != null) {
      ref.read(feedbackProvider.notifier).setFeedback(state.sessionFeedback!);

      // If we already have feedback, we don't need a pending session.
      // We navigate immediately with sessionId: null, and ScoreCardScreen will
      // save the completed session perfectly using saveSessionProvider.
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
    } else {
      // REST API Fallback path
      // Start feedback analysis IMMEDIATELY
      ref
          .read(feedbackProvider.notifier)
          .analyzeConversation(
            transcript: state.fullTranscript,
            category: widget.category,
            scenarioTitle: state.scenarioTitle ?? widget.category,
            scenarioPrompt: state.scenarioPrompt ?? '',
            scenarioId: state.scenarioId ?? '',
            durationSeconds: state.elapsed.inSeconds,
          );

      // Create a pending session FIRST so ScoreCardScreen can update it when feedback is ready
      final sessionId = await _savePendingInBackground(state);

      if (mounted) {
        context.pushReplacement(
          '/score-card',
          extra: {
            'sessionId': sessionId,
            'scenarioId': state.scenarioId ?? '',
            'scenarioTitle': state.scenarioTitle ?? widget.category,
            'category': widget.category,
            'transcript': state.fullTranscript,
          },
        );
      }
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

  String? get _characterImagePath {
    final name = widget.characterName;
    if (name == null) return null;
    try {
      return CharacterRepository.characters
          .firstWhere((c) => c.name == name)
          .imagePath;
    } catch (_) {
      return null;
    }
  }
}

// ── Timer Pill ────────────────────────────────────────────────────────────

class _TimerPill extends StatelessWidget {
  final Duration? remaining;
  final Duration? elapsed;

  const _TimerPill({this.remaining, this.elapsed});

  @override
  Widget build(BuildContext context) {
    final duration = remaining ?? elapsed ?? Duration.zero;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final isLow = remaining != null && remaining!.inSeconds <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: isLow ? AppColors.error : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '$minutes:$seconds',
            style: AppTypography.labelMedium(
              color: isLow ? AppColors.error : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Avatar with Pulse/Waveform Ring ──────────────────────────────────

class _HeroAvatar extends StatefulWidget {
  final String? imagePath;
  final bool isAiSpeaking;
  final bool isUserSpeaking;
  final bool isConnecting;

  const _HeroAvatar({
    this.imagePath,
    required this.isAiSpeaking,
    required this.isUserSpeaking,
    required this.isConnecting,
  });

  @override
  State<_HeroAvatar> createState() => _HeroAvatarState();
}

class _HeroAvatarState extends State<_HeroAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseScale = 1.0 + sin(_controller.value * pi * 2) * 0.06;
        final ringOpacity = 0.3 + sin(_controller.value * pi * 2) * 0.3;

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring (user speaking)
              if (widget.isUserSpeaking)
                Transform.scale(
                  scale: pulseScale + 0.08,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: ringOpacity),
                        width: 3,
                      ),
                    ),
                  ),
                ),

              // Waveform ring (AI speaking)
              if (widget.isAiSpeaking)
                CustomPaint(
                  size: const Size(190, 190),
                  painter: _WaveRingPainter(
                    progress: _controller.value,
                    color: AppColors.accent,
                  ),
                ),

              // Character avatar (circular)
              ClipOval(
                child: widget.imagePath != null
                    ? Image.asset(
                        widget.imagePath!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),

              // Connecting spinner
              if (widget.isConnecting)
                Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 64),
    );
  }
}

// ── Wave Ring Painter (AI speaking) ───────────────────────────────────────

class _WaveRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 8;

    for (int i = 0; i < 3; i++) {
      final offset = i * 0.33;
      final wave = sin((progress + offset) * pi * 2);
      final radius = baseRadius + wave * 6;
      final opacity = 0.15 + wave.abs() * 0.2;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Caption Overlay ───────────────────────────────────────────────────────

class _CaptionOverlay extends StatelessWidget {
  final List<ConversationMessage> messages;
  final String currentTranscription;
  final ScrollController scrollController;

  const _CaptionOverlay({
    required this.messages,
    required this.currentTranscription,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Show last 3 messages + current transcription
    final recentMessages = messages.length > 3
        ? messages.sublist(messages.length - 3)
        : messages;

    if (recentMessages.isEmpty && currentTranscription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        controller: scrollController,
        shrinkWrap: true,
        children: [
          for (final msg in recentMessages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${msg.role == MessageRole.ai ? 'AI' : 'You'}: ${msg.text}',
                style: AppTypography.bodySmall(
                  color: msg.role == MessageRole.ai
                      ? Colors.white
                      : Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (currentTranscription.isNotEmpty)
            Text(
              'AI: $currentTranscription',
              style: AppTypography.bodySmall(color: Colors.white60),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
