import 'dart:async';

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
  final Duration elapsed;
  // Scenario fields
  final String? scenarioId;
  final String? scenarioTitle;
  final String? scenarioPrompt;
  final int? durationLimitMinutes;
  final bool isCountdown;
  // Character fields
  final String? characterName;
  final String? characterVoice;
  final String? characterPersonality;
  // Mic mute state
  final bool isMicMuted;
  // Feedback from live tool call
  final ConversationFeedback? sessionFeedback;

  const ConversationState({
    this.status = ConversationStatus.idle,
    this.messages = const [],
    this.currentTranscription = '',
    this.error,
    this.elapsed = Duration.zero,
    this.scenarioId,
    this.scenarioTitle,
    this.scenarioPrompt,
    this.durationLimitMinutes,
    this.isCountdown = false,
    this.characterName,
    this.characterVoice,
    this.characterPersonality,
    this.isMicMuted = false,
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
    Duration? elapsed,
    String? scenarioId,
    String? scenarioTitle,
    String? scenarioPrompt,
    int? durationLimitMinutes,
    bool? isCountdown,
    String? characterName,
    String? characterVoice,
    String? characterPersonality,
    bool? isMicMuted,
    ConversationFeedback? sessionFeedback,
  }) {
    return ConversationState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      error: error,
      elapsed: elapsed ?? this.elapsed,
      scenarioId: scenarioId ?? this.scenarioId,
      scenarioTitle: scenarioTitle ?? this.scenarioTitle,
      scenarioPrompt: scenarioPrompt ?? this.scenarioPrompt,
      durationLimitMinutes: durationLimitMinutes ?? this.durationLimitMinutes,
      isCountdown: isCountdown ?? this.isCountdown,
      characterName: characterName ?? this.characterName,
      characterVoice: characterVoice ?? this.characterVoice,
      characterPersonality: characterPersonality ?? this.characterPersonality,
      isMicMuted: isMicMuted ?? this.isMicMuted,
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
  bool _closed = false;
  StreamSubscription<List<int>>? _micSubscription;

  // SoLoud streaming audio playback — raw PCM fed directly, no WAV wrapping
  AudioSource? _audioStream;
  SoundHandle? _audioHandle;

  // Keep a copy of all audio for the message bubble
  final List<int> _turnAudioBuffer = [];
  // Buffer for user speech transcription (from inputTranscription)
  String _pendingUserTranscription = '';

  // Echo prevention: track AI speaking state and audio bytes for timing
  bool _isAiSpeaking = false;
  bool _micIsActive = false;
  int _turnAudioBytesSent = 0; // bytes fed to SoLoud this turn
  Timer? _micResumeTimer;
  bool _wrapUpWarningSent = false;

  ConversationNotifier(this._service, this.category)
    : super(const ConversationState());

  void setScenario({
    required String scenarioId,
    required String scenarioTitle,
    required String scenarioPrompt,
    required int durationMinutes,
    String? characterName,
    String? characterVoice,
    String? characterPersonality,
  }) {
    state = state.copyWith(
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      scenarioPrompt: scenarioPrompt,
      durationLimitMinutes: durationMinutes,
      isCountdown: true,
      characterName: characterName,
      characterVoice: characterVoice,
      characterPersonality: characterPersonality,
    );
  }

  void setCharacter({
    required String name,
    required String voiceName,
    required String personality,
  }) {
    state = state.copyWith(
      characterName: name,
      characterVoice: voiceName,
      characterPersonality: personality,
    );
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

    // Stop previous stream if active
    await _stopAudioStream();

    _audioStream = SoLoud.instance.setBufferStream(
      maxBufferSizeBytes: 1024 * 1024 * 10, // 10MB max (not pre-allocated)
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      onBuffering: (isBuffering, handle, time) {},
    );
    _audioHandle = null;
  }

  Future<void> _startAudioPlayback() async {
    if (_audioStream == null) return;
    _audioHandle = await SoLoud.instance.play(_audioStream!);
  }

  Future<void> _stopAudioStream() async {
    if (_audioStream != null &&
        _audioHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_audioHandle!)) {
      SoLoud.instance.setDataIsEnded(_audioStream!);
      await SoLoud.instance.stop(_audioHandle!);
    }
    _audioStream = null;
    _audioHandle = null;
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

      // Initialize SoLoud audio player
      await _initAudioPlayer();

      await _service.connect(
        category,
        scenarioPrompt: state.scenarioPrompt,
        characterPersonality: state.characterPersonality,
        durationMinutes: state.durationLimitMinutes,
        voiceName: state.characterVoice,
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
      state = state.copyWith(
        status: ConversationStatus.error,
        error: 'Failed to connect: ${e.toString().split(':').last.trim()}',
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
          echoCancel: true,
          noiseSuppress: true,
          autoGain: true,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceCommunication,
          ),
        ),
      );

      _micIsActive = true;

      // Send each audio chunk individually via sendAudioRealtime
      _micSubscription = stream.listen((data) {
        if (!_closed) {
          _service.sendAudioRealtime(Uint8List.fromList(data));
        }
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
          final errorStr = e.toString();
          String userError;
          if (errorStr.contains('invalid argument')) {
            userError = 'Invalid configuration. Please try again.';
          } else if (errorStr.contains('WebSocket Closed')) {
            userError = 'Connection closed by server. Please try again.';
          } else {
            userError = 'Connection lost. Please try again.';
          }
          state = state.copyWith(
            status: ConversationStatus.error,
            error: userError,
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
      if (msg.modelTurn != null) {
        if (!_isAiSpeaking) {
          _isAiSpeaking = true;
          _turnAudioBytesSent = 0;
          // Flush any pending user transcription before AI starts its turn
          _flushUserTranscription();
          // Hard-stop mic the moment AI starts talking
          _stopMicStream();
          state = state.copyWith(status: ConversationStatus.aiSpeaking);
        }
        for (final part in msg.modelTurn!.parts) {
          if (part is InlineDataPart && part.mimeType.startsWith('audio')) {
            // Save for the message bubble
            _turnAudioBuffer.addAll(part.bytes);
            _turnAudioBytesSent += part.bytes.length;
            // Feed directly to SoLoud — no WAV wrapping, no buffering
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

              // We successfully parsed the feedback. Set the feedback and close the session.
              state = state.copyWith(
                sessionFeedback: feedback,
                status: ConversationStatus.ended,
              );

              // Respond to the tool call so Gemini knows we received it
              _service.sendToolResponse([
                FunctionResponse(call.name, {'status': 'success'}, id: call.id),
              ]);

              // End the connection
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
    // Signal end of data for this stream segment
    if (_audioStream != null) {
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

    // Calculate how long the remaining audio will play through the speaker.
    // SoLoud plays at 24kHz mono 16-bit = 48000 bytes/sec.
    // turnComplete fires when Gemini finishes SENDING, but SoLoud may still
    // be playing buffered audio. Wait for it to drain + safety margin.
    final remainingMs = (_turnAudioBytesSent / 48000 * 1000).round();
    // Use at least 400ms to account for speaker tail + device latency
    final delayMs = remainingMs.clamp(400, 3000);
    _turnAudioBytesSent = 0;

    _micResumeTimer?.cancel();
    _micResumeTimer = Timer(Duration(milliseconds: delayMs), () {
      _isAiSpeaking = false;
      if (!_closed && !state.isMicMuted && mounted) {
        _startMicStream();
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
    _closed = true;
    _timer?.cancel();
    _micResumeTimer?.cancel();

    // Flush any remaining user transcription before ending
    _flushUserTranscription();

    await _stopMicStream();
    await _stopAudioStream();
    await _service.close();

    if (mounted) {
      state = state.copyWith(status: ConversationStatus.ended);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _wrapUpWarningSent = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(
          elapsed: state.elapsed + const Duration(seconds: 1),
        );

        if (state.durationLimitMinutes != null &&
            state.status != ConversationStatus.ended &&
            state.status != ConversationStatus.analyzing) {
          final limit = Duration(minutes: state.durationLimitMinutes!);
          final remaining = limit - state.elapsed;

          // Send a wrap-up warning 30 seconds before the end
          if (remaining.inSeconds <= 30 && !_wrapUpWarningSent) {
            _wrapUpWarningSent = true;
            _service.sendText(
              'There are only 30 seconds left in our session. Please immediately start wrapping up the conversation naturally, ask a final quick question, or say your goodbyes.',
            );
          }

          // Auto-end when time limit is reached
          if (state.isTimeUp) {
            if (state.scenarioId != null) {
              // Trigger feedback tool and exit gracefully instead of hard cutoff
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
    _micSubscription?.cancel();
    _recorder.dispose();
    _stopAudioStream();
    _service.close();
    super.dispose();
  }
}
