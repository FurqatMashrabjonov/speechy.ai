import '../domain/assessment_entity.dart';
import '../domain/learning_plan_entity.dart';

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
      _ChainStep(scenarioId: 'soc_5', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'soc_4', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'soc_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'conv_1', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'date_4', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'date_5', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'soc_3', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'date_1', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'soc_2', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'date_2', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conv_2', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'date_3', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conf_4', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conv_3', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'conv_5', difficulty: 'hard', minPassScore: 75),
    ],
  ),
  _ChainTemplate(
    id: 'stage_ready',
    title: 'Public Speaking',
    description:
        'Go from nervous speaker to commanding any stage with confidence.',
    steps: [
      _ChainStep(scenarioId: 'pres_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'story_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'story_2', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'pub_2', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'pub_1', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'story_4', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'pres_3', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'deb_1', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'deb_2', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'pres_2', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'story_5', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'deb_3', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'pub_3', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'pres_5', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'pub_4', difficulty: 'hard', minPassScore: 80),
    ],
  ),
  _ChainTemplate(
    id: 'anxiety_buster',
    title: 'Anxiety Buster',
    description:
        'Gentle progressive practice — start low-pressure, build to real confidence.',
    steps: [
      _ChainStep(scenarioId: 'phone_4', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'phone_1', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'soc_5', difficulty: 'easy', minPassScore: 50),
      _ChainStep(scenarioId: 'phone_2', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'soc_4', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'phone_3', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'phone_5', difficulty: 'medium', minPassScore: 60),
      _ChainStep(scenarioId: 'conv_1', difficulty: 'medium', minPassScore: 60),
      _ChainStep(scenarioId: 'story_1', difficulty: 'medium', minPassScore: 60),
      _ChainStep(scenarioId: 'conf_5', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'soc_3', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'conf_2', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'conf_3', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conf_4', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conf_1', difficulty: 'hard', minPassScore: 70),
    ],
  ),
  _ChainTemplate(
    id: 'well_rounded',
    title: 'Well-Rounded Speaker',
    description:
        'A balanced path across all speaking situations — social, professional, and public.',
    steps: [
      _ChainStep(scenarioId: 'soc_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'story_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'phone_1', difficulty: 'easy', minPassScore: 55),
      _ChainStep(scenarioId: 'int_1', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'pres_1', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'conv_1', difficulty: 'easy', minPassScore: 60),
      _ChainStep(scenarioId: 'date_1', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'conf_5', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'deb_1', difficulty: 'medium', minPassScore: 65),
      _ChainStep(scenarioId: 'pub_1', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'conf_1', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_5', difficulty: 'medium', minPassScore: 70),
      _ChainStep(scenarioId: 'int_4', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'pres_5', difficulty: 'hard', minPassScore: 75),
      _ChainStep(scenarioId: 'pub_4', difficulty: 'hard', minPassScore: 75),
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

  // Priority 2: Goal-based
  switch (answerMap['goal']) {
    case 'career':
      return 'career_confidence';
    case 'social':
    case 'dating':
      return 'social_butterfly';
    case 'public':
      return 'stage_ready';
  }

  return 'well_rounded';
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
