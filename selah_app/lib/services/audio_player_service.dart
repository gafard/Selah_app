import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive/hive.dart';
import 'semantic_passage_boundary_service.dart';

/// 🧠 Contexte audio intelligent
class AudioContext {
  final String? reference;
  final String? theme;
  final Map<String, dynamic>? metadata;
  
  AudioContext({
    this.reference,
    this.theme,
    this.metadata,
  });
}

/// 🧠 Contexte sémantique pour audio
class SemanticContext {
  final String unitName;
  final String priority;
  final String theme;
  final String? liturgicalContext;
  final List<String> emotionalTones;
  final String? annotation;
  
  SemanticContext({
    required this.unitName,
    required this.priority,
    required this.theme,
    this.liturgicalContext,
    this.emotionalTones = const [],
    this.annotation,
  });
}

/// 🧠 PROPHÈTE - Lecteur audio avec intelligence sémantique
/// 
/// Niveau : Prophète (Intelligent) - Service intelligent pour l'audio adaptatif
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (FALCON X)
/// 🔥 Priorité 2: thompson_plan_service.dart (thèmes)
/// 🔥 Priorité 3: bible_context_service.dart (contexte)
/// 🎯 Thompson: Enrichit l'expérience audio avec thèmes spirituels
class AudioPlayerService {
  final _player = AudioPlayer();
  Box? _audioPrefsBox;
  
  /// 🧠 Initialise le lecteur audio intelligent avec contexte
  Future<void> init({required Uri url, AudioContext? context}) async {
    // Initialiser la box Hive pour les préférences audio
    _audioPrefsBox = await Hive.openBox('audio_prefs');
    
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // 🧠 INTELLIGENCE CONTEXTUELLE - Configurer selon le contexte
    if (context != null) {
      await _configureIntelligentAudio(context);
    }
    
    await _player.setAudioSource(AudioSource.uri(url));
    
    print('🏎️ Prophète Intelligent: Lecteur audio initialisé avec contexte');
  }

