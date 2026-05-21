import 'package:flutter/material.dart';

import '../domain/assessment_entity.dart';
import '../domain/learning_plan_entity.dart';

// --- Public Roadmap Metadata (for catalog screen) ---

class RoadmapMeta {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final int stepCount;
  final String difficultyLabel;

  const RoadmapMeta({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.stepCount,
    required this.difficultyLabel,
  });
}

const allRoadmapMetas = [
  RoadmapMeta(
    id: 'career_confidence',
    title: 'Interview Prep',
    description: 'Master every stage — from first impressions to salary negotiation.',
    emoji: '\u{1F4BC}',
    color: Color(0xFF4F8EF7),
    stepCount: 15,
    difficultyLabel: 'Easy → Hard',
  ),
  RoadmapMeta(
    id: 'social_butterfly',
    title: 'Social Confidence',
    description: 'Build real social skills step by step — small talk to confident connections.',
    emoji: '\u{1F91D}',
    color: Color(0xFF9B5CF6),
    stepCount: 15,
    difficultyLabel: 'Easy → Hard',
  ),
  RoadmapMeta(
    id: 'stage_ready',
    title: 'Public Speaking',
    description: 'Go from nervous speaker to commanding any stage with confidence.',
    emoji: '\u{1F3A4}',
    color: Color(0xFFE84D8A),
    stepCount: 15,
    difficultyLabel: 'Easy → Hard',
  ),
  RoadmapMeta(
    id: 'anxiety_buster',
    title: 'Anxiety Buster',
    description: 'Gentle progressive practice — start low-pressure, build to real confidence.',
    emoji: '\u{1F4AA}',
    color: Color(0xFF10B981),
    stepCount: 15,
    difficultyLabel: 'Gentle Pace',
  ),
  RoadmapMeta(
    id: 'tough_conversations',
    title: 'Tough Conversations',
    description: 'Practice the conversations you\'ve been avoiding — boundaries, raises, conflict, and hard truths.',
    emoji: '\u{1F525}',
    color: Color(0xFFEF4444),
    stepCount: 15,
    difficultyLabel: 'Easy → Hard',
  ),
  RoadmapMeta(
    id: 'gen_z_work',
    title: 'Gen Z at Work',
    description: 'Level up your workplace communication — meetings, feedback, phone calls, and negotiation.',
    emoji: '\u{1F4BC}',
    color: Color(0xFF6366F1),
    stepCount: 15,
    difficultyLabel: 'Easy → Hard',
  ),
];

LearningPlan generatePlanFromTemplateId(String templateId) {
  final template = _templates.firstWhere(
    (t) => t.id == templateId,
    orElse: () => _templates.last,
  );
  return LearningPlan(
    templateId: template.id,
    title: template.title,
    description: template.description,
    steps: template.steps
        .asMap()
        .entries
        .map((e) => PlanStep(
              scenarioId: e.value.scenarioId,
              order: e.key,
              difficulty: e.value.difficulty,
              minPassScore: e.value.minPassScore,
            ))
        .toList(),
    createdAt: DateTime.now(),
  );
}

// --- Assessment Questions ---

class AssessmentOption {
  final String id;
  final String label;
  final String emoji;

  const AssessmentOption({
    required this.id,
    required this.label,
    required this.emoji,
  });
}

class AssessmentQuestion {
  final String id;
  final String text;
  final List<AssessmentOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
}

