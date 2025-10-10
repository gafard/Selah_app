import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/reader_settings.dart';

/// ⚡ ÉVANGÉLISTE - Service de paramètres de lecture avec adaptation contextuelle
/// 
/// Niveau : Évangéliste (Fonctionnel) - Service fonctionnel pour les paramètres adaptatifs
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (contexte de lecture)
/// 🔥 Priorité 2: user_prefs_hive.dart (préférences utilisateur)
/// 🔥 Priorité 3: thompson_plan_service.dart (thèmes spirituels)
/// 🎯 Thompson: Enrichit les paramètres avec thèmes spirituels
class ReaderSettingsService extends ChangeNotifier {
  static final ReaderSettingsService _instance = ReaderSettingsService._internal();
  factory ReaderSettingsService() => _instance;
  ReaderSettingsService._internal();

  ReaderSettings _settings = const ReaderSettings();
  static const String _settingsKey = 'reader_settings';
  Box? _adaptiveSettingsBox;
  Map<String, dynamic> _readingContext = {};
  Map<String, dynamic> _userPreferences = {};

  // Getters
  String get selectedTheme => _settings.theme;
  String get selectedFont => _settings.font;
  double get fontSize => _settings.fontSize;
  String get textAlignment => _settings.textAlignment;
  bool get isOfflineMode => _settings.isOfflineMode;
  bool get isLocked => _settings.isLocked;
  bool get isSearchEnabled => _settings.isSearchEnabled;
  bool get isTransitionsEnabled => _settings.isTransitionsEnabled;
  double get brightness => _settings.brightness;

  ReaderSettings get settings => _settings;

