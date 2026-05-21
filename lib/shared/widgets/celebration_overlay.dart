import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';

class CelebrationOverlay extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  final int? streakDays;
  final int? score;

  const CelebrationOverlay({
    super.key,
    this.message = 'Amazing!',
    this.onDismiss,
    this.streakDays,
    this.score,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Stack(
          children: [
            // Confetti from top-center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                gravity: 0.3,
                colors: const [
                  AppColors.primary,
                  AppColors.success,
                  AppColors.gold,
                  Color(0xFF7C5CBF),
                  Color(0xFF4FC3F7),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Particles behind
                  ...List.generate(12, (i) => _Particle(index: i)),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.gold,
                          size: 40,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.0, 0.0),
                            end: const Offset(1.0, 1.0),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 300.ms),
                      const SizedBox(height: 16),

                      // Success badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.message.contains('Goal')
                                  ? 'DAILY GOAL'
                                  : 'ACHIEVEMENT',
                              style: AppTypography.labelSmall(
                                color: AppColors.success,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        widget.message.contains('Goal')
                            ? 'Goal Achieved!'
                            : widget.message,
                        style: AppTypography.headlineMedium(),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: 8),
                      Text(
                        widget.message.contains('Goal')
                            ? 'You completed your daily practice goal. Keep the momentum going!'
                            : 'Your speaking skills are really improving. Keep it up!',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),
                      const SizedBox(height: 20),

                      // Stat cards
                      if (widget.streakDays != null || widget.score != null)
                        Row(
                          children: [
                            if (widget.streakDays != null)
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.local_fire_department_rounded,
                                  value: '${widget.streakDays}',
                                  label: 'Day Streak',
                                  color: AppColors.primary,
                                ),
                              ),
                            if (widget.streakDays != null && widget.score != null)
                              const SizedBox(width: 12),
                            if (widget.score != null)
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.star_rounded,
                                  value: '${widget.score}',
                                  label: 'Overall Score',
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 400.ms),
                      if (widget.streakDays != null || widget.score != null)
                        const SizedBox(height: 20),

                      // CTA
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue Learning',
                                  style: AppTypography.button(
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineMedium(color: color),
          ),
          Text(
            label,
            style: AppTypography.labelSmall(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  final int index;

  const _Particle({required this.index});

  @override
  Widget build(BuildContext context) {
    final random = Random(index);
    final size = 6.0 + random.nextDouble() * 10;
    final angle = random.nextDouble() * 2 * pi;
    final distance = 60.0 + random.nextDouble() * 100;
    final dx = cos(angle) * distance;
    final dy = sin(angle) * distance;
    final delay = Duration(milliseconds: random.nextInt(300));

    final colors = [
      AppColors.gold,
      AppColors.primary,
      AppColors.success,
      AppColors.accent,
    ];

    final isCircle = random.nextBool();

    return Positioned(
      left: 0,
      right: 0,
      top: 60,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors[index % colors.length],
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(size * 0.2),
          ),
        )
            .animate()
            .fadeIn(delay: delay, duration: 200.ms)
            .slideX(
                begin: 0,
                end: dx / 100,
                delay: delay,
                duration: 800.ms,
                curve: Curves.easeOutCubic)
            .slideY(
                begin: 0,
                end: dy / 100,
                delay: delay,
                duration: 800.ms,
                curve: Curves.easeOutCubic)
            .fadeOut(delay: delay + 600.ms, duration: 400.ms),
      ),
    );
  }
}
