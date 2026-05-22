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

// Q1 — universal: primary goal
const _q1 = AssessmentQuestion(
  id: 'goal',
  text: 'What do you most want to get better at?',
  options: [
    AssessmentOption(id: 'career', label: 'Job interviews & career', emoji: '\u{1F4BC}'),
    AssessmentOption(id: 'social', label: 'Social confidence', emoji: '\u{1F91D}'),
    AssessmentOption(id: 'speaking', label: 'Presentations & public speaking', emoji: '\u{1F3A4}'),
    AssessmentOption(id: 'conflict', label: 'Standing up for myself', emoji: '\u{1F525}'),
  ],
);

// Q2 — adaptive per goal
const _q2Career = AssessmentQuestion(
  id: 'sub_goal',
  text: 'Tell me more about your situation:',
  options: [
    AssessmentOption(id: 'entry', label: "I'm new to the job market", emoji: '\u{1F331}'),
    AssessmentOption(id: 'experienced', label: 'Experienced, want to sharpen', emoji: '\u{1F4C8}'),
    AssessmentOption(id: 'nervous', label: 'I get very nervous in interviews', emoji: '\u{1F630}'),
    AssessmentOption(id: 'switch', label: 'Switching careers or industries', emoji: '\u{1F504}'),
  ],
);

const _q2Social = AssessmentQuestion(
  id: 'sub_goal',
  text: 'What feels hardest for you?',
  options: [
    AssessmentOption(id: 'strangers', label: 'Meeting new people', emoji: '\u{1F44B}'),
    AssessmentOption(id: 'groups', label: 'Large groups and parties', emoji: '\u{1F389}'),
    AssessmentOption(id: 'dating', label: 'Dating & romantic connections', emoji: '\u{2764}'),
    AssessmentOption(id: 'deepen', label: 'Deepening friendships', emoji: '\u{1F91D}'),
  ],
);

const _q2Speaking = AssessmentQuestion(
  id: 'sub_goal',
  text: 'What kind of speaking?',
  options: [
    AssessmentOption(id: 'work', label: 'Work or school presentations', emoji: '\u{1F4CA}'),
    AssessmentOption(id: 'events', label: 'Public events or conferences', emoji: '\u{1F3A4}'),
    AssessmentOption(id: 'lead', label: 'Leading meetings', emoji: '\u{1F4CB}'),
    AssessmentOption(id: 'big_crowd', label: 'Speaking to a large crowd', emoji: '\u{1F3DF}'),
  ],
);

const _q2Conflict = AssessmentQuestion(
  id: 'sub_goal',
  text: 'Where do you need it most?',
  options: [
    AssessmentOption(id: 'boss', label: 'With my boss or manager', emoji: '\u{1F454}'),
    AssessmentOption(id: 'coworker', label: 'With coworkers or teammates', emoji: '\u{1F465}'),
    AssessmentOption(id: 'personal', label: 'With friends or family', emoji: '\u{2764}'),
    AssessmentOption(id: 'strangers', label: 'With strangers or services', emoji: '\u{1F30D}'),
  ],
);

// Q3 — adaptive per goal
const _q3Career = AssessmentQuestion(
  id: 'challenge',
  text: "What's your biggest block in interviews?",
  options: [
    AssessmentOption(id: 'anxiety', label: 'I freeze up and go blank', emoji: '\u{1F630}'),
    AssessmentOption(id: 'ramble', label: 'I ramble and lose my point', emoji: '\u{1F9E9}'),
    AssessmentOption(id: 'confidence', label: 'I undersell myself', emoji: '\u{1F4AA}'),
    AssessmentOption(id: 'tough', label: 'Tough questions (salary, weaknesses)', emoji: '\u{1F525}'),
  ],
);

