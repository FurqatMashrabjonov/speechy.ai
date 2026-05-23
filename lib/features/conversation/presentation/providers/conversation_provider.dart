import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';
import 'package:speech_coach/features/conversation/data/gemini_live_service.dart';
import 'package:speech_coach/features/conversation/domain/conversation_entity.dart';
import 'package:speech_coach/features/feedback/domain/feedback_entity.dart';

// --- Providers ---

final geminiLiveServiceProvider = Provider<GeminiLiveService>((ref) {
  return GeminiLiveService();
});

final conversationProvider = StateNotifierProvider.autoDispose
    .family<ConversationNotifier, ConversationState, String>((ref, category) {
      final service = ref.read(geminiLiveServiceProvider);
      return ConversationNotifier(service, category);
    });

// --- State ---

class ConversationState {
  final ConversationStatus status;
  final List<ConversationMessage> messages;
  final String currentTranscription;
  final String? error;
  final ConversationErrorType? errorType;
  final Duration elapsed;
  // Scenario fields
  final String? scenarioId;
  final String? scenarioTitle;
  final String? scenarioPrompt;
  final int? durationLimitMinutes;
  final bool isCountdown;
  // Voice selection (from Settings)
  final String? voiceName;
  // Mic mute state
  final bool isMicMuted;
  // Real-time mic amplitude 0.0–1.0 for waveform UI
  final double micAmplitude;
  // Feedback from live tool call
  final ConversationFeedback? sessionFeedback;

  const ConversationState({
    this.status = ConversationStatus.idle,
    this.messages = const [],
    this.currentTranscription = '',
    this.error,
    this.errorType,
    this.elapsed = Duration.zero,
    this.scenarioId,
    this.scenarioTitle,
    this.scenarioPrompt,
    this.durationLimitMinutes,
    this.isCountdown = false,
    this.voiceName,
    this.isMicMuted = false,
    this.micAmplitude = 0.0,
    this.sessionFeedback,
  });

  Duration get remaining {
    if (durationLimitMinutes == null) return Duration.zero;
    final limit = Duration(minutes: durationLimitMinutes!);
    final diff = limit - elapsed;
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isTimeUp =>
      durationLimitMinutes != null &&
      elapsed >= Duration(minutes: durationLimitMinutes!);

  String get fullTranscript {
    return messages
        .map((m) => '${m.role == MessageRole.user ? "User" : "AI"}: ${m.text}')
        .join('\n');
  }

  ConversationState copyWith({
    ConversationStatus? status,
    List<ConversationMessage>? messages,
    String? currentTranscription,
    String? error,
    ConversationErrorType? errorType,
    Duration? elapsed,
    String? scenarioId,
    String? scenarioTitle,
    String? scenarioPrompt,
    int? durationLimitMinutes,
    bool? isCountdown,
    String? voiceName,
    bool? isMicMuted,
    double? micAmplitude,
    ConversationFeedback? sessionFeedback,
  }) {
    return ConversationState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      error: error,
      errorType: errorType,
      elapsed: elapsed ?? this.elapsed,
      scenarioId: scenarioId ?? this.scenarioId,
      scenarioTitle: scenarioTitle ?? this.scenarioTitle,
      scenarioPrompt: scenarioPrompt ?? this.scenarioPrompt,
      durationLimitMinutes: durationLimitMinutes ?? this.durationLimitMinutes,
      isCountdown: isCountdown ?? this.isCountdown,
      voiceName: voiceName ?? this.voiceName,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      micAmplitude: micAmplitude ?? this.micAmplitude,
      sessionFeedback: sessionFeedback ?? this.sessionFeedback,
    );
  }
}

// --- Notifier ---

class ConversationNotifier extends StateNotifier<ConversationState> {
  final GeminiLiveService _service;
  final String category;
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _timer;
  Timer? _amplitudeTimer;
  bool _closed = false;
  StreamSubscription<List<int>>? _micSubscription;

  // SoLoud streaming audio playback — raw PCM fed directly, no WAV wrapping
  AudioSource? _audioStream;
  SoundHandle? _audioHandle;
  bool _audioStreamBusy = false; // prevents concurrent _setupNewStream calls

