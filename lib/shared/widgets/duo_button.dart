import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';

enum DuoButtonVariant { primary, secondary, success, outline, disabled }

class DuoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? color;
  final Color? shadowColor;
  final bool outline;
  final bool disabled;
  final IconData? icon;
  final double? width;

  const DuoButton({
    super.key,
    required this.text,
    this.onTap,
    this.color,
    this.shadowColor,
    this.outline = false,
    this.disabled = false,
    this.icon,
    this.width,
  });

  /// Primary filled orange button
  const DuoButton.primary({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.width,
  })  : color = AppColors.primary,
        shadowColor = AppColors.primaryDark,
        outline = false,
        disabled = false;

  /// Secondary filled blue button
  const DuoButton.secondary({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.width,
  })  : color = AppColors.accent,
        shadowColor = AppColors.darkBlue,
        outline = false,
        disabled = false;

  /// Success filled green button
  const DuoButton.success({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.width,
  })  : color = AppColors.success,
        shadowColor = const Color(0xFF44A302),
        outline = false,
        disabled = false;

  /// Outline/ghost button
  const DuoButton.outline({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.color,
    this.width,
  })  : shadowColor = null,
        outline = true,
        disabled = false;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  static const _shadowOffset = 4.0;
  static const _animDuration = Duration(milliseconds: 60);

  Color get _fillColor {
    if (widget.disabled) return const Color(0xFFE5E5E5);
    if (widget.outline) return AppColors.white;
    return widget.color ?? AppColors.primary;
  }

  Color get _shadowColor {
    if (widget.disabled) return const Color(0xFFCCCCCC);
    if (widget.outline) return const Color(0xFFE5E5E5);
    return widget.shadowColor ?? _darken(widget.color ?? AppColors.primary, 0.2);
  }

  Color get _textColor {
    if (widget.disabled) return const Color(0xFFAFAFAF);
    if (widget.outline) return widget.color ?? AppColors.primary;
    final fill = widget.color ?? AppColors.primary;
    return fill.computeLuminance() > 0.5 ? const Color(0xFF4A4A4A) : AppColors.white;
  }

  Color get _borderColor {
    if (widget.outline) return const Color(0xFFE5E5E5);
    return Colors.transparent;
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.disabled || widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
  }

  void _onTap() {
    if (widget.disabled || widget.onTap == null) return;
    HapticFeedback.lightImpact();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeInOut,
        width: widget.width,
        transform: Matrix4.translationValues(
          0,
          _isPressed ? _shadowOffset : 0,
          0,
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(16),
            border: widget.outline
                ? Border.all(color: _borderColor, width: 2)
                : null,
            boxShadow: _isPressed || widget.disabled
                ? []
                : [
                    BoxShadow(
                      color: _shadowColor,
                      offset: const Offset(0, _shadowOffset),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: _textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    style: AppTypography.button(color: _textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