const assessmentQuestions = [
  AssessmentQuestion(
    id: 'goal',
    text: "What's your main speaking goal?",
    options: [
      AssessmentOption(
          id: 'career', label: 'Ace job interviews', emoji: '\u{1F4BC}'),
      AssessmentOption(
          id: 'social', label: 'Feel confident socially', emoji: '\u{1F91D}'),
      AssessmentOption(
          id: 'public', label: 'Master public speaking', emoji: '\u{1F3A4}'),
      AssessmentOption(
          id: 'dating',
          label: 'Navigate dating conversations',
          emoji: '\u{1F496}'),
    ],
  ),
  AssessmentQuestion(
    id: 'level',
    text: 'How would you rate your current speaking skills?',
    options: [
      AssessmentOption(
          id: 'beginner', label: 'Just starting out', emoji: '\u{1F331}'),
      AssessmentOption(
          id: 'intermediate',
          label: 'Decent but want to improve',
          emoji: '\u{1F4AA}'),
      AssessmentOption(
          id: 'advanced',
          label: 'Good but want to be great',
          emoji: '\u{2B50}'),
    ],
  ),
  AssessmentQuestion(
    id: 'challenge',
    text: "What's your biggest speaking challenge?",
    options: [
      AssessmentOption(
          id: 'confidence', label: 'Lack of confidence', emoji: '\u{1F614}'),
      AssessmentOption(
          id: 'filler', label: 'Too many filler words', emoji: '\u{1F4AC}'),
      AssessmentOption(
          id: 'structure', label: 'Organizing my thoughts', emoji: '\u{1F9E9}'),
      AssessmentOption(
          id: 'anxiety', label: 'Speaking anxiety', emoji: '\u{1F630}'),
    ],
  ),
  AssessmentQuestion(
    id: 'context',
    text: 'Where do you speak most?',
    options: [
      AssessmentOption(
          id: 'work', label: 'Work / professional', emoji: '\u{1F3E2}'),
      AssessmentOption(
          id: 'social', label: 'Social gatherings', emoji: '\u{1F389}'),
      AssessmentOption(
          id: 'school', label: 'School / university', emoji: '\u{1F393}'),
      AssessmentOption(
          id: 'phone', label: 'Phone calls', emoji: '\u{1F4F1}'),
    ],
  ),
  AssessmentQuestion(
    id: 'time',
    text: 'How much time can you practice daily?',
    options: [
      AssessmentOption(id: '5min', label: '5 minutes', emoji: '\u{23F1}'),
      AssessmentOption(id: '10min', label: '10 minutes', emoji: '\u{23F0}'),
      AssessmentOption(id: '15min', label: '15+ minutes', emoji: '\u{1F525}'),
    ],
  ),
  AssessmentQuestion(
    id: 'event_date',
    text: 'When is your target event?',
    options: [
      AssessmentOption(
          id: 'this_week', label: 'This week', emoji: '\u{1F525}'),
      AssessmentOption(
          id: 'this_month', label: 'This month', emoji: '\u{1F4C5}'),
      AssessmentOption(
          id: 'two_months', label: 'In 2+ months', emoji: '\u{1F5D3}'),
      AssessmentOption(
          id: 'no_date', label: 'No specific date', emoji: '\u{1F3AF}'),
    ],
  ),
];

// --- Chain Step Config ---

class _ChainStep {
  final String scenarioId;
  final String difficulty;
  final int minPassScore;

  const _ChainStep({
    required this.scenarioId,
    required this.difficulty,
    required this.minPassScore,
  });
}

// --- Chain Templates ---

class _ChainTemplate {
  final String id;
  final String title;
  final String description;
  final List<_ChainStep> steps;

  const _ChainTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });
}

