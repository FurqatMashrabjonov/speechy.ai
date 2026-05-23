import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/app/app.dart';
import 'package:speech_coach/features/assessment/data/assessment_repository.dart';
import 'package:speech_coach/features/progress/data/progress_repository.dart';
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

  // Crashlytics — initialize plugin first, then wire error handlers
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Enable Analytics data collection
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // App Check — debug provider on emulator/debug, Play Integrity on release
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize RevenueCat — always init on Android so debug builds can test purchases
  try {
    await RevenueCatService().init();
  } catch (_) {}

  // Initialize Notifications
  try {
    await NotificationService.init();
  } catch (_) {}

  // Schedule notifications based on active plan + progress
  try {
    final plan = AssessmentRepository(prefs).getLearningPlan();
    if (plan != null) {
      final next = plan.nextStep;
      final step = next != null ? (next.order + 1) : plan.steps.length;
      await NotificationService.scheduleDailyReminder(
        currentStep: step,
        trackTitle: plan.title,
      );

      // Weekly summary — keep next Sunday's slot filled with real data
      final progress = ProgressRepository(prefs).load();
      final now = DateTime.now();
      final weekSessions = progress.sessionHistory
          .where((s) => now.difference(s.date).inDays < 7)
          .length;
      await NotificationService.scheduleWeeklySummary(
        sessionsThisWeek: weekSessions,
        streak: progress.streak,
      );
    }
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


  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SpeechCoachApp(),
    ),
  );
}
