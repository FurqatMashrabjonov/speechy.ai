import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final _player = AudioPlayer();

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> sessionStart() async {
    HapticFeedback.mediumImpact();
    await _play('audio/session_start.wav');
  }

  Future<void> stepPassed() async {
    HapticFeedback.mediumImpact();
    await _play('audio/step_passed.wav');
  }

  Future<void> celebration() async {
    HapticFeedback.heavyImpact();
    await _play('audio/celebration.wav');
  }

  Future<void> trackComplete() async {
    HapticFeedback.heavyImpact();
    await _play('audio/track_complete.wav');
  }
}