  /// 🧠 Initialise les paramètres avec adaptation contextuelle
  Future<void> loadSettings() async {
    try {
      // Initialiser la box Hive pour les paramètres adaptatifs
      _adaptiveSettingsBox = await Hive.openBox('adaptive_reader_settings');
      
      // Charger les paramètres de base
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        _settings = ReaderSettings.fromJson(jsonDecode(settingsJson));
      }
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Charger le contexte de lecture
      await _loadReadingContext();
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Charger les préférences utilisateur
      await _loadUserPreferences();
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Adapter les paramètres selon le contexte
      await _adaptSettingsToContext();
      
      notifyListeners();
      print('🚗 Évangéliste Intelligent: Paramètres de lecture adaptés au contexte');
    } catch (e) {
      // Use default settings if loading fails
      _settings = const ReaderSettings();
      print('⚠️ Erreur chargement paramètres adaptatifs: $e');
    }
  }

  /// 🧠 Charge le contexte de lecture
  Future<void> _loadReadingContext() async {
    try {
      // 🔥 PRIORITÉ 1: Récupérer le contexte sémantique FALCON X
      final currentReading = await _getCurrentReading();
      if (currentReading != null) {
        _readingContext = {
          'book': currentReading['book'],
          'chapter': currentReading['chapter'],
          'semanticUnit': currentReading['semanticUnit'],
          'priority': currentReading['priority'],
          'theme': currentReading['theme'],
        };
      }
    } catch (e) {
      print('⚠️ Erreur chargement contexte lecture: $e');
    }
  }

  /// 🧠 Charge les préférences utilisateur
  Future<void> _loadUserPreferences() async {
    try {
      // 🔥 PRIORITÉ 2: Récupérer les préférences utilisateur
      // TODO: Intégrer avec user_prefs_hive
      _userPreferences = {
        'preferredTheme': 'auto',
        'preferredFont': 'serif',
        'preferredFontSize': 16.0,
        'accessibilityMode': false,
        'thompsonEnabled': true,
      };
    } catch (e) {
      print('⚠️ Erreur chargement préférences utilisateur: $e');
    }
  }

  /// 🧠 Adapte les paramètres selon le contexte
  Future<void> _adaptSettingsToContext() async {
    try {
      // 🔥 PRIORITÉ 1: Adapter selon le contexte sémantique
      if (_readingContext.isNotEmpty) {
        await _adaptToSemanticContext();
      }
      
      // 🔥 PRIORITÉ 2: Adapter selon les préférences utilisateur
      if (_userPreferences.isNotEmpty) {
        await _adaptToUserPreferences();
      }
      
      // 🔥 PRIORITÉ 3: Adapter selon le thème Thompson
      await _adaptToThompsonTheme();
      
    } catch (e) {
      print('⚠️ Erreur adaptation paramètres: $e');
    }
  }

  /// 🔥 PRIORITÉ 1: Adapte selon le contexte sémantique FALCON X
  Future<void> _adaptToSemanticContext() async {
    try {
      final priority = _readingContext['priority'] as String?;
      final theme = _readingContext['theme'] as String?;
      
      if (priority == 'critical') {
        // Passages critiques → paramètres pour la méditation profonde
        _settings = _settings.copyWith(
          fontSize: _settings.fontSize * 1.1, // Taille plus grande
          brightness: 0.9, // Luminosité réduite pour la concentration
        );
      } else if (priority == 'low') {
        // Passages moins critiques → paramètres pour la lecture rapide
        _settings = _settings.copyWith(
          fontSize: _settings.fontSize * 0.95, // Taille plus petite
          brightness: 1.0, // Luminosité maximale
        );
      }
      
      // Adapter selon le thème sémantique
      if (theme != null) {
        if (theme.contains('prière')) {
          _settings = _settings.copyWith(theme: 'dark'); // Thème sombre pour la prière
        } else if (theme.contains('sagesse')) {
          _settings = _settings.copyWith(theme: 'light'); // Thème clair pour la sagesse
        }
      }
      
    } catch (e) {
      print('⚠️ Erreur adaptation contexte sémantique: $e');
    }
  }

  /// 🔥 PRIORITÉ 2: Adapte selon les préférences utilisateur
  Future<void> _adaptToUserPreferences() async {
    try {
      final preferredTheme = _userPreferences['preferredTheme'] as String?;
      final preferredFont = _userPreferences['preferredFont'] as String?;
      final preferredFontSize = _userPreferences['preferredFontSize'] as double?;
      final accessibilityMode = _userPreferences['accessibilityMode'] as bool?;
      
      if (preferredTheme != null && preferredTheme != 'auto') {
        _settings = _settings.copyWith(theme: preferredTheme);
      }
      
      if (preferredFont != null) {
        _settings = _settings.copyWith(font: preferredFont);
      }
      
      if (preferredFontSize != null) {
        _settings = _settings.copyWith(fontSize: preferredFontSize);
      }
      
      if (accessibilityMode == true) {
        // Mode accessibilité → paramètres optimisés
        _settings = _settings.copyWith(
          fontSize: _settings.fontSize * 1.2,
          brightness: 1.0,
        );
      }
      
    } catch (e) {
      print('⚠️ Erreur adaptation préférences utilisateur: $e');
    }
  }

  /// 🔥 PRIORITÉ 3: Adapte selon le thème Thompson
  Future<void> _adaptToThompsonTheme() async {
    try {
      // TODO: Intégrer avec thompson_plan_service pour récupérer le thème du jour
      final thompsonTheme = await _getThompsonTheme();
      
      if (thompsonTheme != null) {
        if (thompsonTheme.contains('prière')) {
          _settings = _settings.copyWith(
            theme: 'dark',
            brightness: 0.8, // Luminosité réduite pour la prière
          );
        } else if (thompsonTheme.contains('sagesse')) {
          _settings = _settings.copyWith(
            theme: 'light',
            brightness: 1.0, // Luminosité maximale pour la sagesse
          );
        }
      }
      
    } catch (e) {
      print('⚠️ Erreur adaptation thème Thompson: $e');
    }
  }

  /// 🧠 Récupère la lecture actuelle
  Future<Map<String, dynamic>?> _getCurrentReading() async {
    try {
      // TODO: Intégrer avec plan_service_http pour récupérer la lecture du jour
      // Pour l'instant, on simule
      return {
        'book': 'Psaumes',
        'chapter': 23,
        'semanticUnit': 'Le Berger et ses brebis',
        'priority': 'critical',
        'theme': 'prière',
      };
    } catch (e) {
      return null;
    }
  }

  /// 🧠 Récupère le thème Thompson
  Future<String?> _getThompsonTheme() async {
    try {
      // TODO: Intégrer avec thompson_plan_service
      return 'Vie de prière — Souffle spirituel';
    } catch (e) {
      return null;
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      // Handle save error silently
    }
  }

  // Setters
  void setTheme(String theme) {
    _settings = _settings.copyWith(theme: theme);
    _saveSettings();
    notifyListeners();
  }

  void setFont(String font) {
    _settings = _settings.copyWith(font: font);
    _saveSettings();
    notifyListeners();
  }

  void setFontSize(double size) {
    _settings = _settings.copyWith(fontSize: size);
    _saveSettings();
    notifyListeners();
  }

  void setTextAlignment(String alignment) {
    _settings = _settings.copyWith(textAlignment: alignment);
    _saveSettings();
    notifyListeners();
  }

  void setOfflineMode(bool enabled) {
    _settings = _settings.copyWith(isOfflineMode: enabled);
    _saveSettings();
    notifyListeners();
  }

  void setLocked(bool locked) {
    _settings = _settings.copyWith(isLocked: locked);
    _saveSettings();
    notifyListeners();
  }

  void setSearchEnabled(bool enabled) {
    _settings = _settings.copyWith(isSearchEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  void setTransitionsEnabled(bool enabled) {
    _settings = _settings.copyWith(isTransitionsEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  void setBrightness(double brightness) {
    _settings = _settings.copyWith(brightness: brightness);
    _saveSettings();
    notifyListeners();
  }

  // Helper methods
  TextStyle getFontStyle() {
    Color textColor = _settings.theme == 'dark' ? Colors.white : const Color(0xFF333333);
    
    // Apply brightness with minimum value to avoid text disappearing
    double adjustedBrightness = (_settings.brightness * 0.7) + 0.3; // Keep between 30% and 100% brightness
    textColor = Color.fromRGBO(
      (textColor.red * adjustedBrightness).round(),
      (textColor.green * adjustedBrightness).round(),
      (textColor.blue * adjustedBrightness).round(),
      textColor.opacity,
    );

    return _settings.getFontStyle().copyWith(
      color: textColor,
      height: 1.6,
    );
  }

  TextAlign getTextAlign() {
    return _settings.getTextAlign();
  }

  Color getBackgroundColor() {
    return _settings.theme == 'dark' ? const Color(0xFF2D2D2D) : Colors.white;
  }

  /// 🧠 Méthode intelligente pour adapter les paramètres à un contexte spécifique
  Future<void> adaptToContext(String reference, String? thompsonTheme) async {
    try {
      // Mettre à jour le contexte de lecture
      _readingContext = {
        'reference': reference,
        'thompsonTheme': thompsonTheme,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Adapter les paramètres
      await _adaptSettingsToContext();
      
      // Sauvegarder les paramètres adaptatifs
      await _saveAdaptiveSettings();
      
      notifyListeners();
      print('🚗 Évangéliste Intelligent: Paramètres adaptés au contexte $reference');
    } catch (e) {
      print('⚠️ Erreur adaptation contexte: $e');
    }
  }

  /// 🧠 Sauvegarde les paramètres adaptatifs
  Future<void> _saveAdaptiveSettings() async {
    try {
      await _adaptiveSettingsBox?.put('current_context', _readingContext);
      await _adaptiveSettingsBox?.put('user_preferences', _userPreferences);
      await _adaptiveSettingsBox?.put('last_adaptation', DateTime.now().toIso8601String());
    } catch (e) {
      print('⚠️ Erreur sauvegarde paramètres adaptatifs: $e');
    }
  }

  /// 🧠 Récupère les paramètres adaptatifs sauvegardés
  Future<Map<String, dynamic>?> getAdaptiveSettings() async {
    try {
      return {
        'current_context': _adaptiveSettingsBox?.get('current_context'),
        'user_preferences': _adaptiveSettingsBox?.get('user_preferences'),
        'last_adaptation': _adaptiveSettingsBox?.get('last_adaptation'),
      };
    } catch (e) {
      return null;
    }
  }

  /// 🧠 Prédit les paramètres optimaux pour un contexte
  Future<ReaderSettings> predictOptimalSettings(String reference) async {
    try {
      // Analyser le contexte de la référence
      final context = await _analyzeReferenceContext(reference);
      
      // Créer des paramètres optimaux basés sur l'analyse
      return _createOptimalSettings(context);
    } catch (e) {
      print('⚠️ Erreur prédiction paramètres: $e');
      return _settings;
    }
  }

  /// 🧠 Analyse le contexte d'une référence
  Future<Map<String, dynamic>> _analyzeReferenceContext(String reference) async {
    try {
      // TODO: Intégrer avec semantic_passage_boundary_service pour analyser la référence
      return {
        'book': reference.split(' ').first,
        'chapter': reference.split(' ').length > 1 ? reference.split(' ')[1] : '1',
        'estimatedPriority': 'medium',
        'estimatedTheme': 'general',
      };
    } catch (e) {
      return {'book': 'Unknown', 'chapter': '1', 'estimatedPriority': 'low', 'estimatedTheme': 'general'};
    }
  }

  /// 🧠 Crée des paramètres optimaux basés sur l'analyse
  ReaderSettings _createOptimalSettings(Map<String, dynamic> context) {
    final priority = context['estimatedPriority'] as String?;
    final theme = context['estimatedTheme'] as String?;
    
    double fontSize = _settings.fontSize;
    double brightness = _settings.brightness;
    String themeMode = _settings.theme;
    
    // Adapter selon la priorité estimée
    if (priority == 'critical') {
      fontSize *= 1.1;
      brightness = 0.9;
      themeMode = 'dark';
    } else if (priority == 'low') {
      fontSize *= 0.95;
      brightness = 1.0;
      themeMode = 'light';
    }
    
    // Adapter selon le thème estimé
    if (theme != null) {
      if (theme.contains('prière')) {
        themeMode = 'dark';
        brightness = 0.8;
      } else if (theme.contains('sagesse')) {
        themeMode = 'light';
        brightness = 1.0;
      }
    }
    
    return _settings.copyWith(
      fontSize: fontSize,
      brightness: brightness,
      theme: themeMode,
    );
  }

  /// 🧠 Retourne les statistiques d'adaptation
  Map<String, dynamic> getAdaptationStats() {
    return {
      'current_context': _readingContext,
      'user_preferences': _userPreferences,
      'adaptive_settings_enabled': _adaptiveSettingsBox != null,
      'last_adaptation': _adaptiveSettingsBox?.get('last_adaptation'),
    };
  }
}