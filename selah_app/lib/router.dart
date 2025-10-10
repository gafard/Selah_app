// lib/router.dart - Router Unifié avec GoRouter et Guards Auth
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:selah_app/views/welcome_page.dart';
import 'package:selah_app/views/auth_page.dart';
import 'package:selah_app/views/goals_page.dart';
import 'package:selah_app/views/success_page.dart';
import 'package:selah_app/views/home_page.dart';
import 'package:selah_app/views/complete_profile_page.dart';
import 'package:selah_app/views/custom_plan_generator_page.dart';
import 'package:selah_app/views/journal_page.dart';
import 'package:selah_app/views/settings_page.dart';
import 'package:selah_app/views/profile_settings_page.dart';
import 'package:selah_app/views/reader_page_modern.dart';
import 'package:selah_app/views/reader_settings_page.dart';
import 'package:selah_app/views/meditation_chooser_page.dart';
import 'package:selah_app/views/meditation_free_page.dart';
import 'package:selah_app/views/meditation_qcm_page.dart';
import 'package:selah_app/views/meditation_auto_qcm_page.dart';
import 'package:selah_app/views/prayer_subjects_page.dart';
import 'package:selah_app/views/prayer_carousel_page.dart';
import 'package:selah_app/views/verse_poster_page.dart';
import 'package:selah_app/views/spiritual_wall_page.dart';
import 'package:selah_app/views/gratitude_page.dart';
import 'package:selah_app/views/coming_soon_page.dart';
import 'package:selah_app/views/bible_quiz_page.dart';
import 'package:selah_app/views/scan_bible_page.dart';
import 'package:selah_app/views/advanced_scan_bible_page.dart';
import 'package:selah_app/views/profile_page.dart';
import 'package:selah_app/views/splash_page.dart';
import 'package:selah_app/views/pre_meditation_prayer_page.dart';
import 'package:selah_app/views/onboarding_dynamic_page.dart';
import 'package:selah_app/views/congrats_discipline_page.dart';
import 'package:selah_app/repositories/user_repository.dart';

class AppRouter {
  static final _userRepo = UserRepository();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    
    // ═══════════════════════════════════════════════════════════════════
    // REDIRECT LOGIC - Guards d'authentification (OFFLINE-FIRST)
    // ═══════════════════════════════════════════════════════════════════
    redirect: (context, state) async {
      final path = state.uri.path;
      
      // Toujours permettre l'accès à splash et welcome
      if (path == '/splash' || path == '/welcome') return null;
      
      // ─────────────────────────────────────────────────────────────────
      // GUARD 1: Vérifier authentification (LOCAL d'abord)
      // ─────────────────────────────────────────────────────────────────
      final isAuth = _userRepo.isAuthenticated();
      
      if (!isAuth) {
        // Pas authentifié → welcome ou auth
        if (path == '/auth') return null;
        return '/welcome';
      }
      
      // ─────────────────────────────────────────────────────────────────
      // GUARD 2: Vérifier profil utilisateur (LOCAL d'abord)
      // ─────────────────────────────────────────────────────────────────
      try {
        final user = await _userRepo.getCurrentUser();
        
        if (user == null) {
          // User null malgré isAuth → problème, retour auth
          return '/auth';
        }
        
        // ─────────────────────────────────────────────────────────────
        // GUARD 3: Vérifier profil complet
        // ─────────────────────────────────────────────────────────────
        if (!user.isComplete) {
          if (path == '/complete_profile') return null;
          return '/complete_profile';
        }
        
        // ─────────────────────────────────────────────────────────────
        // GUARD 4: Vérifier onboarding (AVANT le plan)
        // ─────────────────────────────────────────────────────────────
        print('🧭 Router Guard: hasOnboarded=${user.hasOnboarded}, path=$path');
        if (!user.hasOnboarded) {
          // Autoriser explicitement onboarding et l'écran de succès
          if (path == '/onboarding' || path == '/congrats') {
            print('🧭 Router Guard: Autorisation /onboarding ou /congrats');
            return null;
          }
          print('🧭 Router Guard: Redirection vers /onboarding');
          return '/onboarding';
        }
        
        // ─────────────────────────────────────────────────────────────
        // GUARD 5: Vérifier plan actif (APRÈS onboarding)
        // ─────────────────────────────────────────────────────────────
        print('🧭 Router Guard: currentPlanId=${user.currentPlanId}, path=$path');
        if (user.currentPlanId == null) {
          // Permettre l'accès à complete_profile, goals et custom_plan
          if (path == '/goals' || path == '/custom_plan' || path == '/complete_profile') {
            print('🧭 Router Guard: Autorisation pages de création (pas de plan)');
            return null;
          }
          print('🧭 Router Guard: Redirection vers /goals (pas de plan)');
          return '/goals';
        } else {
          // 🔒 GUARD 5B: Si plan existe, BLOQUER l'accès aux pages de création
          if (path == '/goals' || path == '/custom_plan') {
            print('🧭 Router Guard: Redirection vers /settings (plan existe)');
            // Rediriger vers settings pour gérer le plan existant
            return '/settings';
          }
        }
        
        // ─────────────────────────────────────────────────────────────
        // Tout est OK - rediriger vers home si sur pages auth
        // ─────────────────────────────────────────────────────────────
        if (path == '/auth' || path == '/welcome') {
          return '/home';
        }
        
        return null;
      } catch (e) {
        print('⚠️ Error in router redirect: $e');
        // En cas d'erreur, laisser passer (mode dégradé)
        return null;
      }
    },
    
