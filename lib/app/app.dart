import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/app/router.dart';
import 'package:speech_coach/app/theme/app_theme.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/shared/providers/theme_provider.dart';

class SpeechCoachApp extends ConsumerWidget {
  const SpeechCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Sync plan to/from Firestore whenever auth state changes to logged-in
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, current) {
      final wasLoggedIn = previous?.value != null;
      final isLoggedIn = current.value != null;
      if (!wasLoggedIn && isLoggedIn) {
        ref.read(learningPlanProvider.notifier).refreshSync();
      }
    });

    return MaterialApp.router(
      title: 'Speechy AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
