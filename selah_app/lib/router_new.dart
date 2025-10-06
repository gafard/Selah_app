import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../views/splash_page.dart';
import '../views/welcome_page.dart';
import '../views/auth_page.dart';
import '../views/complete_profile_page.dart';
import '../views/choose_plan_page.dart';
import '../views/onboarding_dynamic_page.dart';
import '../views/congrats_page.dart';
import '../views/home_page.dart';

class AppRouter {
  static final _supabase = Supabase.instance.client;
  static final _userRepo = UserRepository();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = _supabase.auth.currentUser;
      
      // Toujours permettre l'accès à splash
      if (state.uri.path == '/splash') return null;

      // Si pas d'utilisateur connecté
      if (user == null) {
        if (state.uri.path == '/welcome' || state.uri.path == '/auth') {
          return null;
        }
        return '/welcome';
      }

      // Utilisateur connecté - vérifier le profil
      try {
        final profile = await _userRepo.getCurrentUser();
        if (profile == null) {
          // Profil non trouvé, rediriger vers auth
          return '/auth';
        }

        // Vérifier si le profil est complet
        if (!profile.isComplete) {
          if (state.uri.path == '/complete-profile') return null;
          return '/complete-profile';
        }

        // Vérifier si l'utilisateur a un plan
        if (profile.currentPlanId == null) {
          if (state.uri.path == '/choose-plan') return null;
          return '/choose-plan';
        }

        // Vérifier si l'utilisateur a terminé l'onboarding
        if (!profile.hasOnboarded) {
          if (state.uri.path == '/onboarding') return null;
          return '/onboarding';
        }

        // Tout est OK - rediriger vers home si sur welcome/auth
        if (state.uri.path == '/welcome' || state.uri.path == '/auth') {
          return '/home';
        }

        return null;
      } catch (e) {
        print('Error in router redirect: $e');
        return '/welcome';
      }
    },
    routes: [
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
    ],
  );
}
