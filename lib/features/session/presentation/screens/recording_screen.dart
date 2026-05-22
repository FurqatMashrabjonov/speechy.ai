import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/session/presentation/providers/session_provider.dart';
import 'package:speech_coach/features/session/presentation/widgets/audio_waveform.dart';
import 'package:speech_coach/features/session/presentation/widgets/recording_controls.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final String category;
  final String prompt;

  const RecordingScreen({
    super.key,
    required this.category,
    required this.prompt,
  });

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start recording after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(recordingProvider.notifier).startRecording();
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final recording = ref.watch(recordingProvider);
    // Show error if any
    ref.listen<RecordingState>(recordingProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return PopScope(
      canPop: recording.status == RecordingStatus.idle ||
          recording.status == RecordingStatus.stopped,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        if (recording.status == RecordingStatus.recording ||
                            recording.status == RecordingStatus.paused) {
                          _showExitDialog();
                        } else {
                          context.pop();
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.category,
                        style:
                            AppTypography.labelMedium(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
                const SizedBox(height: 16),

                // Prompt
                Text(
                  widget.prompt,
                  style: AppTypography.bodyLarge(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Timer
                Text(
                  _formatDuration(recording.elapsed),
                  style: AppTypography.displayLarge(
                    color: recording.status == RecordingStatus.recording
                        ? AppColors.secondary
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (recording.status == RecordingStatus.recording) ...[
                      _PulsingDot(),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      switch (recording.status) {
                        RecordingStatus.idle => 'Ready',
                        RecordingStatus.recording => 'Recording',
                        RecordingStatus.paused => 'Paused',
                        RecordingStatus.stopped => 'Stopped',
                      },
                      style: AppTypography.bodyMedium(
                        color: recording.status == RecordingStatus.recording
                            ? AppColors.error
                            : context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Waveform
                SizedBox(
                  height: 80,
                  child: AudioWaveform(
                    amplitude: recording.amplitude,
                    isActive:
                        recording.status == RecordingStatus.recording,
                  ),
                ),

                const Spacer(),

                // Controls
                RecordingControls(
                  status: recording.status,
                  onStart: () =>
                      ref.read(recordingProvider.notifier).startRecording(),
                  onPause: () =>
                      ref.read(recordingProvider.notifier).pauseRecording(),
                  onResume: () =>
                      ref.read(recordingProvider.notifier).resumeRecording(),
                  onStop: () => _stopAndNavigate(),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _stopAndNavigate() async {
    final path = await ref.read(recordingProvider.notifier).stopRecording();
    if (path != null && mounted) {
      final recording = ref.read(recordingProvider);
      context.pushReplacement(
        '/session/feedback',
        extra: {
          'category': widget.category,
          'prompt': widget.prompt,
          'audioPath': path,
          'duration': recording.elapsed.inSeconds,
        },
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stop Recording?'),
        content: const Text(
          'Your recording will be lost if you go back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Recording'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recordingProvider.notifier).reset();
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 1.0, end: 0.2, duration: 700.ms, curve: Curves.easeInOut);
  }
}
