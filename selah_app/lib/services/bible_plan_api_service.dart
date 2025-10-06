import 'package:http/http.dart' as http;
import '../models/thompson_plan_models.dart';

/// Service pour interagir avec l'API biblereadingplangenerator.com
/// Génère des plans de lecture biblique réels basés sur les paramètres utilisateur
class BiblePlanApiService {
  static const String _baseUrl = 'https://www.biblereadingplangenerator.com';
  static const String _proxyUrl = 'https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/bible-plan-proxy';
  
  /// Génère un plan de lecture via l'API biblereadingplangenerator.com
  static Future<BiblePlanResponse> generatePlan({
    required DateTime startDate,
    required int totalDays,
    required String order,
    required String books,
    required List<int> daysOfWeek,
    required String language,
    required String version,
    String? planName,
  }) async {
    try {
      print('🌐 Génération plan via API biblereadingplangenerator.com...');
      print('📅 Début: ${startDate.toIso8601String().split('T')[0]}');
      print('📖 Durée: $totalDays jours');
      print('📚 Livres: $books');
      print('🔤 Version: $version');
      
      final daysParam = daysOfWeek.join(',');
      final startParam = startDate.toIso8601String().split('T')[0];
      
      // Utiliser le proxy Supabase pour contourner CORS
      final uri = Uri.parse(_proxyUrl).replace(queryParameters: {
        'start': startParam,
        'total': totalDays.toString(),
        'format': 'calendar',
        'order': order,
        'daysofweek': daysParam,
        'books': books,
        'lang': language,
        'logic': 'words',
        'checkbox': '1',
        'colors': '0',
        'dailypsalm': '0',
        'dailyproverb': '0',
        'otntoverlap': '0',
        'reverse': '0',
        'stats': '0',
        'dailystats': '0',
        'nodates': '0',
        'includeurls': '1',
        'urlsite': 'biblegateway',
        'urlversion': version,
      });
      
      print('🔗 URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Selah App/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        print('✅ Plan généré avec succès (${response.body.length} caractères)');
        return BiblePlanResponse(
          success: true,
          htmlContent: response.body,
          planName: planName ?? 'Plan de lecture $totalDays jours',
          startDate: startDate,
          totalDays: totalDays,
          books: books,
          version: version,
        );
      } else {
        print('❌ Erreur API: ${response.statusCode}');
        return BiblePlanResponse(
          success: false,
          error: 'Erreur HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur génération plan: $e');
      return BiblePlanResponse(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Génère un plan personnalisé basé sur le profil Thompson
  static Future<BiblePlanResponse> generateThompsonBasedPlan({
    required CompleteProfile profile,
    required String thompsonTheme,
    String? customPlanName,
  }) async {
    // Mapper les thèmes Thompson vers les paramètres de lecture
    final planConfig = _mapThompsonThemeToPlanConfig(thompsonTheme, profile);
    
    return generatePlan(
      startDate: profile.startDate,
      totalDays: planConfig['totalDays'] as int,
      order: planConfig['order'] as String,
      books: planConfig['books'] as String,
      daysOfWeek: profile.daysPerWeek == 7 
          ? [1, 2, 3, 4, 5, 6, 7]
          : List.generate(profile.daysPerWeek, (i) => i + 1),
      language: profile.language,
      version: _mapLanguageToVersion(profile.language),
      planName: customPlanName ?? _generatePlanName(thompsonTheme, planConfig['totalDays'] as int),
    );
  }
  
  /// Mappe un thème Thompson vers une configuration de plan de lecture
  static Map<String, dynamic> _mapThompsonThemeToPlanConfig(String theme, CompleteProfile profile) {
    switch (theme) {
      case 'spiritual_demand':
        return {
          'totalDays': _calculateDuration(profile, 90), // 3 mois pour approfondir
          'order': 'chronological',
          'books': 'NT', // Nouveau Testament pour la spiritualité
        };
      case 'no_worry':
        return {
          'totalDays': _calculateDuration(profile, 40), // 40 jours comme Jésus au désert
          'order': 'thematic',
          'books': 'Gospels,Psalms', // Évangiles et Psaumes pour la paix
        };
      case 'companionship':
        return {
          'totalDays': _calculateDuration(profile, 60), // 2 mois pour la communauté
          'order': 'traditional',
          'books': 'OT,NT', // Toute la Bible pour la communion
        };
      case 'marriage_duties':
        return {
          'totalDays': _calculateDuration(profile, 30), // 1 mois pour les couples
          'order': 'thematic',
          'books': 'Gospels,Psalms,Proverbs', // Sagesse et amour
        };
      case 'prayer_life':
        return {
          'totalDays': _calculateDuration(profile, 50), // 50 jours pour la prière
          'order': 'traditional',
          'books': 'Psalms', // Psaumes pour la prière
        };
      case 'forgiveness':
        return {
          'totalDays': _calculateDuration(profile, 21), // 21 jours pour le pardon
          'order': 'chronological',
          'books': 'NT', // Nouveau Testament pour le pardon
        };
      case 'faith_trials':
        return {
          'totalDays': _calculateDuration(profile, 70), // 70 jours pour les épreuves
          'order': 'historical',
          'books': 'OT,NT', // Toute la Bible pour la foi
        };
      case 'common_errors':
        return {
          'totalDays': _calculateDuration(profile, 45), // 45 jours pour la sagesse
          'order': 'traditional',
          'books': 'Proverbs,James', // Proverbes et Jacques pour la sagesse
        };
      default:
        return {
          'totalDays': _calculateDuration(profile, 30),
          'order': 'traditional',
          'books': 'OT,NT',
        };
    }
  }
  
  /// Calcule la durée selon le profil utilisateur
  static int _calculateDuration(CompleteProfile profile, int baseDays) {
    // Ajuster selon l'expérience et le temps disponible
    double multiplier = 1.0;
    
    if (profile.experience == 'new') {
      multiplier = 0.7; // Plans plus courts pour les débutants
    } else if (profile.experience == 'mature') {
      multiplier = 1.3; // Plans plus longs pour les matures
    }
    
    if (profile.minutesPerDay < 10) {
      multiplier *= 0.8; // Plans plus courts si peu de temps
    } else if (profile.minutesPerDay > 20) {
      multiplier *= 1.2; // Plans plus longs si beaucoup de temps
    }
    
    return (baseDays * multiplier).round().clamp(7, 365);
  }
  
  /// Mappe la langue vers une version biblique
  static String _mapLanguageToVersion(String language) {
    switch (language.toLowerCase()) {
      case 'fr':
        return 'LSG'; // Louis Segond
      case 'en':
        return 'NIV';
      case 'es':
        return 'NVI'; // Nueva Versión Internacional
      case 'de':
        return 'NGU'; // Neue Genfer Übersetzung
      default:
        return 'NIV';
    }
  }
  
  /// Génère un nom de plan basé sur le thème
  static String _generatePlanName(String theme, int days) {
    final themeNames = {
      'spiritual_demand': 'Exigence spirituelle',
      'no_worry': 'Paix du cœur',
      'companionship': 'Communion fraternelle',
      'marriage_duties': 'Mariage selon Dieu',
      'prayer_life': 'Vie de prière',
      'forgiveness': 'Pardon & guérison',
      'faith_trials': 'Foi dans l\'épreuve',
      'common_errors': 'Sagesse pratique',
    };
    
    final themeName = themeNames[theme] ?? 'Plan spirituel';
    return '$themeName — $days jours';
  }
  
  /// Parse le contenu HTML pour extraire les références bibliques
  static List<BibleReadingDay> parsePlanFromHtml(String htmlContent) {
    // Cette méthode devrait parser le HTML pour extraire les lectures quotidiennes
    // Pour l'instant, on retourne une structure basique
    return [];
  }
}

/// Réponse de l'API biblereadingplangenerator.com
class BiblePlanResponse {
  final bool success;
  final String? htmlContent;
  final String? error;
  final String? planName;
  final DateTime? startDate;
  final int? totalDays;
  final String? books;
  final String? version;
  
  const BiblePlanResponse({
    required this.success,
    this.htmlContent,
    this.error,
    this.planName,
    this.startDate,
    this.totalDays,
    this.books,
    this.version,
  });
}

/// Jour de lecture biblique
class BibleReadingDay {
  final DateTime date;
  final List<String> references;
  final String? notes;
  
  const BibleReadingDay({
    required this.date,
    required this.references,
    this.notes,
  });
}

