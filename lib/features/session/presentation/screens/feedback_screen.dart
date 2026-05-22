import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/session/domain/feedback_entity.dart';
import 'package:speech_coach/features/session/presentation/providers/session_provider.dart';
import 'package:speech_coach/features/session/presentation/widgets/feedback_section.dart';
import 'package:speech_coach/features/session/presentation/widgets/score_breakdown.dart';
import 'package:speech_coach/shared/widgets/app_button.dart';
import 'package:speech_coach/shared/widgets/loading_indicator.dart';
import 'package:speech_coach/shared/widgets/skeleton.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final String category;
  final String prompt;
  final String audioPath;
  final int durationSeconds;

  const FeedbackScreen({
    super.key,
    required this.category,
    required this.prompt,
    required this.audioPath,
    required this.durationSeconds,
  });

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  bool _transcriptExpanded = false;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    ref.read(analysisProvider.notifier).analyzeAndSave(
          userId: user.uid,
          category: widget.category,
          prompt: widget.prompt,
          audioPath: widget.audioPath,
          duration: Duration(seconds: widget.durationSeconds),
        );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    return PopScope(
      canPop: !analysis.isLoading,
      child: Scaffold(
        backgroundColor: context.background,
        body: SafeArea(
          child: analysis.isLoading
              ? _buildLoading()
              : analysis.error != null
                  ? _buildError(analysis.error!)
                  : analysis.feedback != null
                      ? _buildFeedback(analysis.feedback!)
                      : _buildLoading(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Center(
            child: Column(
              children: [
                const LoadingIndicator(size: 48),
                const SizedBox(height: 20),
                Text(
                  'Analyzing your speech...',
                  style: AppTypography.headlineMedium(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Reviewing clarity, pace, confidence, and more.',
                  style: AppTypography.bodyMedium(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Score circle skeleton
          const Center(child: SkeletonCircle(size: 140)),
          const SizedBox(height: 32),

          // Score breakdown skeleton
          const SkeletonLine(width: 150, height: 20),
          const SizedBox(height: 16),
          for (int i = 0; i < 4; i++) ...[
            Skeleton(
              height: 48,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 24),

          // Strengths skeleton
          const SkeletonLine(width: 120, height: 20),
          const SizedBox(height: 12),
          Skeleton(
            height: 100,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 20),

          // Improvements skeleton
          const SkeletonLine(width: 160, height: 20),
          const SizedBox(height: 12),
          Skeleton(
            height: 100,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTypography.bodyMedium(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Try Again',
              onPressed: _startAnalysis,
              isExpanded: false,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Go Home',
              variant: AppButtonVariant.outline,
              onPressed: () => context.go('/home'),
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(FeedbackEntity feedback) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text('Session Complete!',
                    style: AppTypography.headlineLarge()),
                const SizedBox(height: 4),
                Text(
                  widget.category,
                  style: AppTypography.bodyMedium(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Overall score
          Center(
            child: _OverallScoreWidget(score: feedback.overallScore),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),

          // Breakdown
          Text('Score Breakdown', style: AppTypography.titleLarge()),
          const SizedBox(height: 12),
          ScoreBreakdown(feedback: feedback)
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Strengths
          if (feedback.strengths.isNotEmpty) ...[
            FeedbackSection(
              title: 'Strengths',
              items: feedback.strengths,
              isPositive: true,
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            const SizedBox(height: 20),
          ],

          // Improvements
          if (feedback.improvements.isNotEmpty) ...[
            FeedbackSection(
              title: 'Areas to Improve',
              items: feedback.improvements,
              isPositive: false,
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            const SizedBox(height: 20),
          ],

          // Detailed analysis
          if (feedback.detailedAnalysis.isNotEmpty) ...[
            Text('Detailed Analysis', style: AppTypography.titleLarge()),
            const SizedBox(height: 8),
            Text(
              feedback.detailedAnalysis,
              style: AppTypography.bodyMedium(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Audio playback
          _AudioPlayerCard(audioPath: widget.audioPath)
              .animate()
              .fadeIn(delay: 700.ms, duration: 400.ms),
          const SizedBox(height: 20),

          // Transcript (expandable, formatted)
          if (feedback.transcript.isNotEmpty) ...[
            Tappable(
              onTap: () {
                setState(() => _transcriptExpanded = !_transcriptExpanded);
              },
              child: Row(
                children: [
                  Text('Transcript', style: AppTypography.titleLarge()),
                  const Spacer(),
                  Icon(
                    _transcriptExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (_transcriptExpanded) ...[
              const SizedBox(height: 8),
              _TranscriptView(transcript: feedback.transcript),
            ],
            const SizedBox(height: 24),
          ],

          // Action buttons
          AppButton(
            label: 'Practice Again',
            icon: Icons.refresh_rounded,
            onPressed: () => context.pushReplacement(
              '/session/setup/${Uri.encodeComponent(widget.category)}',
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Go Home',
            variant: AppButtonVariant.outline,
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OverallScoreWidget extends StatelessWidget {
  final int score;

  const _OverallScoreWidget({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTypography.displayLarge(color: AppColors.primary),
              ),
              Text(
                'Overall',
                style: AppTypography.labelMedium(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  final String audioPath;

  const _AudioPlayerCard({required this.audioPath});

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      if (!File(widget.audioPath).existsSync()) return;
      await _player.play(DeviceFileSource(widget.audioPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Recording',
                  style: AppTypography.labelMedium(color: context.textPrimary),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position),
                        style: AppTypography.labelSmall(
                            color: context.textTertiary)),
                    Text(_fmt(_duration),
                        style: AppTypography.labelSmall(
                            color: context.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptView extends StatelessWidget {
  final String transcript;

  const _TranscriptView({required this.transcript});

  @override
  Widget build(BuildContext context) {
    final lines = transcript
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isUser = line.startsWith('User:');
        final isAi = line.startsWith('AI:') || line.startsWith('Assistant:');
        final text = isUser
            ? line.replaceFirst('User:', '').trim()
            : isAi
                ? line.replaceFirst(RegExp(r'^(AI|Assistant):'), '').trim()
                : line;
        final label = isUser ? 'You' : isAi ? 'AI Coach' : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Container(
                  width: 64,
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: AppTypography.labelSmall(
                      color: isUser ? AppColors.primary : context.textTertiary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary.withValues(alpha: 0.07)
                        : context.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : context.textTertiary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    text,
                    style: AppTypography.bodySmall(color: context.textPrimary)
                        .copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
