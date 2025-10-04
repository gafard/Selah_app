// lib/router.dart
import 'package:flutter/material.dart';
import 'package:essai/views/welcome_page.dart';
import 'package:essai/views/login_page.dart';
import 'package:essai/views/register_page.dart';
import 'package:essai/views/onboarding_page.dart';
import 'package:essai/views/goals_page.dart';
import 'package:essai/views/success_page.dart';
import 'package:essai/views/prayer_workflow_demo.dart';
import 'package:essai/views/prayer_generator_page.dart';
import 'package:essai/views/home_page.dart';
import 'package:essai/views/selah_home_page.dart';
import 'package:essai/views/complete_profile_page.dart';
import 'package:essai/views/custom_plan_page.dart';
import 'package:essai/views/bible_videos_page.dart';
import 'package:essai/views/journal_page.dart';
import 'package:essai/views/settings_page.dart';
import 'package:essai/views/reader_page_modern.dart';
import 'package:essai/views/reader_settings_page.dart';
import 'package:essai/views/meditation_chooser_page.dart';
import 'package:essai/views/meditation_flow_page.dart';
import 'package:essai/views/meditation_free_page.dart';
import 'package:essai/views/meditation_qcm_page.dart';
import 'package:essai/views/meditation_auto_qcm_page.dart';
import 'package:essai/views/passage_analysis_demo.dart';
import 'package:essai/views/prayer_subjects_page.dart';
import 'package:essai/test_navigation.dart';

class AppRouter {
  static final routes = <String, Widget Function(BuildContext)>{
    // Page de test
    '/test': (context) => const TestNavigationPage(),
    
    // Authentification
    '/welcome': (context) => const WelcomePage(),
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
    '/onboarding': (context) => const OnboardingFlow(),
    '/complete_profile': (context) => const CompleteProfilePage(),
    
    // Plans
    '/goals': (context) => const GoalsPage(),
    '/custom_plan': (context) => const CustomPlanPage(),
    
    // Pages principales
    '/home': (context) => const HomePageWidget(),
    '/selah_home': (context) => const SelahHomePage(),
    '/reader': (context) => const ReaderPageModern(),
    '/reader_modern': (context) => const ReaderPageModern(),
    '/reader_settings': (context) => const ReaderSettingsPage(),
    '/journal': (context) => const JournalPage(),
    '/bible_videos': (context) => const BibleVideosPage(),
    '/settings': (context) => const SettingsPage(),
    
    // Méditation
    '/meditation/chooser': (context) => const MeditationChooserPage(),
    '/meditation/flow': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MeditationFlowModern(
        planId: args?['planId'],
        day: args?['day'],
        ref: args?['ref'],
      );
    },
    '/meditation/free': (context) => const MeditationFreePage(),
    '/meditation/qcm': (context) => const MeditationQcmPage(),
    '/meditation/auto_qcm': (context) => const MeditationAutoQcmPage(),
    '/passage_analysis_demo': (context) => const PassageAnalysisDemo(),
    '/prayer_subjects': (context) => const PrayerSubjectsPage(),
    
    // Prière
    '/prayer_workflow': (context) => const PrayerWorkflowDemo(),
    '/prayer_workflow_demo': (context) => const PrayerWorkflowDemo(),
    '/prayer_generator': (context) => const PrayerGeneratorPage(),
    
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
  };
}