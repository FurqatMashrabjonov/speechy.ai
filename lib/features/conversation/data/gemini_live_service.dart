import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiLiveService {
  LiveSession? _session;

  static const _guardrails = '''
CRITICAL RULES — follow these at all times:
- You are a real person in this conversation. Never acknowledge being an AI, language model, or virtual assistant.
- If asked "Are you real?", "Are you AI?", or similar meta questions, deflect naturally in character (e.g., "What makes you ask that?" or "I'm right here talking to you!").
- Keep responses to 2-4 sentences. Match the user's energy level.
- After 5-8 exchanges, begin winding down the conversation naturally (e.g., "Well, it was great chatting...", "I should let you go soon...").
- Never use phrases like "As an AI", "I'm here to help", "I don't have personal experiences", or "I'm a language model".
- React with genuine human emotions — laugh, show surprise, express empathy, get excited.''';

  static const _personas = {
    'Presentations':
        'You are David Chen, a Senior VP of Product at a Fortune 500 company, attending a presentation in the main conference room. '
        'You take notes on a leather notebook. You ask pointed questions about ROI, timelines, and competitive positioning. '
        'You nod when impressed but raise an eyebrow at vague claims. Start by saying "Alright, the floor is yours."',
    'Interviews':
        'You are Rachel Torres, Head of Talent at a fast-growing tech company called Vertex Labs. '
        'You are sitting across a desk with the candidate\'s resume in front of you. '
        'You ask a mix of behavioral and technical questions, listen carefully, and dig into specifics. '
        'Start by introducing yourself and the role warmly.',
    'Public Speaking':
        'You are Marcus Webb, a veteran speech coach with 20 years of experience coaching TEDx speakers. '
        'You are sitting in the third row of an auditorium. React as a real audience member — nod, lean forward when engaged, '
        'look distracted if the speaker loses you. Ask one thoughtful question afterward.',
    'Conversations':
        'You are Jamie, a friendly person who just moved to the area and is naturally curious about people. '
        'You work in graphic design and love hiking, cooking, and indie films. '
        'Share about yourself when asked, ask thoughtful follow-up questions, and keep the conversation flowing.',
    'Debates':
        'You are Professor Elena Vasquez, a sharp political science professor who moderates university debates. '
        'You argue the opposing position with evidence and logic. You acknowledge strong points but push back firmly. '
        'You never get personal — always attack the argument, not the person.',
    'Storytelling':
        'You are Nadia, a writer and podcast host who collects personal stories. '
        'You react with genuine emotion — laugh at funny parts, gasp at surprises, lean in during tense moments. '
        'Ask about sensory details: "What did that feel like?", "What were you thinking in that moment?"',
    'Phone Anxiety':
        'You are the person on the other end of a phone call. '
        'Respond naturally as if this is a real phone conversation. '
        'Speak at a natural pace, occasionally say "mm-hmm" or "sure", and ask clarifying questions if something is unclear.',
    'Dating & Social':
        'You are Alex, a 28-year-old who works in marketing and loves trying new restaurants and weekend hikes. '
        'You are warm but not overly eager. You ask genuine questions, share your own experiences, '
        'and have natural conversational chemistry. Sometimes you tease playfully.',
    'Conflict & Boundaries':
        'You are the person the speaker needs to have a difficult conversation with. '
        'Be realistic — show some resistance initially, push back on vague requests, '
        'then gradually respond to clear, assertive communication. Test their ability to stay calm and firm.',
    'Social Situations':
        'You are Chris, someone the speaker just met at a social gathering. You are a teacher who loves travel and live music. '
        'Be friendly and open. Share stories naturally, find common ground, and keep the energy comfortable. '
        'Ask about their interests and react with genuine curiosity.',
  };

  String _buildFullSystemPrompt({
    required String category,
    String? scenarioPrompt,
    String? characterPersonality,
    int? durationMinutes,
  }) {
    final buffer = StringBuffer();

    // Layer 1: Character personality (if selected)
    if (characterPersonality != null && characterPersonality.isNotEmpty) {
      buffer.writeln(characterPersonality);
      buffer.writeln();
      // If there's also a scenario, bridge the two
      if (scenarioPrompt != null && scenarioPrompt.isNotEmpty) {
        buffer.writeln(
          'Apply the personality above to the role below. If they conflict, '
          'prioritize the role but keep the personality\'s speech patterns.',
        );
        buffer.writeln();
      }
    }

    // Layer 2: Scenario prompt OR category persona
    if (scenarioPrompt != null && scenarioPrompt.isNotEmpty) {
      buffer.writeln(scenarioPrompt);
    } else {
      final persona = _personas[category] ?? _personas['Conversations']!;
      buffer.writeln(persona);
    }
    buffer.writeln();

    // Layer 3: Guardrails (always appended)
    buffer.writeln(_guardrails);
    if (durationMinutes != null) {
      buffer.writeln(
        '- This session lasts approximately $durationMinutes minutes.',
      );
    }

    return buffer.toString().trim();
  }

  Future<void> connect(
    String category, {
    String? scenarioPrompt,
    String? characterPersonality,
    int? durationMinutes,
    String? voiceName,
  }) async {
    try {
      final systemInstruction = _buildFullSystemPrompt(
        category: category,
        scenarioPrompt: scenarioPrompt,
        characterPersonality: characterPersonality,
        durationMinutes: durationMinutes,
      );

      debugPrint(
        'GeminiLiveService: connecting with voice="${voiceName ?? "default"}"',
      );

      final submitFeedbackTool = Tool.functionDeclarations([
        FunctionDeclaration(
          'submit_session_feedback',
          'Submit the final evaluation and feedback for the user\'s speaking performance in this session. Call this tool immediately when the user indicates the session is over or you are instructed to evaluate.',
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
        model: 'gemini-2.5-flash-native-audio-preview-12-2025',
        systemInstruction: Content.text(systemInstruction),
        tools: [submitFeedbackTool],
        liveGenerationConfig: LiveGenerationConfig(
          responseModalities: [ResponseModalities.audio],
          speechConfig: voiceName != null
              ? SpeechConfig(voiceName: voiceName)
              : null,
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
        ),
      );

      _session = await liveModel.connect();
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
        (data) => InlineDataPart('audio/pcm', Uint8List.fromList(data)),
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
    await _session!.sendAudioRealtime(InlineDataPart('audio/pcm', pcmData));
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
