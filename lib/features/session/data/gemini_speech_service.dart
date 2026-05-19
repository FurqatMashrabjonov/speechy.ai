import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_coach/features/session/domain/feedback_entity.dart';

class GeminiSpeechService {
  GenerativeModel? _model;

  GenerativeModel get model {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<FeedbackEntity> analyzeSpeech({
    required Uint8List audioBytes,
    required String mimeType,
    required String category,
    required String prompt,
  }) async {
    final systemPrompt =
        '''
You are an expert speaking coach. Analyze this speech recording for a "$category" practice session.
The speaker's prompt was: "$prompt"

Analyze the speech and return ONLY a valid JSON object (no markdown, no code fences) with these fields:
{
  "overallScore": <0-100>,
  "clarity": <0-100>,
  "pace": <0-100>,
  "fillerWords": <0-100 where 100 means no filler words>,
  "confidence": <0-100>,
  "strengths": ["strength1", "strength2", "strength3"],
  "improvements": ["improvement1", "improvement2", "improvement3"],
  "transcript": "full transcript of what was said",
  "detailedAnalysis": "2-3 paragraph detailed feedback about the speaker's performance"
}

Be encouraging but honest. Provide actionable feedback.''';

    final audioPart = InlineDataPart(mimeType, audioBytes);
    final textPart = TextPart(systemPrompt);

    final response = await model.generateContent([
      Content.multi([audioPart, textPart]),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return _parseResponse(text);
  }

  FeedbackEntity _parseResponse(String text) {
    try {
      // Strip markdown code fences if present
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(cleaned.indexOf('\n') + 1);
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
        }
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return FeedbackEntity.fromMap(json);
    } catch (e) {
      debugPrint('Failed to parse Gemini response: $e\nRaw: $text');
      // Return a fallback if parsing fails
      return FeedbackEntity(
        overallScore: 50,
        clarity: 50,
        pace: 50,
        fillerWords: 50,
        confidence: 50,
        strengths: ['Keep practicing!'],
        improvements: ['Try recording again for a better analysis'],
        transcript: '',
        detailedAnalysis:
            'We had trouble analyzing your recording. Please try again with clearer audio.',
      );
    }
  }
}
