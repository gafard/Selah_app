import 'package:go_router/go_router.dart';
import '../views/simple_home_page.dart';
import '../views/test_navigation_page.dart';
import '../views/splash_page.dart';
import '../views/welcome_page.dart';
import '../views/auth_page.dart';
import '../views/complete_profile_page.dart';
import '../views/choose_plan_page.dart';
import '../views/onboarding_dynamic_page.dart';
import '../views/congrats_page.dart';
import '../views/home_page.dart';
import '../views/goals_page.dart';
import '../views/import_plan_page.dart';
import '../views/custom_plan_generator_page.dart';
import '../views/coming_soon_page.dart';
import '../views/bible_quiz_page.dart';
import '../views/pre_meditation_prayer_page.dart';
import '../views/reader_page_modern.dart';
import '../models/reading_config.dart';
import '../views/meditation_chooser_page.dart';
import '../views/meditation_free_page.dart';
import '../views/meditation_qcm_page.dart';
import '../views/meditation_auto_qcm_page.dart';
import '../views/prayer_carousel_page.dart';
import '../views/verse_poster_page.dart';
import '../views/gratitude_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePageWidget(),
      ),
      GoRoute(
        path: '/test',
        builder: (context, state) => const TestNavigationPage(),
      ),
      GoRoute(
        path: '/simple-home',
        builder: (context, state) => const SimpleHomePage(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/choose-plan',
        builder: (context, state) => const ChoosePlanPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingDynamicPage(),
      ),
      GoRoute(
        path: '/congrats',
        builder: (context, state) => const CongratsPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePageWidget(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: '/import_plan',
        builder: (context, state) => const ImportPlanPage(),
      ),
      GoRoute(
        path: '/custom_plan_generator',
        builder: (context, state) => const CustomPlanGeneratorPage(),
      ),
      GoRoute(
        path: '/coming_soon',
        builder: (context, state) => const ComingSoonPage(),
      ),
      GoRoute(
        path: '/bible_quiz',
        builder: (context, state) => const BibleQuizPage(),
      ),
      GoRoute(
        path: '/pre_meditation_prayer',
        builder: (context, state) => const PreMeditationPrayerPage(),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final config = state.extra as ReadingConfig?;
          return ReaderPageModern(config: config);
        },
      ),
      GoRoute(
        path: '/meditation/choose',
        builder: (context, state) {
          final config = state.extra as ReadingConfig?;
          return MeditationChooserPage();
        },
      ),
      GoRoute(
        path: '/meditation/free',
        builder: (context, state) {
          final args = state.extra as Map?;
          return MeditationFreePage(
            passageRef: args?['passageRef'] as String? ?? 'Jean 3:16',
            passageText: args?['passageText'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/meditation/qcm',
        builder: (context, state) {
          final args = state.extra as Map?;
          return MeditationQcmPage(
            passageRef: args?['passageRef'] as String?,
            passageText: args?['passageText'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/meditation/auto_qcm',
        builder: (context, state) => const MeditationAutoQcmPage(),
      ),
      GoRoute(
        path: '/prayer_carousel',
        builder: (context, state) {
          final args = state.extra as Map?;
          return PrayerCarouselPage();
        },
      ),
      GoRoute(
        path: '/verse_poster',
        builder: (context, state) {
          final args = state.extra as Map?;
          return VersePosterPage();
        },
      ),
      GoRoute(
        path: '/gratitude',
        builder: (context, state) => const GratitudePage(),
      ),
    ],
  );
}
