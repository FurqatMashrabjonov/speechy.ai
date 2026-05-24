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
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : 'S');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
