import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Orange Brand (kept)
  static const primary = Color(0xFFE8793A);
  static const primaryLight = Color(0xFFFFF0E5);
  static const primaryDark = Color(0xFFC45A1F);

  // Secondary
  static const secondary = Color(0xFFE8793A);
  static const secondaryLight = Color(0xFFFFF0E5);

  // Accent - Duolingo Blue (for links, secondary actions)
  static const accent = Color(0xFF1CB0F6);
  static const accentLight = Color(0xFFE5F4FD);

  // Extended palette - Duolingo-vibrant
  static const lime = Color(0xFF58CC02);
  static const skyBlue = Color(0xFF1CB0F6);
  static const gold = Color(0xFFFFC800);
  static const lavender = Color(0xFFCE82FF);
  static const softPink = Color(0xFFFFE5E5);
  static const purple = Color(0xFFCE82FF);
  static const darkBlue = Color(0xFF2B70C9);

  // Success / Warning / Error - Duolingo-vibrant
  static const success = Color(0xFF58CC02);
  static const warning = Color(0xFFFFC800);
  static const error = Color(0xFFFF4B4B);

  // Neutrals - Light (clean white like Duolingo)
  static const white = Color(0xFFFFFFFF);
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF7F7F7);
  static const cardLight = Color(0xFFFFFFFF);
  static const dividerLight = Color(0xFFE5E5E5);
  static const textPrimaryLight = Color(0xFF1A1715);
  static const textSecondaryLight = Color(0xFF777777);
  static const textTertiaryLight = Color(0xFFAFAFAF);

  // Neutrals - Dark (warm-tinted, kept as-is)
  static const backgroundDark = Color(0xFF161412);
  static const surfaceDark = Color(0xFF211E1B);
  static const cardDark = Color(0xFF2C2825);
  static const dividerDark = Color(0xFF3D3833);
  static const textPrimaryDark = Color(0xFFF5F0EB);
  static const textSecondaryDark = Color(0xFFA8A098);
  static const textTertiaryDark = Color(0xFF706860);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFE8793A), Color(0xFFF09050)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF161412), Color(0xFF211E1B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFE8793A), Color(0xFFF09050)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFFC800), Color(0xFFE8793A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category colors - Vibrant, distinct hues (Duolingo-style)
  static const categoryPresentations = Color(0xFFE8793A);
  static const categoryInterviews = Color(0xFF2B70C9);
  static const categoryPublicSpeaking = Color(0xFFCE82FF);
  static const categoryConversations = Color(0xFF58CC02);
  static const categoryDebates = Color(0xFFFF4B4B);
  static const categoryStorytelling = Color(0xFFFFC800);
  static const categoryPhoneAnxiety = Color(0xFF1CB0F6);
  static const categoryDating = Color(0xFFFF9600);
  static const categoryConflict = Color(0xFFE8793A);
  static const categorySocial = Color(0xFF58CC02);

  // Card pastels - Brighter, cleaner
  static const cardPeach = Color(0xFFFFF4EC);
  static const cardBlue = Color(0xFFE5F4FD);
  static const cardLavender = Color(0xFFF0E5FF);
  static const cardMint = Color(0xFFE5FFF0);
  static const cardYellow = Color(0xFFFFF9E0);
  static const cardRose = Color(0xFFFFE5E5);

  // Warm background (clean white)
  static const backgroundWarm = Color(0xFFFFFFFF);

  // Chat bubble colors
  static const chatAiBubble = Color(0xFFF7F7F7);

}