    // ═══════════════════════════════════════════════════════════════════
    // ROUTES - 51 routes complètes
    // ═══════════════════════════════════════════════════════════════════
    routes: [
      // ─────────────────────────────────────────────────────────────────
      // Splash & Authentification (PUBLIC)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AuthPage(initialMode: extra?['mode'] as String?);
        },
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Onboarding & Setup (PROTECTED - Guards appliqués)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/complete_profile',
        name: 'complete_profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingDynamicPage(),
      ),
      GoRoute(
        path: '/congrats',
        name: 'congrats',
        builder: (context, state) => const CongratsDisciplinePage(),
      ),
      GoRoute(
        path: '/custom_plan',
        name: 'custom_plan',
        builder: (context, state) => const CustomPlanGeneratorPage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Pages principales (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePageWidget(),
      ),
      GoRoute(
        path: '/pre_meditation_prayer',
        name: 'pre_meditation_prayer',
        builder: (context, state) => const PreMeditationPrayerPage(),
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) => const ReaderPageModern(),
      ),
      GoRoute(
        path: '/reader_settings',
        name: 'reader_settings',
        builder: (context, state) => const ReaderSettingsPage(),
      ),
      GoRoute(
        path: '/journal',
        name: 'journal',
        builder: (context, state) => const JournalPage(),
      ),
      GoRoute(
        path: '/bible_videos',
        name: 'bible_videos',
        builder: (context, state) => const ComingSoonPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/profile_settings',
        name: 'profile_settings',
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Méditation (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/meditation/chooser',
        name: 'meditation_chooser',
        builder: (context, state) => const MeditationChooserPage(),
      ),
      GoRoute(
        path: '/meditation/free',
        name: 'meditation_free',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return MeditationFreePage(
            passageRef: args?['passageRef'] as String?,
            passageText: args?['passageText'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/meditation/qcm',
        name: 'meditation_qcm',
        builder: (context, state) => const MeditationQcmPage(),
      ),
      GoRoute(
        path: '/meditation/auto_qcm',
        name: 'meditation_auto_qcm',
        builder: (context, state) => const MeditationAutoQcmPage(),
      ),
      GoRoute(
        path: '/prayer_subjects',
        name: 'prayer_subjects',
        builder: (context, state) => const PrayerSubjectsPage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Prière (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/prayer_generator',
        name: 'prayer_generator',
        builder: (context, state) => const ComingSoonPage(),
      ),
      GoRoute(
        path: '/payerpage',
        name: 'payerpage',
        builder: (context, state) => const PrayerCarouselPage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Scan Bible (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/scan/bible',
        name: 'scan_bible',
        builder: (context, state) => const ScanBiblePage(),
      ),
      GoRoute(
        path: '/scan/bible/advanced',
        name: 'scan_bible_advanced',
        builder: (context, state) => const AdvancedScanBiblePage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Profil (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Fonctionnalités créatives (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/verse_poster',
        name: 'verse_poster',
        builder: (context, state) => const VersePosterPage(),
      ),
      GoRoute(
        path: '/spiritual_wall',
        name: 'spiritual_wall',
        builder: (context, state) => const SpiritualWallPage(),
      ),
      GoRoute(
        path: '/gratitude',
        name: 'gratitude',
        builder: (context, state) => const GratitudePage(),
      ),
      GoRoute(
        path: '/bible_quiz',
        name: 'bible_quiz',
        builder: (context, state) => const BibleQuizPage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Coming Soon (PROTECTED)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/community/new-post',
        name: 'community_new_post',
        builder: (context, state) => const ComingSoonPage(),
      ),
      GoRoute(
        path: '/coming_soon',
        name: 'coming_soon',
        builder: (context, state) => const ComingSoonPage(),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // Pages de succès (PUBLIC - Accessibles sans guards stricts)
      // ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/success',
        name: 'success',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
      return SuccessPage(
        title: args?['title'] ?? 'Succès',
        message: args?['message'] ?? 'Opération réussie',
        buttonText: args?['buttonText'],
        nextRoute: args?['nextRoute'],
      );
    },
      ),
      GoRoute(
        path: '/success/registration',
        name: 'success_registration',
        builder: (context, state) => const SuccessPage(
      title: 'Inscription réussie',
      message: 'Votre compte a été créé avec succès !',
      nextRoute: '/home',
    ),
      ),
      GoRoute(
        path: '/success/login',
        name: 'success_login',
        builder: (context, state) => const SuccessPage(
      title: 'Connexion réussie',
      message: 'Bienvenue dans votre espace personnel !',
      nextRoute: '/home',
    ),
      ),
      GoRoute(
        path: '/success/plan_created',
        name: 'success_plan_created',
        builder: (context, state) => const SuccessPage(
      title: 'Plan créé',
      message: 'Votre plan de lecture a été créé avec succès !',
      nextRoute: '/home',
    ),
      ),
      GoRoute(
        path: '/success/analysis',
        name: 'success_analysis',
        builder: (context, state) => const SuccessPage(
      title: 'Analyse terminée',
      message: 'Votre analyse a été complétée avec succès !',
      nextRoute: '/home',
    ),
      ),
      GoRoute(
        path: '/success/save',
        name: 'success_save',
        builder: (context, state) => const SuccessPage(
      title: 'Sauvegarde réussie',
      message: 'Vos données ont été sauvegardées !',
      nextRoute: '/home',
    ),
      ),
    ],
  );
}