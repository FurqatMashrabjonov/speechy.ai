import 'package:flutter/material.dart';
import 'package:speech_coach/app/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 21,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    const color = AppColors.primary;

    Widget avatar;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _InitialsCircle(
            name: name,
            size: size,
            color: color,
          ),
        ),
      );
    } else {
      avatar = _InitialsCircle(name: name, size: size, color: color);
    }

    return avatar;
  }
}

class _InitialsCircle extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const _InitialsCircle({
    required this.name,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
