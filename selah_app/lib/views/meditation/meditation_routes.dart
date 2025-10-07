/// Routes centralisées pour toutes les pages de méditation
/// 
/// Ce fichier sert de référence pour éviter la confusion entre les différentes
/// pages de méditation et leurs routes.
library;

class MeditationRoutes {
  // Route principale - Chooser
  static const String chooser = '/meditation/chooser';
  
  // Options de méditation
  static const String free = '/meditation/free';
  static const String qcm = '/meditation/qcm';
  static const String autoQcm = '/meditation/auto_qcm';
  
  // Pages de support
  static const String prayerSubjects = '/prayer_subjects';
  static const String passageAnalysisDemo = '/passage_analysis_demo';
  
  // Anciennes routes (pour référence)
  static const String oldMeditation = '/meditation'; // meditation_page.dart
  static const String flowStart = '/meditation/start'; // meditation_flow_page.dart
}

/// Description des pages de méditation
class MeditationPages {
  static const Map<String, String> descriptions = {
    MeditationRoutes.chooser: 'Chooser principal - 3 options de méditation',
    MeditationRoutes.free: 'Méditation libre avec tags et génération de sujets de prière',
    MeditationRoutes.qcm: 'QCM classique avec questions prédéfinies',
    MeditationRoutes.autoQcm: 'QCM automatique généré depuis le texte biblique',
    MeditationRoutes.prayerSubjects: 'Sélection des sujets de prière suggérés',
    MeditationRoutes.passageAnalysisDemo: 'Démonstration d\'analyse de passage',
    MeditationRoutes.oldMeditation: 'Ancienne page de méditation (obsolète)',
    MeditationRoutes.flowStart: 'Flow de méditation complexe avec Riverpod',
  };
}
