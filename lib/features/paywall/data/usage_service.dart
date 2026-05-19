import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

class UsageService {
  static const _keyTotalFree = 'total_free_sessions_used';
  static const _keyIsPro = 'is_pro_user';
  static const int freeTotalSessions = 3;

  final SharedPreferences _prefs;

  UsageService(this._prefs);

  bool get isPro => _prefs.getBool(_keyIsPro) ?? false;

  int get totalFreeSessionsUsed => _prefs.getInt(_keyTotalFree) ?? 0;

  int get remainingSessions {
    if (isPro) return 999;
    return (freeTotalSessions - totalFreeSessionsUsed).clamp(0, freeTotalSessions);
  }

  bool canStartSession() {
    if (isPro) return true;
    return totalFreeSessionsUsed < freeTotalSessions;
  }

  Future<void> recordSession() async {
    if (isPro) return;
    final count = totalFreeSessionsUsed + 1;
    await _prefs.setInt(_keyTotalFree, count);
  }

  Future<void> setPro(bool value) async {
    await _prefs.setBool(_keyIsPro, value);
  }
}

final usageServiceProvider = Provider<UsageService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UsageService(prefs);
});
