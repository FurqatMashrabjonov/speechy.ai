import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/app/app.dart';
import 'package:speech_coach/features/progress/data/progress_repository.dart';
import 'package:speech_coach/features/widgets/data/widget_service.dart';
import 'package:speech_coach/firebase_options.dart';
import 'package:speech_coach/features/notifications/data/notification_service.dart';
import 'package:speech_coach/features/paywall/data/revenue_cat_service.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

void main() async {
  debugPrint('[main] 1 start');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[main] 2 ensureInitialized');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[main] 3 firebase done');

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  debugPrint('[main] 4 prefs done');

  // Initialize RevenueCat — skip in debug (simulator compat)
  if (kReleaseMode) {
    try {
      await RevenueCatService().init();
    } catch (e) {
      debugPrint('[main] RevenueCat init failed: $e');
    }
  }

  // Initialize Notifications
  if (kReleaseMode) {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('[main] NotificationService init failed: $e');
    }
  }

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

  debugPrint('[main] 5 before widgets');
  // Sync home screen widget data
  final progressRepo = ProgressRepository(prefs);
  final progress = progressRepo.load();
  WidgetService.updateWidgetData(progress);
  debugPrint('[main] 6 runApp');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SpeechCoachApp(),
    ),
  );
}