  // Keep a copy of all audio for the message bubble
  final List<int> _turnAudioBuffer = [];
  // Buffer for user speech transcription (from inputTranscription)
  String _pendingUserTranscription = '';

  // Echo prevention: track AI speaking state
  bool _isAiSpeaking = false;
  bool _micIsActive = false;
  Timer? _micResumeTimer;
  bool _wrapUpWarningSent = false;

  // Barge-in detection
  static const double _bargeInThreshold = 0.35;
  static const int _bargeInHoldFrames = 3;
  int _bargeInFrameCount = 0;
  bool _bargeInActive = false; // blocks in-flight AI audio after barge-in

  ConversationNotifier(this._service, this.category)
    : super(const ConversationState());

  ConversationErrorType _classifyError(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission') || s.contains('microphone')) {
      return ConversationErrorType.permission;
    }
    if (s.contains('firebase_app_check') || s.contains('app check') ||
        s.contains('too many attempts') || s.contains('appcheck') ||
        s.contains('unauthorized') || s.contains('403')) {
      return ConversationErrorType.appCheck;
    }
    if (s.contains('quota') || s.contains('rate limit') ||
        s.contains('resource exhausted') || s.contains('429') ||
        s.contains('too many requests')) {
      return ConversationErrorType.quota;
    }
    if (s.contains('socketexception') || s.contains('connection refused') ||
        s.contains('network') || s.contains('unreachable') ||
        s.contains('no address') || s.contains('failed host lookup') ||
        s.contains('websocket closed') || s.contains('connection reset') ||
        s.contains('connection closed') || s.contains('connection lost') ||
        s.contains('ioexception')) {
      return ConversationErrorType.network;
    }
    return ConversationErrorType.unknown;
  }

  String _friendlyMessage(ConversationErrorType type) => switch (type) {
    ConversationErrorType.network => 'No internet connection.\nCheck your connection and try again.',
    ConversationErrorType.permission => 'Microphone access is required\nto start a conversation.',
    ConversationErrorType.appCheck => 'Connection failed.\nPlease try again.',
    ConversationErrorType.quota => 'Service is busy right now.\nPlease wait a moment and try again.',
    ConversationErrorType.midSession => 'Connection lost during your session.\nYou can reconnect or end the session.',
    ConversationErrorType.unknown => 'Something went wrong.\nPlease try again.',
  };

  void setScenario({
    required String scenarioId,
    required String scenarioTitle,
    required String scenarioPrompt,
    required int durationMinutes,
    String? voiceName,
  }) {
    state = state.copyWith(
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      scenarioPrompt: scenarioPrompt,
      durationLimitMinutes: durationMinutes,
      isCountdown: true,
      voiceName: voiceName,
    );
  }

  /// Configure Android audio session like a phone call:
  /// - Takes audio focus → music/video pauses
  /// - Routes through communication path with speakerphone on
  ///   (voiceCommunication AEC reference tracks speaker output for echo cancellation)
  Future<void> _activateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
          flags: AndroidAudioFlags.audibilityEnforced,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientExclusive,
        androidWillPauseWhenDucked: true,
      ));
      await session.setActive(true);
    } catch (e) {
      debugPrint('AudioSession activate failed: $e');
    }
  }

  Future<void> _deactivateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('AudioSession deactivate failed: $e');
    }
  }

  /// Initialize SoLoud engine and set up a buffer stream for audio playback.
  Future<void> _initAudioPlayer() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);
    }
    await _setupNewStream();
  }

  Future<void> _setupNewStream() async {
    if (!SoLoud.instance.isInitialized) return;

    if (_audioStreamBusy) return;
    _audioStreamBusy = true;
    try {
      await _stopAudioStream();
      _audioStream = SoLoud.instance.setBufferStream(
        maxBufferSizeBytes: 1024 * 1024 * 10,
        bufferingType: BufferingType.released,
        bufferingTimeNeeds: 0,
        onBuffering: (isBuffering, handle, time) {},
      );
      _audioHandle = null;
    } finally {
      _audioStreamBusy = false;
    }
  }

  Future<void> _startAudioPlayback() async {
    if (_audioStream == null) return;
    _audioHandle = await SoLoud.instance.play(_audioStream!);
  }

  /// Feed 100ms of silent PCM into SoLoud before the first real audio arrives.
  /// Warms up the audio path (OpenSLES/AAudio init, JNI bridge) so first
  /// AI response plays immediately instead of stalling 300-500ms.
  /// Call ONCE at session start only — not per-turn.
  void _primeAudioPipeline() {
    if (_audioStream == null) return;
    // 100ms @ 24kHz mono 16-bit = 24000 * 0.1 * 2 = 4800 bytes of zeros
    final silence = Uint8List(4800);
    SoLoud.instance.addAudioDataStream(_audioStream!, silence);
  }

  /// Invalidates the current stream without touching the engine.
  /// Safe to call mid-session — SoLoud frees the stream automatically when data ends.
  Future<void> _stopAudioStream() async {
    if (_audioStream != null && SoLoud.instance.isInitialized) {
      try {
        SoLoud.instance.setDataIsEnded(_audioStream!);
      } catch (_) {}
    }
    _audioStream = null;
    _audioHandle = null;
  }

  /// Full engine teardown at session end.
  /// Avoids the FFI callback crash that stop(handle) causes when the Dart
  /// NativeCallable closure is GC'd before the native callback fires.
  Future<void> _teardownAudioEngine() async {
    await _stopAudioStream();
    if (SoLoud.instance.isInitialized) {
      try {
        SoLoud.instance.deinit();
      } catch (_) {}
    }
  }

  Future<void> startConversation() async {
    if (state.status != ConversationStatus.idle &&
        state.status != ConversationStatus.error) {
      return;
    }

    state = state.copyWith(status: ConversationStatus.connecting, error: null);

    try {
      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) {
        state = state.copyWith(
          status: ConversationStatus.error,
          error: 'Microphone permission denied',
        );
        return;
      }

      // Take audio focus — pauses music/video, activates call routing
      await _activateAudioSession();

      // Initialize SoLoud audio player
      await _initAudioPlayer();

      // Warm up audio pipeline — prevents 300-500ms stall on first AI audio
      _primeAudioPipeline();

      await _service.connect(
        category,
        scenarioPrompt: state.scenarioPrompt,
        durationMinutes: state.durationLimitMinutes,
        voiceName: state.voiceName,
      );
      _startTimer();

      // Start receive loop (runs in background)
      _receiveLoop();

      // Start audio playback stream (SoLoud auto-pauses when buffer empty)
      await _startAudioPlayback();

      // Trigger AI to speak first (greeting)
      // Don't start mic yet — wait until AI finishes greeting
      _isAiSpeaking = true;
      await _service.sendText('Hello');

      state = state.copyWith(status: ConversationStatus.aiSpeaking);
    } catch (e) {
      debugPrint('Start conversation error: $e');
      final errorType = _classifyError(e);
      state = state.copyWith(
        status: ConversationStatus.error,
        error: _friendlyMessage(errorType),
        errorType: errorType,
      );
    }
  }

  /// Starts continuous mic audio streaming to Gemini via per-chunk sendAudioRealtime.
  /// VAD on the server automatically detects when the user speaks/stops.
  Future<void> _startMicStream() async {
    if (_micIsActive || state.isMicMuted || _closed) return;
    try {
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,     // software AEC — works correctly with speaker audio path
          noiseSuppress: true,  // suppress background noise
          autoGain: true,
          androidConfig: const AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceCommunication,
          ),
        ),
      );

      _micIsActive = true;

      _micSubscription = stream.listen((data) {
        if (_closed) return;
        final bytes = Uint8List.fromList(data);
        if (_isAiSpeaking) {
          // Barge-in detection: check amplitude from raw PCM
          final amp = _pcmAmplitude(bytes);
          if (amp > _bargeInThreshold) {
            _bargeInFrameCount++;
            if (_bargeInFrameCount >= _bargeInHoldFrames) {
              _onBargeIn(bytes);
            }
          } else {
            _bargeInFrameCount = 0;
          }
          // Don't send to Gemini — AI has the floor
        } else {
          _bargeInFrameCount = 0;
          _service.sendAudioRealtime(bytes);
        }
      });

      // Poll amplitude at 20Hz for waveform UI
      _amplitudeTimer?.cancel();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
        if (!_micIsActive || _closed || !mounted) return;
        try {
          final amp = await _recorder.getAmplitude();
          // dBFS: silence ≈ -60, speech ≈ -30 to -5. Map to 0.0–1.0.
          final linear = ((amp.current + 60) / 55).clamp(0.0, 1.0);
          if (mounted) state = state.copyWith(micAmplitude: linear);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Mic stream error: $e');
      _micIsActive = false;
    }
  }

  /// Hard-stop the mic recorder. No audio reaches Gemini after this.
  Future<void> _stopMicStream() async {
    _micResumeTimer?.cancel();
    _micResumeTimer = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    if (mounted) state = state.copyWith(micAmplitude: 0.0);

    if (!_micIsActive) return;
    await _micSubscription?.cancel();
    _micSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    _micIsActive = false;
  }

  /// Toggle mic mute/unmute. When muted, stops the recorder so no audio
  /// is sent to Gemini. When unmuted, restarts the mic stream.
  Future<void> toggleMic() async {
    if (state.status == ConversationStatus.idle ||
        state.status == ConversationStatus.ended ||
        state.status == ConversationStatus.error ||
        state.status == ConversationStatus.connecting) {
      return;
    }

    if (!state.isMicMuted) {
      // Mute: stop recorder
      await _stopMicStream();
      state = state.copyWith(isMicMuted: true);
    } else {
      // Unmute: restart mic stream (only if AI is not speaking)
      state = state.copyWith(isMicMuted: false);
      if (!_isAiSpeaking) {
        await _startMicStream();
      }
    }
  }

  /// Continuously calls receive() in a loop. Each call yields responses
  /// until turnComplete, then we call receive() again for the next turn.
  Future<void> _receiveLoop() async {
    while (!_closed && _service.isConnected) {
      try {
        await for (final response in _service.receive()) {
          if (_closed) break;
          _handleServerResponse(response);
        }
        // receive() stream ended (turnComplete). Flush user transcription
        // as a message, then loop back for next turn.
        _flushUserTranscription();
      } catch (e) {
        if (_closed) break;
        debugPrint('Receive loop error: $e');
        if (mounted) {
          final isMidSession = state.messages.isNotEmpty;
          final errorType = isMidSession ? ConversationErrorType.midSession : _classifyError(e);
          state = state.copyWith(
            status: ConversationStatus.error,
            error: _friendlyMessage(errorType),
            errorType: errorType,
          );
        }
        break;
      }
    }
  }

  void _handleServerResponse(LiveServerResponse response) {
    final msg = response.message;

    if (msg is LiveServerContent) {
      // Audio chunks from model turn — feed directly to SoLoud stream
      if (msg.modelTurn != null && !_bargeInActive) {
        if (!_isAiSpeaking) {
          _isAiSpeaking = true;
          _bargeInFrameCount = 0;
          _flushUserTranscription();
          state = state.copyWith(status: ConversationStatus.aiSpeaking);
        }
        for (final part in msg.modelTurn!.parts) {
          if (part is InlineDataPart && part.mimeType.startsWith('audio')) {
            _turnAudioBuffer.addAll(part.bytes);
            if (_audioStream != null) {
              SoLoud.instance.addAudioDataStream(_audioStream!, part.bytes);
            }
          }
        }
      }

      // AI output transcription (what the AI is saying as text)
      if (msg.outputTranscription?.text != null) {
        state = state.copyWith(
          currentTranscription:
              state.currentTranscription + msg.outputTranscription!.text!,
        );
      }

      // User input transcription (what the user said)
      if (msg.inputTranscription?.text != null) {
        final newText = msg.inputTranscription!.text!;
        _pendingUserTranscription += newText;

        if (state.status == ConversationStatus.active &&
            newText.trim().isNotEmpty) {
          state = state.copyWith(status: ConversationStatus.userSpeaking);
        }
      }

      // Turn is complete — create the AI message bubble (audio already playing)
      if (msg.turnComplete == true) {
        _onAiTurnComplete();
      }
    } else if (msg is GoingAwayNotice) {
      // Server will disconnect in ~60 seconds — end gracefully now
      debugPrint('GoingAwayNotice received. timeLeft=${msg.timeLeft}. Ending session.');
      if (state.scenarioId != null &&
          state.status != ConversationStatus.ended &&
          state.status != ConversationStatus.analyzing) {
        requestFeedbackAndEnd();
      } else if (state.status != ConversationStatus.ended) {
        endConversation();
      }
    } else if (msg is LiveServerToolCall) {
      if (msg.functionCalls != null) {
        for (final call in msg.functionCalls!) {
          if (call.name == 'submit_session_feedback') {
            try {
              final args = call.args;
              // Ensure correct fields for entity creation
              final jsonMap = Map<String, dynamic>.from(args);
              jsonMap['scenarioId'] = state.scenarioId ?? '';
              jsonMap['category'] = category;
              jsonMap['durationSeconds'] = state.elapsed.inSeconds;
              jsonMap['createdAt'] = DateTime.now().toIso8601String();

              final feedback = ConversationFeedback.fromMap(jsonMap);
              debugPrint(
                'LiveServerToolCall: Parsed feedback successfully. Score: \${feedback.overallScore}',
              );

              // Store feedback; endConversation() will set status=ended + metrics
              state = state.copyWith(
                sessionFeedback: feedback,
                status: ConversationStatus.analyzing,
              );

              // Respond to the tool call so Gemini knows we received it
              _service.sendToolResponse([
                FunctionResponse(call.name, {'status': 'success'}, id: call.id),
              ]);

              // End the connection — sets status=ended with Deepgram metrics
              endConversation();
            } catch (e) {
              debugPrint('LiveServerToolCall Error parsing feedback: $e');
              _service.sendToolResponse([
                FunctionResponse(call.name, {
                  'status': 'error',
                  'message': e.toString(),
                }, id: call.id),
              ]);
            }
          }
        }
      }
    }
  }

  /// Flush any accumulated user transcription into a user message bubble.
  void _flushUserTranscription() {
    final userText = _pendingUserTranscription.trim();
    if (userText.isNotEmpty) {
      _pendingUserTranscription = '';
      final userMsg = ConversationMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.user,
        text: userText,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, userMsg]);
    }
  }

  Future<void> _onAiTurnComplete() async {
    // Signal end of data — only if handle is still valid (not already stopped by barge-in)
    if (_audioStream != null &&
        _audioHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_audioHandle!)) {
      SoLoud.instance.setDataIsEnded(_audioStream!);
    }

    final transcription = state.currentTranscription.trim();
    Uint8List? audioBytes;

    // Grab the full audio from this turn (already played via stream)
    if (_turnAudioBuffer.isNotEmpty) {
      audioBytes = Uint8List.fromList(_turnAudioBuffer);
      _turnAudioBuffer.clear();
    }

    if (transcription.isNotEmpty || audioBytes != null) {
      final aiMsg = ConversationMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.ai,
        text: transcription.isNotEmpty ? transcription : 'AI response',
        audioBytes: audioBytes,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        currentTranscription: '',
        status: ConversationStatus.active,
      );
    } else {
      state = state.copyWith(
        currentTranscription: '',
        status: ConversationStatus.active,
      );
    }

    // Set up a new stream for the next AI turn
    await _setupNewStream();
    if (_audioStream != null) {
      await _startAudioPlayback();
    }

    _bargeInActive = false;
    _micResumeTimer?.cancel();
    _micResumeTimer = Timer(const Duration(milliseconds: 150), () {
      _isAiSpeaking = false;
      _bargeInFrameCount = 0;
      // Mic stays running — no restart needed
      if (!_closed && !state.isMicMuted && mounted) {
        if (!_micIsActive) _startMicStream(); // fallback if somehow stopped
      }
    });
  }

  /// RMS amplitude from raw PCM16 bytes, returns 0.0–1.0.
  double _pcmAmplitude(Uint8List bytes) {
    if (bytes.length < 2) return 0.0;
    final samples = bytes.buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (final s in samples) {
      final norm = s / 32768.0;
      sum += norm * norm;
    }
    return sqrt(sum / samples.length).clamp(0.0, 1.0);
  }

  /// User spoke loudly enough to interrupt AI. Stop playback, hand floor back.
  void _onBargeIn(Uint8List triggerChunk) {
    if (!_isAiSpeaking || _closed) return;
    debugPrint('Barge-in detected — interrupting AI');
    _isAiSpeaking = false;
    _bargeInActive = true;
    _bargeInFrameCount = 0;
    _micResumeTimer?.cancel();

    // Signal data ended — SoLoud stops playing naturally.
    // Avoid stop(handle) which uses FFI callbacks that crash if Dart closure is GC'd.
    if (_audioStream != null && SoLoud.instance.isInitialized) {
      try { SoLoud.instance.setDataIsEnded(_audioStream!); } catch (_) {}
    }
    _audioStream = null;
    _audioHandle = null;

    // Send the chunk that triggered barge-in — Gemini detects user speaking
    // and cancels its current generation server-side.
    _service.sendAudioRealtime(triggerChunk);

    if (mounted) {
      state = state.copyWith(status: ConversationStatus.userSpeaking);
    }

    // Safety: if turnComplete never arrives (e.g. network drop), unblock after 5s
    Timer(const Duration(seconds: 5), () {
      if (_bargeInActive && !_closed) {
        debugPrint('Barge-in safety timeout — clearing _bargeInActive');
        _bargeInActive = false;
      }
    });
  }

  Future<void> requestFeedbackAndEnd() async {
    if (state.status == ConversationStatus.ended ||
        state.status == ConversationStatus.analyzing) {
      return;
    }

    // Stop mic stream so user doesn't interrupt the final processing
    await _stopMicStream();

    state = state.copyWith(status: ConversationStatus.analyzing);

    // Ask Gemini for the feedback tool call
    await _service.sendText(
      'The session is over. Evaluate my performance based on our conversation and my vocal tone. Call the submit_session_feedback tool with the scores and feedback, then briefly say goodbye.',
    );

    // Add a failsafe timeout. If Gemini doesn't call the tool within 15 seconds,
    // end the conversation anyway so the user isn't stuck.
    Timer(const Duration(seconds: 15), () {
      if (mounted && state.status == ConversationStatus.analyzing) {
        debugPrint(
          'requestFeedbackAndEnd: Timed out waiting for tool call. Falling back.',
        );
        endConversation();
      }
    });
  }

  Future<void> endConversation() async {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _micResumeTimer?.cancel();

    _flushUserTranscription();
    await _stopMicStream();
    await _teardownAudioEngine();
    await _service.close();
    await _deactivateAudioSession(); // release audio focus → music resumes

    if (mounted) {
      state = state.copyWith(status: ConversationStatus.ended);
    }
  }

  // Firebase Live API hard limit: 15 min audio-only sessions
  static const Duration _sessionHardLimit = Duration(minutes: 14, seconds: 30);

  void _startTimer() {
    _timer?.cancel();
    _wrapUpWarningSent = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(
          elapsed: state.elapsed + const Duration(seconds: 1),
        );

        final elapsed = state.elapsed;
        final status = state.status;

        if (status == ConversationStatus.ended ||
            status == ConversationStatus.analyzing) {
          return;
        }

        // Hard cap: 14m30s — end before Firebase 15-min server disconnect
        if (elapsed >= _sessionHardLimit) {
          debugPrint('Session hard limit reached — ending gracefully.');
          if (state.scenarioId != null) {
            requestFeedbackAndEnd();
          } else {
            endConversation();
          }
          return;
        }

        // Scenario timer: warn + auto-end at scenario duration
        if (state.durationLimitMinutes != null) {
          final limit = Duration(minutes: state.durationLimitMinutes!);
          final remaining = limit - elapsed;

          if (remaining.inSeconds <= 30 && !_wrapUpWarningSent) {
            _wrapUpWarningSent = true;
            _service.sendText(
              'There are only 30 seconds left in our session. Please immediately start wrapping up the conversation naturally, ask a final quick question, or say your goodbyes.',
            );
          }

          if (state.isTimeUp) {
            if (state.scenarioId != null) {
              requestFeedbackAndEnd();
            } else {
              endConversation();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    _micResumeTimer?.cancel();
    _amplitudeTimer?.cancel();
    _micSubscription?.cancel();
    _recorder.dispose();
    _teardownAudioEngine(); // fire-and-forget: deinit is fast, no callbacks
    _service.close();
    super.dispose();
  }
}
