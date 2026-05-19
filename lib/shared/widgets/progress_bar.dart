import 'package:flutter/material.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';

class ProgressBar extends StatefulWidget {
  final double value;
  final String? label;
  final String? trailingText;
  final IconData? icon;
  final double height;
  final Color? color;
  final Color? trackColor;
  final bool animate;
  final Duration delay;

  const ProgressBar({
    super.key,
    required this.value,
    this.label,
    this.trailingText,
    this.icon,
    this.height = 12,
    this.color,
    this.trackColor,
    this.animate = true,
    this.delay = Duration.zero,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.animate) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: widget.value.clamp(0.0, 1.0),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ?? AppColors.primary;
    final track = widget.trackColor ?? const Color(0xFFE5E5E5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.trailingText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: barColor),
                  const SizedBox(width: 6),
                ],
                if (widget.label != null)
                  Expanded(
                    child: Text(
                      widget.label!,
                      style: AppTypography.labelMedium(),
                    ),
                  ),
                if (widget.trailingText != null)
                  Text(
                    widget.trailingText!,
                    style: AppTypography.labelMedium(color: barColor),
                  ),
              ],
            ),
          ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  children: [
                    Container(width: double.infinity, color: track),
                    FractionallySizedBox(
                      widthFactor: _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(
                            widget.height / 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
