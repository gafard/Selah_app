import 'package:hive/hive.dart';
import 'local_storage_service.dart';

/// Service offline pour comparer différentes versions bibliques
/// 
/// Sources de données :
/// - Hive box 'bible_versions_meta' (métadonnées versions)
/// - Hive box 'local_bible' (textes des versions téléchargées)
/// 
/// Fonctionnalités :
/// - Liste versions disponibles localement
/// - Récupère texte d'un verset dans une version spécifique
/// - Comparaison côte à côte (side-by-side)
class VersionCompareService {
  static Box? _versionsMetaBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _versionsMetaBox = await Hive.openBox('bible_versions_meta');
    print('✅ VersionCompareService initialisé');
  }
  
  /// Récupère les versions disponibles localement
  /// 
  /// Retourne : Liste des codes de versions (ex: ["LSG", "S21", "BDS"])
  static Future<List<String>> availableVersions() async {
    try {
      // Récupérer depuis LocalStorageService
      final versions = LocalStorageService.getAvailableBibleVersions();
      
      // Filtrer celles qui sont vraiment disponibles
      final available = <String>[];
      for (final version in versions) {
        final data = LocalStorageService.getBibleVersion(version);
        if (data != null && data.isNotEmpty) {
          available.add(version);
        }
      }
      
      return available;
    } catch (e) {
      print('⚠️ Erreur availableVersions: $e');
      return [];
    }
  }
  
  /// Récupère le texte d'un verset dans une version spécifique
  /// 
  /// [version] : Code de la version (ex: "LSG")
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// 
  /// Retourne : Texte du verset ou null
  static Future<String?> verseText(String version, String id) async {
    try {
      // Récupérer les données de la version
      final versionData = LocalStorageService.getBibleVersion(version);
      if (versionData == null) return null;
      
      // Chercher le verset
      // Format attendu : { "verses": { "Jean.3.16": "Car Dieu a tant aimé..." } }
      final verses = versionData['verses'] as Map<String, dynamic>?;
      if (verses == null) return null;
      
      return verses[id] as String?;
    } catch (e) {
      print('⚠️ Erreur verseText($version, $id): $e');
      return null;
    }
  }
  
  /// Comparaison côte à côte de plusieurs versions
  /// 
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// [versions] : Liste des versions à comparer (optionnel, défaut: toutes disponibles)
  /// 
  /// Retourne : Liste de {version, text} pour comparaison
  static Future<List<VersionText>> sideBySide(
    String id, {
    List<String>? versions,
  }) async {
    try {
      // Si versions non spécifiées, utiliser toutes les disponibles
      versions ??= await availableVersions();
      
      final comparisons = <VersionText>[];
      
      for (final version in versions) {
        final text = await verseText(version, id);
        if (text != null) {
          comparisons.add(VersionText(
            version: version,
            versionName: _getVersionName(version),
            text: text,
          ));
        }
      }
      
      return comparisons;
    } catch (e) {
      print('⚠️ Erreur sideBySide($id): $e');
      return [];
    }
  }
  
  /// Obtient le nom complet d'une version
  static String _getVersionName(String code) {
    const names = {
      'LSG': 'Louis Segond 1910',
      'S21': 'Segond 21',
      'BDS': 'Bible du Semeur',
      'NBS': 'Nouvelle Bible Segond',
      'TOB': 'Traduction Œcuménique de la Bible',
      'PDV': 'Parole de Vie',
      'FC': 'Français Courant',
      'NEG': 'Nouvelle Édition de Genève',
    };
    
    return names[code] ?? code;
  }
  
  /// Vérifie si au moins 2 versions sont disponibles
  static Future<bool> canCompare() async {
    final versions = await availableVersions();
    return versions.length >= 2;
  }
  
  /// Obtient les métadonnées d'une version
  static Future<VersionMetadata?> getMetadata(String version) async {
    try {
      final data = _versionsMetaBox?.get(version);
      if (data == null) return null;
      
      return VersionMetadata.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('⚠️ Erreur getMetadata($version): $e');
      return null;
    }
  }
  
  static bool _isOldTestament(String book) {
    const otBooks = [
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', 'Juges', 'Ruth', '1Samuel', '2Samuel', '1Rois', '2Rois',
      'Psaumes', 'Proverbes', 'Job', 'Ecclésiaste', 'Cantique',
      'Ésaïe', 'Jérémie', 'Ézéchiel', 'Daniel',
    ];
    return otBooks.contains(book);
  }
  
  static bool _isNewTestament(String book) {
    const ntBooks = [
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
      'Romains', '1Corinthiens', '2Corinthiens', 'Galates', 'Éphésiens',
      'Philippiens', 'Colossiens', '1Thessaloniciens', '2Thessaloniciens',
      '1Timothée', '2Timothée', 'Tite', 'Philémon',
      'Hébreux', 'Jacques', '1Pierre', '2Pierre',
      '1Jean', '2Jean', '3Jean', 'Jude', 'Apocalypse',
    ];
    return ntBooks.contains(book);
  }
}

/// Texte d'un verset dans une version spécifique
class VersionText {
  final String version;
  final String versionName;
  final String text;
  
  VersionText({
    required this.version,
    required this.versionName,
    required this.text,
  });
}

/// Métadonnées d'une version biblique
class VersionMetadata {
  final String code;
  final String name;
  final String language;
  final String description;
  final bool isDownloaded;
  
  VersionMetadata({
    required this.code,
    required this.name,
    required this.language,
    required this.description,
    required this.isDownloaded,
  });
  
  factory VersionMetadata.fromJson(Map<String, dynamic> json) {
    return VersionMetadata(
      code: json['code'] as String,
      name: json['name'] as String,
      language: json['language'] as String? ?? 'fr',
      description: json['description'] as String? ?? '',
      isDownloaded: json['is_downloaded'] as bool? ?? false,
    );
  }
}

