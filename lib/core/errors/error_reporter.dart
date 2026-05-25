import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Report non-fatal errors to Crashlytics in release; print in debug.
void reportError(Object error, StackTrace stack, {String? context}) {
  if (kDebugMode) {
    debugPrint('ERROR${context != null ? ' [$context]' : ''}: $error\n$stack');
    return;
  }
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: context,
    fatal: false,
  );
}
