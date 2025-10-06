// lib/router.dart
import 'package:flutter/material.dart';
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
// // import 'package:selah_app/views/test_navigation_page.dart'; // Fichier supprimé // Fichier supprimé
import 'package:selah_app/views/onboarding_dynamic_page.dart';
import 'package:selah_app/views/congrats_discipline_page.dart';

class AppRouter {
  static final routes = <String, Widget Function(BuildContext)>{
    // Page de test (supprimée)
    // '/test': (context) => // const TestNavigationPage() // Fichier supprimé,
    
    // Authentification
    '/welcome': (context) => const WelcomePage(),
    '/auth': (context) => const AuthPage(),
    '/onboarding': (context) => const OnboardingDynamicPage(),
    '/congrats': (context) => const CongratsDisciplinePage(),
    '/complete_profile': (context) => const CompleteProfilePage(),
    
    // Plans
    '/goals': (context) => const GoalsPage(),
    '/custom_plan': (context) => const CustomPlanGeneratorPage(),
    
    // Pages principales
    '/home': (context) => const HomePageWidget(),
    '/pre_meditation_prayer': (context) => const PreMeditationPrayerPage(),
    '/reader': (context) => const ReaderPageModern(),
    '/reader_modern': (context) => const ReaderPageModern(),
    '/reader_settings': (context) => const ReaderSettingsPage(),
    '/journal': (context) => const JournalPage(),
    '/bible_videos': (context) => const ComingSoonPage(),
    '/settings': (context) => const SettingsPage(),
    '/profile_settings': (context) => const ProfileSettingsPage(),
    
    // Méditation
    '/meditation/chooser': (context) => const MeditationChooserPage(),
    '/meditation/free': (context) => const MeditationFreePage(
      passageRef: 'Jean 3:16',
      passageText: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
    ),
    '/meditation/qcm': (context) => const MeditationQcmPage(),
    '/meditation/auto_qcm': (context) => const MeditationAutoQcmPage(),
    '/prayer_subjects': (context) => const PrayerSubjectsPage(),
    
    // Prière
    '/prayer_generator': (context) => const ComingSoonPage(),
    
    // Scan Bible
    '/scan/bible': (context) => const ScanBiblePage(),
    '/scan/bible/advanced': (context) => const AdvancedScanBiblePage(),
    
    // Profil
    '/profile': (context) => const ProfilePage(),
    
    // Splash
    '/splash': (context) => const SplashPage(),
    
    // Succès (page générique)
    '/success': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SuccessPage(
        title: args?['title'] ?? 'Succès',
        message: args?['message'] ?? 'Opération réussie',
        buttonText: args?['buttonText'],
        nextRoute: args?['nextRoute'],
      );
    },
    
    // Pages de succès spécifiques
    '/success/registration': (context) => const SuccessPage(
      title: 'Inscription réussie',
      message: 'Votre compte a été créé avec succès !',
      nextRoute: '/home',
    ),
    '/success/login': (context) => const SuccessPage(
      title: 'Connexion réussie',
      message: 'Bienvenue dans votre espace personnel !',
      nextRoute: '/home',
    ),
    '/success/plan_created': (context) => const SuccessPage(
      title: 'Plan créé',
      message: 'Votre plan de lecture a été créé avec succès !',
      nextRoute: '/home',
    ),
    '/success/analysis': (context) => const SuccessPage(
      title: 'Analyse terminée',
      message: 'Votre analyse a été complétée avec succès !',
      nextRoute: '/home',
    ),
    '/success/save': (context) => const SuccessPage(
      title: 'Sauvegarde réussie',
      message: 'Vos données ont été sauvegardées !',
      nextRoute: '/home',
    ),
    
    // Payerpage - Carousel de cartes de prière
    '/payerpage': (context) => const PrayerCarouselPage(),
    
    // Verse Poster - Création de poster de verset
    '/verse_poster': (context) => const VersePosterPage(),
    
    // Spiritual Wall - Mur spirituel avec historique des méditations
    '/spiritual_wall': (context) => const SpiritualWallPage(),
    
    // Gratitude Page - Page de gratitude après partage/sauvegarde
    '/gratitude': (context) => const GratitudePage(),
    
    
    // Coming Soon Page - Page temporaire pour fonctionnalités à venir
    '/community/new-post': (context) => const ComingSoonPage(),
    '/coming_soon': (context) => const ComingSoonPage(),
    
    // Bible Quiz Page - Quiz biblique avancé basé sur l'historique
    '/bible_quiz': (context) => const BibleQuizPage(),
  };
}