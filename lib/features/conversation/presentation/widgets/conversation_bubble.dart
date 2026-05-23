import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/conversation/domain/conversation_entity.dart';

class ConversationBubble extends StatelessWidget {
  final ConversationMessage message;
  final String? characterImagePath;

  const ConversationBubble({
    super.key,
    required this.message,
    this.characterImagePath,
  });

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            _AiAvatar(imagePath: characterImagePath),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isUser
                        ? AppColors.primary
                        : AppColors.chatAiBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(_isUser ? 20 : 4),
                      bottomRight: Radius.circular(_isUser ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: AppTypography.bodyMedium(
                      color: _isUser
                          ? AppColors.white
                          : context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: AppTypography.labelSmall(
                        color: context.textTertiary,
                      ).copyWith(fontSize: 10),
                    ),
                    if (_isUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.success.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_isUser) const SizedBox(width: 8),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: _isUser ? 0.1 : -0.1, duration: 300.ms);
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AiAvatar extends StatelessWidget {
  final String? imagePath;

  const _AiAvatar({this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return ClipOval(
        child: Image.asset(
          imagePath!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultAvatar(),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 14,
        color: AppColors.primary,
      ),
    );
  }
}
