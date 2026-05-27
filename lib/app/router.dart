import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/auth/presentation/screens/login_screen.dart';
import 'package:speech_coach/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:speech_coach/features/auth/presentation/screens/splash_screen.dart';
import 'package:speech_coach/features/conversation/presentation/screens/conversation_screen.dart';
import 'package:speech_coach/features/feedback/presentation/screens/score_card_screen.dart';
import 'package:speech_coach/features/history/presentation/screens/session_detail_screen.dart';
import 'package:speech_coach/features/history/presentation/screens/session_history_screen.dart';
import 'package:speech_coach/features/home/presentation/screens/home_screen.dart';
import 'package:speech_coach/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:speech_coach/features/profile/presentation/screens/profile_screen.dart';
import 'package:speech_coach/features/profile/presentation/screens/settings_screen.dart';
import 'package:speech_coach/features/progress/presentation/screens/analytics_screen.dart';
import 'package:speech_coach/features/scenarios/presentation/screens/scenario_detail_screen.dart';
import 'package:speech_coach/features/scenarios/presentation/screens/practice_screen.dart';
import 'package:speech_coach/features/scenarios/presentation/screens/scenario_list_screen.dart';
import 'package:speech_coach/features/session/presentation/screens/feedback_screen.dart';
import 'package:speech_coach/features/session/presentation/screens/recording_screen.dart';
import 'package:speech_coach/features/session/presentation/screens/session_setup_screen.dart';
import 'package:speech_coach/features/assessment/presentation/screens/assessment_screen.dart';
import 'package:speech_coach/features/assessment/presentation/screens/plan_summary_screen.dart';
import 'package:speech_coach/features/assessment/presentation/screens/roadmap_catalog_screen.dart';
import 'package:speech_coach/features/assessment/presentation/screens/track_detail_screen.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/shared/widgets/bottom_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
    redirect: (context, state) {
      final isLoggedIn = authState.whenOrNull(data: (user) => user != null) ?? false;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/splash';

      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') {
        return '/home';
      }

      // Redirect to assessment if not completed (skip for assessment/plan-summary/splash/auth routes)
      final isAssessmentRoute = state.matchedLocation == '/assessment' ||
          state.matchedLocation == '/plan-summary';
      if (isLoggedIn && !isAuthRoute && !isAssessmentRoute) {
        final hasAssessment = ref.read(hasAssessmentProvider);
        if (!hasAssessment) {
          return '/assessment';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/assessment',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AssessmentScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/plan-summary',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PlanSummaryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/practice',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PracticeScreen(),
            ),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/tracks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RoadmapCatalogScreen(),
            ),
          ),
          GoRoute(
            path: '/tracks/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomTransitionPage(
                child: TrackDetailScreen(trackId: id),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      // Scenario routes
      GoRoute(
        path: '/scenarios/:category',
        pageBuilder: (context, state) {
          final category = Uri.decodeComponent(
            state.pathParameters['category']!,
          );
          return CustomTransitionPage(
            child: ScenarioListScreen(category: category),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/scenario/:scenarioId',
        pageBuilder: (context, state) {
          final scenarioId = Uri.decodeComponent(
            state.pathParameters['scenarioId']!,
          );
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            child: ScenarioDetailScreen(
              scenarioId: scenarioId,
              trackId: extra?['trackId'] as String?,
              stepOrder: extra?['stepOrder'] as int?,
              focusPriority: extra?['focusPriority'] as String?,
              focusChallenge: extra?['focusChallenge'] as String?,
              previousScore: extra?['previousScore'] as int?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      // Score card
      GoRoute(
        path: '/score-card',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: ScoreCardScreen(
              sessionId: extra['sessionId'] as String?,
              scenarioId: extra['scenarioId'] as String,
              scenarioTitle: extra['scenarioTitle'] as String,
              category: extra['category'] as String,
              transcript: extra['transcript'] as String? ?? '',
              previousScore: extra['previousScore'] as int?,
              scenarioPrompt: extra['scenarioPrompt'] as String? ?? '',
              durationSeconds: extra['durationSeconds'] as int? ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      // Paywall
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final trackId = extra?['trackId'] as String? ?? '';
          final trackTitle = extra?['trackTitle'] as String? ?? 'This Track';
          return CustomTransitionPage(
          child: PaywallScreen(trackId: trackId, trackTitle: trackTitle),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          );
        },
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SessionHistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/history/:sessionId',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return CustomTransitionPage(
            child: SessionDetailScreen(sessionId: sessionId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      // Existing session routes
      GoRoute(
        path: '/session/setup/:category',
        pageBuilder: (context, state) {
          final category = Uri.decodeComponent(
            state.pathParameters['category']!,
          );
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            child: SessionSetupScreen(
              category: category,
              challengePrompt: extra?['prompt'] as String?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/session/record',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: RecordingScreen(
              category: extra['category'] as String,
              prompt: extra['prompt'] as String,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/session/feedback',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: FeedbackScreen(
              category: extra['category'] as String,
              prompt: extra['prompt'] as String,
              audioPath: extra['audioPath'] as String,
              durationSeconds: extra['duration'] as int,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      // Conversation (with optional scenario params)
      GoRoute(
        path: '/conversation/:category',
        pageBuilder: (context, state) {
          final category = Uri.decodeComponent(
            state.pathParameters['category']!,
          );
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            child: ConversationScreen(
              category: category,
              scenarioId: extra?['scenarioId'] as String?,
              scenarioTitle: extra?['scenarioTitle'] as String?,
              scenarioPrompt: extra?['scenarioPrompt'] as String?,
              durationMinutes: extra?['durationMinutes'] as int?,
              userRole: extra?['userRole'] as String?,
              focusPriority: extra?['focusPriority'] as String?,
              focusChallenge: extra?['focusChallenge'] as String?,
              previousScore: extra?['previousScore'] as int?,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
    ],
  );
});

class _ShellScreen extends StatelessWidget {
  final Widget child;

  const _ShellScreen({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _calculateIndex(context),
        onTap: (index) {
          // Dismiss any open bottom sheet or dialog before switching tabs
          Navigator.of(context).popUntil((route) => route.isFirst);
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/tracks');
            case 2:
              context.go('/profile');
          }
        },
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/tracks')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
}