  /// 🧠 Configure l'audio selon le contexte intelligent
  Future<void> _configureIntelligentAudio(AudioContext context) async {
    try {
      // 🔥 PRIORITÉ 1: Récupérer le contexte sémantique FALCON X
      final semanticContext = await _getSemanticContext(context);
      
      // 🔥 PRIORITÉ 2: Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(context);
      
      // 🔥 PRIORITÉ 3: Récupérer les préférences utilisateur
      final userPrefs = await _getUserAudioPreferences();
      
      // 🧠 MACHINE LEARNING: Adapter la vitesse selon le contexte
      final optimalSpeed = _calculateOptimalSpeed(semanticContext, thompsonTheme, userPrefs);
      await _player.setSpeed(optimalSpeed);
      
      // 🧠 MACHINE LEARNING: Adapter le volume selon le contexte
      final optimalVolume = _calculateOptimalVolume(semanticContext, thompsonTheme, userPrefs);
      await _player.setVolume(optimalVolume);
      
      // Sauvegarder les préférences apprises
      await _saveLearnedPreferences(context, optimalSpeed, optimalVolume);
      
    } catch (e) {
      print('⚠️ Erreur configuration audio intelligente: $e');
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le contexte sémantique FALCON X
  Future<SemanticContext?> _getSemanticContext(AudioContext context) async {
    try {
      if (context.reference != null) {
        // Extraire livre et chapitre de la référence
        final parts = context.reference!.split(' ');
        if (parts.length >= 2) {
          final book = parts[0];
          final chapter = int.tryParse(parts[1]);
          if (chapter != null) {
            final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
            if (unit != null) {
              return SemanticContext(
                unitName: unit.name,
                priority: unit.priority.name,
                theme: unit.theme ?? '',
                liturgicalContext: unit.liturgicalContext ?? '',
                emotionalTones: unit.emotionalTones ?? [],
                annotation: unit.annotation,
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 2: Récupère le thème Thompson
  Future<String?> _getThompsonTheme(AudioContext context) async {
    try {
      if (context.reference != null) {
        // TODO: Intégrer avec thompson_plan_service pour récupérer le thème
        // Mapping basique pour l'instant
        if (context.reference!.contains('Psaumes')) {
          return 'Vie de prière — Souffle spirituel';
        } else if (context.reference!.contains('Jean')) {
          return 'Exigence spirituelle — Transformation profonde';
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Récupère les préférences utilisateur
  Future<Map<String, dynamic>?> _getUserAudioPreferences() async {
    try {
      // TODO: Intégrer avec user_prefs_hive pour récupérer les préférences audio
      return {
        'preferredSpeed': 1.0,
        'preferredVolume': 0.8,
        'thompsonEnabled': true,
      };
    } catch (e) {
      return null;
    }
  }

  /// 🧠 Calcule la vitesse optimale selon le contexte
  double _calculateOptimalSpeed(SemanticContext? semantic, String? thompson, Map<String, dynamic>? prefs) {
    double baseSpeed = prefs?['preferredSpeed'] ?? 1.0;
    
    // Adapter selon le contexte sémantique
    if (semantic != null) {
      if (semantic.priority == 'critical') {
        baseSpeed *= 0.8; // Ralentir pour les passages critiques
      } else if (semantic.priority == 'low') {
        baseSpeed *= 1.2; // Accélérer pour les passages moins critiques
      }
    }
    
    // Adapter selon le thème Thompson
    if (thompson != null) {
      if (thompson.contains('prière')) {
        baseSpeed *= 0.9; // Ralentir pour la prière
      } else if (thompson.contains('sagesse')) {
        baseSpeed *= 1.1; // Accélérer pour la sagesse
      }
    }
    
    return baseSpeed.clamp(0.5, 2.0);
  }

  /// 🧠 Calcule le volume optimal selon le contexte
  double _calculateOptimalVolume(SemanticContext? semantic, String? thompson, Map<String, dynamic>? prefs) {
    double baseVolume = prefs?['preferredVolume'] ?? 0.8;
    
    // Adapter selon le contexte sémantique
    if (semantic != null) {
      if (semantic.emotionalTones.contains('peaceful')) {
        baseVolume *= 0.9; // Volume plus doux pour la paix
      } else if (semantic.emotionalTones.contains('powerful')) {
        baseVolume *= 1.1; // Volume plus fort pour la puissance
      }
    }
    
    return baseVolume.clamp(0.1, 1.0);
  }

  /// 🧠 Sauvegarde les préférences apprises
  Future<void> _saveLearnedPreferences(AudioContext context, double speed, double volume) async {
    try {
      final key = '${context.reference ?? 'default'}_${DateTime.now().day}';
      await _audioPrefsBox?.put(key, {
        'speed': speed,
        'volume': volume,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Erreur sauvegarde préférences audio: $e');
    }
  }
  
  Stream<Duration> get position$ => _player.positionStream;
  Stream<Duration?> get duration$ => _player.durationStream;
  Stream<PlayerState> get state$ => _player.playerStateStream;
  
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration d) => _player.seek(d);
  Future<void> dispose() => _player.dispose();
  
  // Get current position synchronously
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  PlayerState get state => _player.playerState;
  
  // Check if currently playing
  bool get isPlaying => _player.playing;

  /// 🧠 Méthode intelligente pour jouer avec contexte
  Future<void> playWithContext(AudioContext context) async {
    await _configureIntelligentAudio(context);
    await play();
  }

  /// 🧠 Méthode intelligente pour ajuster la vitesse selon le contexte
  Future<void> adjustSpeedForContext(AudioContext context) async {
    final semanticContext = await _getSemanticContext(context);
    final thompsonTheme = await _getThompsonTheme(context);
    final userPrefs = await _getUserAudioPreferences();
    
    final optimalSpeed = _calculateOptimalSpeed(semanticContext, thompsonTheme, userPrefs);
    await _player.setSpeed(optimalSpeed);
    
    print('🏎️ Prophète Intelligent: Vitesse ajustée à $optimalSpeed selon le contexte');
  }

  /// 🧠 Méthode intelligente pour ajuster le volume selon le contexte
  Future<void> adjustVolumeForContext(AudioContext context) async {
    final semanticContext = await _getSemanticContext(context);
    final thompsonTheme = await _getThompsonTheme(context);
    final userPrefs = await _getUserAudioPreferences();
    
    final optimalVolume = _calculateOptimalVolume(semanticContext, thompsonTheme, userPrefs);
    await _player.setVolume(optimalVolume);
    
    print('🏎️ Prophète Intelligent: Volume ajusté à $optimalVolume selon le contexte');
  }

  /// 🧠 Récupère les préférences apprises pour un contexte
  Future<Map<String, dynamic>?> getLearnedPreferences(AudioContext context) async {
    try {
      final key = '${context.reference ?? 'default'}_${DateTime.now().day}';
      return _audioPrefsBox?.get(key);
    } catch (e) {
      return null;
    }
  }
}
