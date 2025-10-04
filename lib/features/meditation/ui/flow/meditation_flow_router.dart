import 'package:go_router/go_router.dart';
import 'step_intro_page.dart';
import 'step_question_mcq_page.dart';
import 'step_free_input_page.dart';
import 'step_checklist_review_page.dart';
import 'step_summary_done_page.dart';

/// Configuration des routes pour le flow de méditation
class MeditationFlowRouter {
  static const String basePath = '/meditation';
  static const String startPath = '$basePath/start';
  
  static List<RouteBase> get routes => [
    GoRoute(
      path: startPath,
      name: 'meditation-start',
      builder: (context, state) {
        final planId = state.uri.queryParameters['planId'] ?? 'demo-plan';
        final day = int.tryParse(state.uri.queryParameters['day'] ?? '1') ?? 1;
        final ref = state.uri.queryParameters['ref'] ?? 'Jean 3:16';
        
        return StepIntroPage(
          planId: planId,
          dayNumber: day,
          passageRef: ref,
        );
      },
      routes: [
        GoRoute(
          path: 'mcq',
          name: 'meditation-mcq',
          builder: (context, state) {
            final planId = state.uri.queryParameters['planId'] ?? 'demo-plan';
            final day = int.tryParse(state.uri.queryParameters['day'] ?? '1') ?? 1;
            final ref = state.uri.queryParameters['ref'] ?? 'Jean 3:16';
            
            return StepQuestionMcqPage(
              planId: planId,
              dayNumber: day,
              passageRef: ref,
            );
          },
        ),
        GoRoute(
          path: 'free',
          name: 'meditation-free',
          builder: (context, state) {
            final planId = state.uri.queryParameters['planId'] ?? 'demo-plan';
            final day = int.tryParse(state.uri.queryParameters['day'] ?? '1') ?? 1;
            final ref = state.uri.queryParameters['ref'] ?? 'Jean 3:16';
            
            return StepFreeInputPage(
              planId: planId,
              dayNumber: day,
              passageRef: ref,
            );
          },
        ),
        GoRoute(
          path: 'checklist',
          name: 'meditation-checklist',
          builder: (context, state) {
            final planId = state.uri.queryParameters['planId'] ?? 'demo-plan';
            final day = int.tryParse(state.uri.queryParameters['day'] ?? '1') ?? 1;
            final ref = state.uri.queryParameters['ref'] ?? 'Jean 3:16';
            
            return StepChecklistReviewPage(
              planId: planId,
              dayNumber: day,
              passageRef: ref,
            );
          },
        ),
        GoRoute(
          path: 'summary',
          name: 'meditation-summary',
          builder: (context, state) {
            final planId = state.uri.queryParameters['planId'] ?? 'demo-plan';
            final day = int.tryParse(state.uri.queryParameters['day'] ?? '1') ?? 1;
            final ref = state.uri.queryParameters['ref'] ?? 'Jean 3:16';
            
            return StepSummaryDonePage(
              planId: planId,
              dayNumber: day,
              passageRef: ref,
            );
          },
        ),
      ],
    ),
  ];
}
