import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/progress_bar.dart';
import '../../data/assessment_data.dart';
import '../../domain/assessment_entity.dart';
import '../providers/assessment_provider.dart';
import '../widgets/question_card.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final Map<String, String> _answers = {};
  bool _isGenerating = false;

  List<AssessmentQuestion> get _questions => getAdaptiveQuestions(_answers['goal']);

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString('onboarding_event_date');
    if (saved != null) {
      _answers['event_date'] = saved;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _generatePlan() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    final answers = _answers.entries
        .map((e) => AssessmentAnswer(questionId: e.key, optionId: e.value))
        .toList();

    try {
      await ref
          .read(learningPlanProvider.notifier)
          .generateFromAssessment(answers)
          .timeout(const Duration(seconds: 10));

      if (mounted) context.go('/plan-summary');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('TimeoutException')
                ? 'Taking longer than expected. Please check your connection and try again.'
                : 'Something went wrong. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final isLastPage = _currentPage == questions.length - 1;
    final currentQuestion = questions[_currentPage];
    final hasAnswer = _answers.containsKey(currentQuestion.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back + progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 24,
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ProgressBar(
                      value: (_currentPage + 1) / questions.length,
                      height: 10,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentPage + 1}/${questions.length}',
                    style: AppTypography.labelMedium(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return QuestionCard(
                    question: question,
                    selectedOptionId: _answers[question.id],
                    onSelect: (optionId) {
                      isLastPage
                          ? HapticFeedback.mediumImpact()
                          : HapticFeedback.selectionClick();
                      setState(() {
                        // Changing goal clears downstream adaptive answers
                        if (question.id == 'goal' && _answers['goal'] != optionId) {
                          _answers.remove('sub_goal');
                          _answers.remove('challenge');
                        }
                        _answers[question.id] = optionId;
                      });
                      if (!isLastPage) {
                        Future.delayed(const Duration(milliseconds: 400), () {
                          if (mounted) _nextPage();
                        });
                      }
                    },
                  );
                },
              ),
            ),

            // Bottom CTA (last page only)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: isLastPage && hasAnswer
                  ? DuoButton(
                      text: _isGenerating ? 'Building your plan...' : 'Get My Plan',
                      icon: _isGenerating ? null : Icons.auto_awesome_rounded,
                      width: double.infinity,
                      color: AppColors.success,
                      shadowColor: const Color(0xFF44A302),
                      disabled: _isGenerating,
                      onTap: _isGenerating ? null : _generatePlan,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1)
                  : const SizedBox(height: 52),
            ),
          ],
        ),
      ),
    );
  }
}
