// lib/router.dart
import 'package:flutter/material.dart';
import 'package:essai/views/welcome_page.dart';
import 'package:essai/views/login_page.dart';
import 'package:essai/views/onboarding_page.dart';
import 'package:essai/views/goals_page.dart';
import 'package:essai/views/success_page.dart';
import 'package:essai/views/prayer_workflow_demo.dart';
import 'package:essai/views/prayer_generator_page.dart';
import 'package:essai/views/home_page.dart';
import 'package:essai/views/complete_profile_page.dart';
import 'package:essai/views/custom_plan_page.dart';
import 'package:essai/views/bible_videos_page.dart';
import 'package:essai/views/journal_page.dart';
import 'package:essai/views/settings_page.dart';
import 'package:essai/views/reader_page_modern.dart';
import 'package:essai/views/reader_settings_page.dart';
import 'package:essai/views/meditation_chooser_page.dart';
import 'package:essai/views/meditation_free_page.dart';
import 'package:essai/views/meditation_qcm_page.dart';
import 'package:essai/views/meditation_auto_qcm_page.dart';
import 'package:essai/views/passage_analysis_demo.dart';
import 'package:essai/views/prayer_subjects_page.dart';
import 'package:essai/views/prayer_carousel_page.dart';
import 'package:essai/views/verse_poster_page.dart';
import 'package:essai/views/spiritual_wall_page.dart';
import 'package:essai/views/gratitude_page.dart';
import 'package:essai/views/coming_soon_page.dart';
import 'package:essai/views/bible_quiz_page.dart';
import 'package:essai/views/scan_bible_page.dart';
import 'package:essai/views/advanced_scan_bible_page.dart';
import 'package:essai/views/profile_page.dart';
import 'package:essai/views/splash_page.dart';
import 'package:essai/views/pre_meditation_prayer_page.dart';
import 'package:essai/views/main_navigation_wrapper.dart';
// import 'package:essai/views/payerpage_widget.dart'; // Temporairement désactivé
import 'package:essai/test_navigation.dart';

class AppRouter {
  static final routes = <String, Widget Function(BuildContext)>{
    // Page de test
    '/test': (context) => const TestNavigationPage(),
    
    // Authentification
    '/welcome': (context) => const WelcomePage(),
    '/login': (context) => const LoginPage(),
    '/onboarding': (context) => const OnboardingFlow(),
    '/complete_profile': (context) => const CompleteProfilePage(),
    
    // Plans
    '/goals': (context) => const GoalsPage(),
    '/custom_plan': (context) => const CustomPlanPage(),
    
    // Pages principales
    '/home': (context) => const MainNavigationWrapper(initialIndex: 1),
    '/pre_meditation_prayer': (context) => const PreMeditationPrayerPage(),
    '/reader': (context) => const MainNavigationWrapper(initialIndex: 1, initialRoute: '/reader'),
    '/reader_modern': (context) => const MainNavigationWrapper(initialIndex: 1, initialRoute: '/reader'),
    '/reader_settings': (context) => const ReaderSettingsPage(),
    '/journal': (context) => const MainNavigationWrapper(initialIndex: 2, initialRoute: '/journal'),
    '/bible_videos': (context) => const BibleVideosPage(),
    '/settings': (context) => const SettingsPage(),
    
    // Méditation
    '/meditation/chooser': (context) => const MeditationChooserPage(),
    '/meditation/free': (context) => const MeditationFreePage(
      passageRef: 'Jean 3:16',
      passageText: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
    ),
    '/meditation/qcm': (context) => const MeditationQcmPage(),
    '/meditation/auto_qcm': (context) => const MeditationAutoQcmPage(),
    '/passage_analysis_demo': (context) => const PassageAnalysisDemo(),
    '/prayer_subjects': (context) => const PrayerSubjectsPage(),
    
    // Prière
    '/prayer_workflow': (context) => const PrayerWorkflowDemo(),
    '/prayer_workflow_demo': (context) => const PrayerWorkflowDemo(),
    '/prayer_generator': (context) => const PrayerGeneratorPage(),
    '/prayer_editor': (context) => const PrayerGeneratorPage(), // Placeholder pour l'éditeur de prière
    
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
    
        // Payerpage - Carousel de cartes de prière (VOTRE DESIGN)
        '/payerpage': (context) => const PrayerCarouselPage(),
        
        // Verse Poster - Création de poster de verset
        '/verse_poster': (context) => const VersePosterPage(),
        
        // Spiritual Wall - Mur spirituel avec historique des méditations
        '/spiritual_wall': (context) => const MainNavigationWrapper(initialIndex: 1, initialRoute: '/spiritual_wall'),
        
        // Gratitude Page - Page de gratitude après partage/sauvegarde
        '/gratitude': (context) => const GratitudePage(),
        
        // Coming Soon Page - Page temporaire pour fonctionnalités à venir
        '/community/new-post': (context) => const ComingSoonPage(),
        '/coming_soon': (context) => const ComingSoonPage(),
        
        // Bible Quiz Page - Quiz biblique avancé basé sur l'historique
        '/bible_quiz': (context) => const BibleQuizPage(),
  };
}