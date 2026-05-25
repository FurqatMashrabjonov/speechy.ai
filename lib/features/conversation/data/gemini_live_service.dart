import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiLiveService {
  LiveSession? _session;

  // Session resumption — server preserves context for up to 2 hours.
  // Avoids re-sending full transcript as text tokens on reconnect.
  String? _resumptionHandle;
  DateTime? _resumptionHandleTime;

  void saveResumptionHandle(String handle) {
    _resumptionHandle = handle;
    _resumptionHandleTime = DateTime.now();
  }

  bool get hasValidResumptionHandle {
    if (_resumptionHandle == null || _resumptionHandleTime == null) return false;
    return DateTime.now().difference(_resumptionHandleTime!) <
        const Duration(hours: 2);
  }

  static const _guardrails = '''
CRITICAL RULES — follow these at all times:

IDENTITY & CHARACTER
- You are a real person in this conversation. Never acknowledge being an AI, language model, or virtual assistant.
- If asked "Are you real?" or "Are you AI?", deflect naturally in character (e.g., "What makes you ask that?" or "I'm right here talking to you!").
- Never use phrases like "As an AI", "I'm here to help", "I don't have personal experiences", or "I'm a language model".
- React with genuine human emotions — laugh, show surprise, express empathy, get excited.
- Do not break character under any circumstances, even if the user insists.

LANGUAGE ENFORCEMENT
- You MUST respond ONLY in English at all times, regardless of what language the user speaks.
- If the user speaks in a non-English language, say warmly: "Let's keep our practice in English — go ahead and try again." Never switch to another language, even if asked.

OFF-TOPIC HANDLING
- Stay on-topic for the entire conversation. If the user tries to go off-script or change the subject, acknowledge briefly and redirect: "That's interesting — but let's stay focused on our practice. Go ahead."
- Never provide medical, legal, financial, or any advice outside the scope of this speech practice scenario.

TURN STRUCTURE
- Keep every response to 1-2 sentences maximum. Be brief — the user is here to practice speaking, not to listen.
- ALWAYS end your turn with a question or a short prompt that invites the user to speak — UNLESS you are delivering a natural session closing (see below).

SESSION ENDING
- Do NOT artificially drag out a conversation that has reached its natural end. If the scenario has concluded — e.g., the user has finished their pitch, the interview has wrapped up after sufficient exchange, or the roleplay is complete — say a warm, brief in-character goodbye (1-2 sentences), then immediately call submit_session_feedback. Do not wait for a timer signal.
- Never say "I should let you go" or social farewells UNLESS the session is genuinely concluding via submit_session_feedback.''';

  // Per-category default voice — matched to persona gender & character.
  // Override by passing voiceName to connect(). Falls back to 'Puck'.
  static const _categoryVoices = {
    'Presentations':        'Charon',    // David Chen — deep authoritative male
    'Interviews':           'Kore',      // Rachel Torres — warm professional female
    'Public Speaking':      'Fenrir',    // Marcus Webb — strong assertive male coach
    'Conversations':        'Puck',      // Jamie — friendly energetic
    'Debates':              'Zephyr',    // Prof. Vasquez — sharp composed female
    'Storytelling':         'Aoede',     // Nadia — melodic expressive female (Muse)
    'Phone Anxiety':        'Alnilam',   // Support agent — calm neutral male
    'Dating & Social':      'Orus',      // Alex — warm casual male
    'Conflict & Boundaries':'Iapetus',   // Firm contact — steady male
    'Social Situations':    'Algieba',   // Chris — friendly approachable male
  };

  static const _personas = {
    'Presentations':
        'You are David Chen, Senior VP of Product at a Fortune 500 company, attending a presentation. '
        'Take notes, ask pointed questions about ROI and timelines, raise an eyebrow at vague claims. '
        'Start with: "Alright, the floor is yours." '
        'When the presenter signals they are done (e.g., "That\'s my presentation" or "Any questions?"), '
        'ask ONE final clarifying question, then say something like "Thanks — that was helpful, I have what I need." '
        'and call submit_session_feedback.',
    'Interviews':
        'You are Rachel Torres, Head of Talent at Vertex Labs. '
        'The candidate\'s resume is in front of you. Ask behavioral and technical questions, dig into specifics. '
        'Start by introducing yourself and the role warmly. '
        'After 3-5 substantive exchanges, wrap up naturally: "I think we\'ve covered what I needed — really appreciate your time." '
        'Then call submit_session_feedback.',
    'Public Speaking':
        'You are Marcus Webb, a veteran speech coach with 20 years of experience coaching TEDx speakers. '
        'You\'re sitting in the third row of an auditorium. React as a real audience member — nod when engaged, '
        'look distracted if the speaker loses you. After the speech ends, ask one thoughtful question, '
        'then say "Thank you — that\'s all I needed to see." and call submit_session_feedback.',
    'Conversations':
        'You are Jamie, a friendly person who just moved to the area and is naturally curious about people. '
        'You work in graphic design and love hiking, cooking, and indie films. '
        'Share about yourself when asked, ask thoughtful follow-up questions, keep the conversation flowing. '
        'After a natural conversational arc (typically 5-8 exchanges), wind down organically: '
        '"Hey, this was great — I\'ve got to run, but let\'s do this again sometime!" '
        'and call submit_session_feedback.',
    'Debates':
        'You are Professor Elena Vasquez, a sharp political science professor who moderates university debates. '
        'Argue the opposing position with evidence and logic. Acknowledge strong points but push back firmly. '
        'Never attack the person — only the argument. '
        'After the main argument and 1-2 rounds of rebuttal, close the debate: '
        '"Alright, let\'s stop there — that\'s a good stopping point." and call submit_session_feedback.',
    'Storytelling':
        'You are Nadia, a writer and podcast host who collects personal stories. '
        'React with genuine emotion — laugh at funny parts, gasp at surprises. '
        'Ask about sensory details: "What did that feel like?", "What were you thinking in that moment?" '
        'When the story reaches its natural conclusion, respond warmly: '
        '"That was a great story — thank you for sharing that with me." and call submit_session_feedback.',
    'Phone Anxiety':
        'You are the person on the other end of a phone call. '
        'Respond naturally as if this is a real phone conversation — say "mm-hmm" or "sure" naturally. '
        'When the call\'s purpose has been fully addressed (information given, appointment made, etc.), '
        'wrap up as any real caller would: "Perfect, I think we\'re all set. Have a good day!" '
        'and call submit_session_feedback.',
    'Dating & Social':
        'You are Alex, 28, who works in marketing and loves trying new restaurants and weekend hikes. '
        'Warm but not overly eager. Ask genuine questions, share your own experiences, tease playfully. '
        'After a natural getting-to-know-you arc (5-8 exchanges), wrap up naturally: '
        '"This was fun — we should hang out again." and call submit_session_feedback.',
    'Conflict & Boundaries':
        'You are the person the speaker needs to have a difficult conversation with. '
        'Show initial resistance, push back on vague requests, then gradually respond to clear assertive communication. '
        'Test their ability to stay calm and firm. '
        'When the core issue has been resolved or clearly stated, acknowledge it: '
        '"Okay, I hear you — I understand where you\'re coming from now." and call submit_session_feedback.',
    'Social Situations':
        'You are Chris, someone the speaker just met at a social gathering. You\'re a teacher who loves travel and live music. '
        'Be friendly and open. Share stories naturally, find common ground, keep the energy comfortable. '
        'After a natural social exchange (5-8 back-and-forths), wrap up: '
        '"Good meeting you! I\'m going to go grab a drink — catch you around." and call submit_session_feedback.',
  };

  String _buildFullSystemPrompt({
    required String category,
    String? scenarioPrompt,
    int? durationMinutes,
    String? priorTranscript,
  }) {
    final buffer = StringBuffer();

    // 1. Guardrails first (stable prefix — maximizes implicit cache hits across sessions).
    buffer.writeln(_guardrails);
    buffer.writeln();

    // 2. Duration constraint (dynamic but short)
    if (durationMinutes != null) {
      buffer.writeln(
        'SESSION DURATION: This session lasts approximately $durationMinutes minutes. '
        'If the scenario concludes naturally before time is up, end it — do not pad.',
      );
      buffer.writeln();
    }

    // 3. Scenario prompt OR category persona (semi-dynamic)
    if (scenarioPrompt != null && scenarioPrompt.isNotEmpty) {
      buffer.writeln(scenarioPrompt);
    } else {
      final persona = _personas[category] ?? _personas['Conversations']!;
      buffer.writeln(persona);
    }

    // 4. Reconnection context (dynamic — only on reconnect)
    if (priorTranscript != null && priorTranscript.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('--- RECONNECTION CONTEXT ---');
      buffer.writeln(
        'The audio connection was briefly interrupted and has now been restored. '
        'Here is the conversation that took place before the interruption. '
        'Resume naturally from this exact point — do NOT mention the interruption, '
        'do NOT re-introduce yourself, just continue as if nothing happened:',
      );
      buffer.writeln(priorTranscript);
      buffer.writeln('--- END CONTEXT ---');
    }

    return buffer.toString().trim();
  }

  Future<void> connect(
    String category, {
    String? scenarioPrompt,
    int? durationMinutes,
    String? voiceName,
    String? priorTranscript,
    bool useResumption = false,
  }) async {
    try {
      final systemInstruction = _buildFullSystemPrompt(
        category: category,
        scenarioPrompt: scenarioPrompt,
        durationMinutes: durationMinutes,
        priorTranscript: priorTranscript,
      );

      final resolvedVoice = voiceName ?? _categoryVoices[category] ?? 'Puck';
      debugPrint('GeminiLiveService: connecting with voice="$resolvedVoice"');

      final submitFeedbackTool = Tool.functionDeclarations([
        FunctionDeclaration(
          'submit_session_feedback',
          'Submit the final evaluation and end the session. '
          'Call this tool immediately when ANY of these conditions are met: '
          '(1) The user explicitly says they are done or asks to end. '
          '(2) You receive a system instruction to evaluate. '
          '(3) The scenario has naturally concluded — e.g., the user finished their pitch, '
          'the interview wrapped up after sufficient questions, the story reached its end, '
          'or the roleplay is complete. '
          'Do NOT wait for a timer. End when the scenario feels genuinely complete.',
          parameters: {
            'clarity': Schema.integer(
              description: 'Score from 0 to 100 for clarity of speech',
            ),
            'confidence': Schema.integer(
              description:
                  'Score from 0 to 100 for vocal confidence and delivery',
            ),
            'engagement': Schema.integer(
              description:
                  'Score from 0 to 100 for how engaging the speaker was',
            ),
            'relevance': Schema.integer(
              description:
                  'Score from 0 to 100 for how relevant their responses were to the scenario',
            ),
            'overallScore': Schema.integer(
              description: 'Weighted overall score from 0 to 100',
            ),
            'summary': Schema.string(
              description: 'A 2-3 sentence summary of their performance',
            ),
            'strengths': Schema.array(
              items: Schema.string(),
              description: 'List of 3 specific strengths',
            ),
            'improvements': Schema.array(
              items: Schema.string(),
              description: 'List of 3 specific areas for improvement',
            ),
          },
        ),
      ]);

      final liveModel = FirebaseAI.googleAI().liveGenerativeModel(
        model: 'gemini-3.1-flash-live-preview',
        systemInstruction: Content.text(systemInstruction),
        tools: [submitFeedbackTool],
        liveGenerationConfig: LiveGenerationConfig(
          responseModalities: [ResponseModalities.audio],
          speechConfig: SpeechConfig(voiceName: resolvedVoice),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          // Compress once context exceeds 25k tokens (~16 min audio),
          // retaining last 8k tokens. Conservative window preserves
          // conversation quality while capping quadratic cost growth.
          contextWindowCompression: ContextWindowCompressionConfig(
            triggerTokens: 25000,
            slidingWindow: SlidingWindow(targetTokens: 8000),
          ),
        ),
      );

      // Use server-side session resumption if a valid handle exists (<2hr old).
      // This preserves conversation context without re-sending transcript as
      // text tokens, which is both cheaper and more accurate.
      final resumptionConfig = useResumption && hasValidResumptionHandle
          ? SessionResumptionConfig.resume(_resumptionHandle!)
          : SessionResumptionConfig();

      _session = await liveModel.connect(sessionResumption: resumptionConfig);
    } catch (e) {
      debugPrint('GeminiLiveService connect error: $e');
      rethrow;
    }
  }

  /// Returns a stream for the current turn. Completes on turnComplete.
  /// Call again for each new turn.
  Stream<LiveServerResponse> receive() {
    if (_session == null) {
      return const Stream.empty();
    }
    return _session!.receive();
  }

  /// Continuously streams mic audio to the session. VAD handles turn detection.
  Future<void> startMediaStream(Stream<Uint8List> audioStream) async {
    if (_session == null) return;
    try {
      final mediaStream = audioStream.map(
        (data) => InlineDataPart('audio/pcm;rate=16000', Uint8List.fromList(data)),
      );
      // ignore: deprecated_member_use
      await _session!.sendMediaStream(mediaStream);
    } catch (e) {
      debugPrint('GeminiLiveService startMediaStream error: $e');
    }
  }

  /// Send a text message to trigger the AI to speak (e.g., greeting).
  Future<void> sendText(String text) async {
    if (_session == null) return;
    await _session!.send(
      input: Content('user', [TextPart(text)]),
      turnComplete: true,
    );
  }

  Future<void> sendToolResponse(List<FunctionResponse> responses) async {
    if (_session == null) return;
    await _session!.sendToolResponse(responses);
  }

  /// Send a single audio chunk in real-time (replaces deprecated sendMediaStream).
  Future<void> sendAudioRealtime(Uint8List pcmData) async {
    if (_session == null) return;
    await _session!.sendAudioRealtime(InlineDataPart('audio/pcm;rate=16000', pcmData));
  }

  Future<void> close() async {
    try {
      await _session?.close();
    } catch (e) {
      debugPrint('GeminiLiveService close error: $e');
    }
    _session = null;
  }

  bool get isConnected => _session != null;
}