const _q3Social = AssessmentQuestion(
  id: 'challenge',
  text: 'What holds you back most?',
  options: [
    AssessmentOption(id: 'anxiety', label: 'Strong social anxiety', emoji: '\u{1F630}'),
    AssessmentOption(id: 'blank', label: 'I go blank mid-conversation', emoji: '\u{1F9E9}'),
    AssessmentOption(id: 'fear', label: 'Fear of rejection', emoji: '\u{1F494}'),
    AssessmentOption(id: 'boring', label: 'I worry I seem boring', emoji: '\u{1F614}'),
  ],
);

const _q3Speaking = AssessmentQuestion(
  id: 'challenge',
  text: "What's your biggest challenge?",
  options: [
    AssessmentOption(id: 'anxiety', label: 'I panic on stage', emoji: '\u{1F630}'),
    AssessmentOption(id: 'structure', label: 'I lose my train of thought', emoji: '\u{1F9E9}'),
    AssessmentOption(id: 'filler', label: "I say um/uh constantly", emoji: '\u{1F910}'),
    AssessmentOption(id: 'flat', label: 'My delivery feels flat', emoji: '\u{1F4C9}'),
  ],
);

const _q3Conflict = AssessmentQuestion(
  id: 'challenge',
  text: "What's hardest for you?",
  options: [
    AssessmentOption(id: 'avoidance', label: 'I avoid the conversation entirely', emoji: '\u{1F6AB}'),
    AssessmentOption(id: 'emotional', label: 'I get too emotional', emoji: '\u{1F62D}'),
    AssessmentOption(id: 'freeze', label: "I freeze and can't respond", emoji: '\u{2744}'),
    AssessmentOption(id: 'assertive', label: "I don't know how to stay firm", emoji: '\u{1F4AA}'),
  ],
);

// Q4 — universal: urgency
const _q4 = AssessmentQuestion(
  id: 'event_date',
  text: 'When do you need to be ready?',
  options: [
    AssessmentOption(id: 'this_week', label: 'This week', emoji: '\u{1F525}'),
    AssessmentOption(id: 'this_month', label: 'This month', emoji: '\u{1F4C5}'),
    AssessmentOption(id: 'two_months', label: 'In 2+ months', emoji: '\u{1F5D3}'),
    AssessmentOption(id: 'no_date', label: 'No rush — just improving', emoji: '\u{1F3AF}'),
  ],
);

List<AssessmentQuestion> getAdaptiveQuestions(String? goal) {
  final AssessmentQuestion q2;
  final AssessmentQuestion q3;

  switch (goal) {
    case 'career':
      q2 = _q2Career;
      q3 = _q3Career;
    case 'social':
      q2 = _q2Social;
      q3 = _q3Social;
    case 'speaking':
      q2 = _q2Speaking;
      q3 = _q3Speaking;
    case 'conflict':
      q2 = _q2Conflict;
      q3 = _q3Conflict;
    default:
      q2 = _q2Career;
      q3 = _q3Career;
  }

  return [_q1, q2, q3, _q4];
}

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
      _ChainStep(scenarioId: 'stage_1', difficulty: 'easy', minPassScore: 60), // elevator pitch for networking
      _ChainStep(scenarioId: 'int_2', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'int_8', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'int_9', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'int_10', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_5', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_11', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_12', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'stage_5', difficulty: 'medium', minPassScore: 70), // present results to manager
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
  final a = {for (final x in answers) x.questionId: x.optionId};
  final goal = a['goal'];
  final subGoal = a['sub_goal'];
  final challenge = a['challenge'];

  // Anxiety override — any path
  if (challenge == 'anxiety') return 'anxiety_buster';

  switch (goal) {
    case 'career':
      // Very nervous in interviews → anxiety track first
      if (subGoal == 'nervous') return 'anxiety_buster';
      // New to job market → gen z work fundamentals first
      if (subGoal == 'entry') return 'gen_z_work';
      return 'career_confidence';

    case 'social':
      return 'social_butterfly';

    case 'speaking':
      return 'stage_ready';

    case 'conflict':
      return 'tough_conversations';

    default:
      return 'social_butterfly';
  }
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