const _templates = [
  _ChainTemplate(
    id: 'career_confidence',
    title: 'Interview Prep',
    description:
        'Master every stage of the interview process — from first impressions to salary negotiation.',
    steps: [
      _ChainStep(scenarioId: 'int_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'int_6', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'int_7', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'int_2', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'int_8', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'int_9', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'int_10', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_5', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_11', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_12', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conf_1', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'pres_1', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_13', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'int_4', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'int_3', difficulty: 'hard', minPassScore: 80),
    ],
  ),
  _ChainTemplate(
    id: 'social_butterfly',
    title: 'Social Confidence',
    description:
        'Build real social skills step by step — from small talk to confident connections.',
    steps: [
      _ChainStep(scenarioId: 'social_1', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'social_2', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'social_3', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'social_4', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'social_5', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'social_6', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'social_7', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'social_8', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'social_9', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'social_10', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'social_11', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'social_12', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'social_13', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'social_14', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'social_15', difficulty: 'hard', minPassScore: 75),
    ],
  ),
  _ChainTemplate(
    id: 'stage_ready',
    title: 'Public Speaking',
    description:
        'Go from nervous speaker to commanding any stage with confidence.',
    steps: [
      _ChainStep(scenarioId: 'stage_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'stage_2', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'stage_3', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'stage_4', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'stage_5', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'stage_6', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'stage_7', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'stage_8', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'stage_9', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'stage_10', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'stage_11', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'stage_12', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'stage_13', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'stage_14', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'stage_15', difficulty: 'hard', minPassScore: 80),
    ],
  ),
  _ChainTemplate(
    id: 'anxiety_buster',
    title: 'Anxiety Buster',
    description:
        'Gentle progressive practice — start low-pressure, build to real confidence.',
    steps: [
      _ChainStep(scenarioId: 'anxiety_1', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'anxiety_2', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'anxiety_3', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'anxiety_4', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'anxiety_5', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'anxiety_6', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'anxiety_7', difficulty: 'medium', minPassScore: 60),
      _ChainStep(scenarioId: 'anxiety_8', difficulty: 'medium', minPassScore: 60),
      _ChainStep(scenarioId: 'anxiety_9', difficulty: 'medium', minPassScore: 60),
      _ChainStep(scenarioId: 'anxiety_10', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'anxiety_11', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'anxiety_12', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'anxiety_13', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'anxiety_14', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'anxiety_15', difficulty: 'hard', minPassScore: 75),
    ],
  ),
  _ChainTemplate(
    id: 'tough_conversations',
    title: 'Tough Conversations',
    description:
        'Practice the conversations you\'ve been avoiding — boundaries, raises, conflict, and hard truths.',
    steps: [
      _ChainStep(scenarioId: 'tough_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'tough_2', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'tough_3', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'tough_4', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'tough_5', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'tough_6', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'tough_7', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'tough_8', difficulty: 'medium', minPassScore: 68),
      _ChainStep(scenarioId: 'tough_9', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'tough_10', difficulty: 'hard', minPassScore: 78),
      _ChainStep(scenarioId: 'tough_11', difficulty: 'hard', minPassScore: 76),
      _ChainStep(scenarioId: 'tough_12', difficulty: 'hard', minPassScore: 77),
      _ChainStep(scenarioId: 'tough_13', difficulty: 'hard', minPassScore: 80),
      _ChainStep(scenarioId: 'tough_14', difficulty: 'hard', minPassScore: 78),
      _ChainStep(scenarioId: 'tough_15', difficulty: 'hard', minPassScore: 80),
    ],
  ),
  _ChainTemplate(
    id: 'gen_z_work',
    title: 'Gen Z at Work',
    description:
        'Level up your workplace communication — meetings, feedback, phone calls, and negotiation.',
    steps: [
      _ChainStep(scenarioId: 'genz_1', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'genz_2', difficulty: 'easy', minPassScore: 52),
      _ChainStep(scenarioId: 'genz_3', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'genz_4', difficulty: 'medium', minPassScore: 62),
      _ChainStep(scenarioId: 'genz_5', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'genz_6', difficulty: 'medium', minPassScore: 67),
      _ChainStep(scenarioId: 'genz_7', difficulty: 'medium', minPassScore: 68),
      _ChainStep(scenarioId: 'genz_8', difficulty: 'medium', minPassScore: 64),
      _ChainStep(scenarioId: 'genz_9', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'genz_10', difficulty: 'medium', minPassScore: 66),
      _ChainStep(scenarioId: 'genz_11', difficulty: 'medium', minPassScore: 68),
      _ChainStep(scenarioId: 'genz_12', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'genz_13', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'genz_14', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'genz_15', difficulty: 'hard', minPassScore: 78),
    ],
  ),
];

// --- Event Date → Sessions Per Day ---

int _sessionsPerDay(String? eventDateId) {
  switch (eventDateId) {
    case 'this_week':
      return 3;
    case 'this_month':
      return 1;
    case 'two_months':
      return 1;
    default:
      return 1;
  }
}

DateTime? _eventDate(String? eventDateId) {
  final now = DateTime.now();
  switch (eventDateId) {
    case 'this_week':
      return now.add(const Duration(days: 5));
    case 'this_month':
      return now.add(const Duration(days: 25));
    case 'two_months':
      return now.add(const Duration(days: 60));
    default:
      return null;
  }
}

// --- Mapping Engine ---

String matchTemplate(List<AssessmentAnswer> answers) {
  final answerMap = {for (final a in answers) a.questionId: a.optionId};

  // Priority 1: Anxiety override
  if (answerMap['challenge'] == 'anxiety') return 'anxiety_buster';

  // Priority 2: Filler/structure challenge → boundaries + workplace fit
  if (answerMap['challenge'] == 'confidence' &&
      answerMap['context'] == 'work') {
    return 'gen_z_work';
  }

  // Priority 3: Goal-based
  switch (answerMap['goal']) {
    case 'career':
      // Level beginner → gen_z_work (easier entry), others → interview prep
      return answerMap['level'] == 'beginner'
          ? 'gen_z_work'
          : 'career_confidence';
    case 'social':
    case 'dating':
      return 'social_butterfly';
    case 'public':
      return 'stage_ready';
  }

  // Default → tough_conversations (replaced well_rounded)
  return 'tough_conversations';
}

LearningPlan generatePlan(AssessmentResult result) {
  final template = _templates.firstWhere(
    (t) => t.id == result.templateId,
    orElse: () => _templates.last,
  );

  final answerMap = {
    for (final a in result.answers) a.questionId: a.optionId
  };
  final eventDateId = answerMap['event_date'];

  return LearningPlan(
    templateId: template.id,
    title: template.title,
    description: template.description,
    steps: template.steps
        .asMap()
        .entries
        .map(
          (e) => PlanStep(
            scenarioId: e.value.scenarioId,
            order: e.key,
            difficulty: e.value.difficulty,
            minPassScore: e.value.minPassScore,
          ),
        )
        .toList(),
    createdAt: DateTime.now(),
    eventDate: _eventDate(eventDateId),
    sessionsPerDayTarget: _sessionsPerDay(eventDateId),
  );
}
