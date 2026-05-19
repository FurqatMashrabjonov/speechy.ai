import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_coach/features/feedback/domain/feedback_entity.dart';

class ConversationFeedbackService {
  GenerativeModel? _model;

  GenerativeModel get model {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  static const _categoryRubrics = {
    'Interviews':
        'Scoring weights: Relevance 30%, Confidence 30%, Clarity 25%, Engagement 15%. '
        'Relevance: Did they answer the question asked? Were examples specific and structured (STAR method)? '
        'Confidence: Did they project authority without arrogance? Minimal hedging and filler words? '
        'Clarity: Were answers concise and well-organized? Easy to follow? '
        'Engagement: Did they build rapport with the interviewer? Ask good questions back?',
    'Presentations':
        'Scoring weights: Clarity 30%, Confidence 25%, Engagement 25%, Relevance 20%. '
        'Clarity: Was the structure clear (intro, body, conclusion)? Were key points easy to identify? '
        'Confidence: Did they project executive presence? Strong vocal delivery? '
        'Engagement: Did they hold attention? Use stories or data effectively? '
        'Relevance: Did the content match the presentation context?',
    'Public Speaking':
        'Scoring weights: Engagement 30%, Confidence 25%, Clarity 25%, Relevance 20%. '
        'Engagement: Did the audience stay hooked? Were there emotional peaks? '
        'Confidence: Was delivery commanding? Good use of pauses and emphasis? '
        'Clarity: Was the message clear and memorable? Well-structured narrative? '
        'Relevance: Did the speech match the occasion and audience?',
    'Conversations':
        'Scoring weights: Engagement 30%, Clarity 25%, Confidence 25%, Relevance 20%. '
        'Engagement: Did they keep the conversation flowing? Ask good follow-ups? '
        'Clarity: Were they easy to understand? Did they express thoughts coherently? '
        'Confidence: Were they comfortable and natural? Not overly nervous? '
        'Relevance: Did they stay on topic and respond appropriately?',
    'Debates':
        'Scoring weights: Relevance 35%, Clarity 25%, Confidence 25%, Engagement 15%. '
        'Relevance: Did arguments directly address the topic? Were rebuttals on point? '
        'Clarity: Were arguments logically structured and easy to follow? '
        'Confidence: Did they stand firm under pressure? Project conviction? '
        'Engagement: Did they acknowledge opposing points? Maintain respectful dialogue?',
    'Storytelling':
        'Scoring weights: Engagement 35%, Clarity 25%, Confidence 20%, Relevance 20%. '
        'Engagement: Was the story captivating? Did it have emotional hooks? '
        'Clarity: Was the narrative arc clear (setup, tension, resolution)? '
        'Confidence: Was delivery natural and expressive? '
        'Relevance: Did the story match the prompt and convey a clear message?',
    'Phone Anxiety':
        'Scoring weights: Confidence 35%, Clarity 30%, Relevance 25%, Engagement 10%. '
        'Confidence: Did they sound calm and composed? Minimal hesitation? '
        'Clarity: Were requests/information stated clearly? Easy to understand? '
        'Relevance: Did they accomplish the phone call objective? '
        'Engagement: Were they polite and appropriately conversational?',
    'Dating & Social':
        'Scoring weights: Engagement 35%, Confidence 30%, Relevance 20%, Clarity 15%. '
        'Engagement: Was there genuine chemistry and curiosity? Good questions asked? '
        'Confidence: Were they comfortable, natural, not overly eager or aloof? '
        'Relevance: Did they respond appropriately to social cues? '
        'Clarity: Were they articulate and easy to talk to?',
    'Conflict & Boundaries':
        'Scoring weights: Confidence 30%, Relevance 30%, Clarity 25%, Engagement 15%. '
        'Confidence: Did they stay assertive without being aggressive? Hold firm? '
        'Relevance: Did they address the actual issue directly? Stay on point? '
        'Clarity: Was their message unambiguous? Were expectations clearly stated? '
        'Engagement: Did they listen to the other side and show empathy?',
    'Social Situations':
        'Scoring weights: Engagement 35%, Confidence 25%, Clarity 25%, Relevance 15%. '
        'Engagement: Did they keep the social interaction flowing? Show genuine interest? '
        'Confidence: Were they approachable and comfortable? Natural body language? '
        'Clarity: Did they express themselves clearly and concisely? '
        'Relevance: Did they read social cues and respond appropriately?',
  };

  Future<ConversationFeedback> analyzeConversation({
    required String transcript,
    required String category,
    required String scenarioTitle,
    required String scenarioPrompt,
    required String scenarioId,
    required int durationSeconds,
  }) async {
    // Guard: if transcript is too short, return a gentle fallback
    final userLines = transcript
        .split('\n')
        .where((l) => l.startsWith('User:') && l.trim().length > 6)
        .length;
    if (transcript.trim().isEmpty || userLines == 0) {
      debugPrint(
        'FeedbackService: transcript empty or no user speech — returning fallback',
      );
      return ConversationFeedback(
        clarity: 50,
        confidence: 50,
        engagement: 50,
        relevance: 50,
        overallScore: 50,
        summary:
            'We couldn\'t detect enough speech to analyze. Try speaking more in your next session!',
        strengths: ['You showed up to practice — that\'s a great start!'],
        improvements: [
          'Speak more during the conversation so we can give detailed feedback',
        ],
        createdAt: DateTime.now(),
        scenarioId: scenarioId,
        category: category,
        durationSeconds: durationSeconds,
      );
    }

    final rubric =
        _categoryRubrics[category] ?? _categoryRubrics['Conversations']!;

    final prompt =
        '''
You are an expert speaking coach analyzing a practice conversation.

Category: $category
Scenario: $scenarioTitle
Context: $scenarioPrompt

$rubric

Here is the full transcript of the conversation:
---
$transcript
---

Analyze the speaker's performance and return ONLY a valid JSON object (no markdown, no code fences) with these fields:
{
  "clarity": <0-100 score>,
  "confidence": <0-100 score>,
  "engagement": <0-100 score>,
  "relevance": <0-100 score>,
  "overallScore": <0-100 weighted composite based on the category weights above>,
  "summary": "2-3 sentence summary of their performance",
  "strengths": ["strength1", "strength2", "strength3"],
  "improvements": ["specific improvement tip 1", "specific improvement tip 2", "specific improvement tip 3"]
}

IMPORTANT: All scores (clarity, confidence, engagement, relevance) must be on a 0-100 scale, NOT 1-10.
Be encouraging but honest. Provide specific, actionable feedback.''';

    debugPrint(
      'FeedbackService: sending ${prompt.length} char prompt to Gemini...',
    );
    final response = await model.generateContent([Content.text(prompt)]);

    final text = response.text;
    debugPrint(
      'FeedbackService: received response (${text?.length ?? 0} chars)',
    );
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return _parseResponse(
      text,
      scenarioId: scenarioId,
      category: category,
      durationSeconds: durationSeconds,
    );
  }

  ConversationFeedback _parseResponse(
    String text, {
    required String scenarioId,
    required String category,
    required int durationSeconds,
  }) {
    try {
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(cleaned.indexOf('\n') + 1);
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
        }
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      // Migration guard: if AI returned 1-10 scale scores, scale to 0-100.
      // Only apply if ALL four subscores are ≤ 10 (to avoid corrupting
      // legitimate low scores on the 0-100 scale).
      final subscoreKeys = ['clarity', 'confidence', 'engagement', 'relevance'];
      final allLowScale = subscoreKeys.every(
        (key) => json[key] != null && (json[key] as num).toInt() <= 10,
      );
      if (allLowScale) {
        debugPrint('FeedbackService: detected 1-10 scale, converting to 0-100');
        for (final key in subscoreKeys) {
          json[key] = ((json[key] as num).toInt() * 10);
        }
        // Also scale overallScore if it was on 1-10 scale
        if (json['overallScore'] != null &&
            (json['overallScore'] as num).toInt() <= 10) {
          json['overallScore'] = ((json['overallScore'] as num).toInt() * 10);
        }
      }

      json['scenarioId'] = scenarioId;
      json['category'] = category;
      json['durationSeconds'] = durationSeconds;
      json['createdAt'] = DateTime.now().toIso8601String();
      return ConversationFeedback.fromMap(json);
    } catch (e) {
      debugPrint('Failed to parse feedback response: $e\nRaw: $text');
      return ConversationFeedback(
        clarity: 50,
        confidence: 50,
        engagement: 50,
        relevance: 50,
        overallScore: 50,
        summary:
            'We had trouble analyzing your conversation. Please try again.',
        strengths: ['Keep practicing!'],
        improvements: ['Try another session for better analysis'],
        createdAt: DateTime.now(),
        scenarioId: scenarioId,
        category: category,
        durationSeconds: durationSeconds,
      );
    }
  }
}
