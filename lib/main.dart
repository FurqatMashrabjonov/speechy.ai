import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/app/app.dart';
import 'package:speech_coach/features/assessment/data/assessment_repository.dart';
import 'package:speech_coach/features/progress/data/progress_repository.dart';
import 'package:speech_coach/features/widgets/data/widget_service.dart';
import 'package:speech_coach/firebase_options.dart';
import 'package:speech_coach/features/notifications/data/notification_service.dart';
import 'package:speech_coach/features/paywall/data/revenue_cat_service.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize RevenueCat — skip in debug (simulator compat)
  if (kReleaseMode) {
    try {
      await RevenueCatService().init();
    } catch (_) {}
  }

  // Initialize Notifications
  try {
    await NotificationService.init();
  } catch (_) {}

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Sync home screen widget data
  final progressRepo = ProgressRepository(prefs);
  final progress = progressRepo.load();
  WidgetService.updateWidgetData(progress);

  // Schedule daily reminder if user has an active learning plan
  try {
    final assessmentRepo = AssessmentRepository(prefs);
    final plan = assessmentRepo.getLearningPlan();
    if (plan != null) {
      final nextStep = plan.nextStep;
      final stepNumber = nextStep != null ? (nextStep.order + 1) : plan.steps.length;
      await NotificationService.scheduleDailyReminder(
        currentStep: stepNumber,
        roadmapTitle: plan.title,
      );
    }
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SpeechCoachApp(),
    ),
  );
}
