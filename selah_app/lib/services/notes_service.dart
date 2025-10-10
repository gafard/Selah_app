import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'semantic_passage_boundary_service.dart';
import 'thompson_plan_service.dart';
import 'bible_context_service.dart';

/// 🔧 PASTEUR - Note avec contexte sémantique
class Note {
  final String id;
  final String passageId;
  final String text;
  final int startOffset;
  final int endOffset;
  final DateTime createdAt;
  final String? verseReference;
  final Map<String, dynamic>? semanticContext;
  final String? thompsonTheme;
  final String? emotionalTone;
  final double? spiritualDepth;

  Note({
    required this.id,
    required this.passageId,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    this.verseReference,
    this.semanticContext,
    this.thompsonTheme,
    this.emotionalTone,
    this.spiritualDepth,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'passageId': passageId,
    'text': text,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'createdAt': createdAt.toIso8601String(),
    'verseReference': verseReference,
    'semanticContext': semanticContext,
    'thompsonTheme': thompsonTheme,
    'emotionalTone': emotionalTone,
    'spiritualDepth': spiritualDepth,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    passageId: json['passageId'],
    text: json['text'],
    startOffset: json['startOffset'],
    endOffset: json['endOffset'],
    createdAt: DateTime.parse(json['createdAt']),
    verseReference: json['verseReference'],
    semanticContext: json['semanticContext'] != null 
        ? Map<String, dynamic>.from(json['semanticContext']) 
        : null,
    thompsonTheme: json['thompsonTheme'],
    emotionalTone: json['emotionalTone'],
    spiritualDepth: json['spiritualDepth']?.toDouble(),
  );
}

/// 🔧 PASTEUR - Service de notes avec contexte sémantique
/// 
/// Niveau : Pasteur (Utilité) - Service utilitaire pour la gestion des notes
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (contexte sémantique)
/// 🔥 Priorité 2: bible_context_service.dart (contexte biblique)
/// 🔥 Priorité 3: thompson_plan_service.dart (thèmes spirituels)
/// 🎯 Thompson: Enrichit les notes avec thèmes spirituels
class NotesService {
  static const String _notesKey = 'user_notes';
  static Box? _analysisBox;
  
  /// 🧠 Initialise le service avec analyse sémantique
  static Future<void> init() async {
    try {
      _analysisBox = await Hive.openBox('notes_analysis');
      print('🚲 Pasteur Intelligent: Service de notes initialisé');
    } catch (e) {
      print('⚠️ Erreur initialisation notes: $e');
    }
  }

  Future<List<Note>> getNotesForPassage(String passageId) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .where((note) => note.passageId == passageId)
        .toList();
  }
  
  /// 🧠 Sauvegarde une note avec analyse sémantique intelligente
  Future<void> saveNote(Note note) async {
    try {
      // Initialiser la box d'analyse si nécessaire
      if (_analysisBox == null) {
        await init();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser la note si pas déjà fait
      Note enrichedNote = note;
      if (note.semanticContext == null || note.thompsonTheme == null) {
        enrichedNote = await _enrichNoteWithContext(note);
      }
      
      // Remove existing note with same ID if it exists
      notesJson.removeWhere((json) {
        final existingNote = Note.fromJson(jsonDecode(json));
        return existingNote.id == note.id;
      });
      
      // Add new enriched note
      notesJson.add(jsonEncode(enrichedNote.toJson()));
      
      await prefs.setStringList(_notesKey, notesJson);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Sauvegarder l'analyse
      await _saveNoteAnalysis(enrichedNote.id, enrichedNote);
      
      print('🚲 Pasteur Intelligent: Note sauvegardée avec contexte sémantique: ${note.id}');
    } catch (e) {
      print('❌ Erreur sauvegarde note: $e');
    }
  }

  /// 🧠 Enrichit une note avec le contexte sémantique
  Future<Note> _enrichNoteWithContext(Note note) async {
    try {
      // 🔥 PRIORITÉ 1: Récupérer le contexte sémantique FALCON X
      final semanticContext = await _getSemanticContext(note.passageId, note.verseReference);
      
      // 🔥 PRIORITÉ 2: Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(note.passageId, note.verseReference);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser le contenu de la note
      final emotionalTone = _analyzeEmotionalTone(note.text);
      final spiritualDepth = _calculateSpiritualDepth(note.text, semanticContext, thompsonTheme);
      
      return Note(
        id: note.id,
        passageId: note.passageId,
        text: note.text,
        startOffset: note.startOffset,
        endOffset: note.endOffset,
        createdAt: note.createdAt,
        verseReference: note.verseReference,
        semanticContext: semanticContext,
        thompsonTheme: thompsonTheme,
        emotionalTone: emotionalTone,
        spiritualDepth: spiritualDepth,
      );
    } catch (e) {
      print('⚠️ Erreur enrichissement note: $e');
      return note;
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le contexte sémantique FALCON X
  Future<Map<String, dynamic>?> _getSemanticContext(String passageId, String? verseReference) async {
    try {
      if (verseReference == null) return null;
      
      // Extraire livre et chapitre de la référence
      final parts = verseReference.split(' ');
      if (parts.length >= 2) {
        final book = parts[0];
        final chapter = int.tryParse(parts[1]);
        if (chapter != null) {
          final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
          if (unit != null) {
            return {
              'unit_name': unit.name,
              'priority': unit.priority.name,
              'theme': unit.theme,
              'liturgical_context': unit.liturgicalContext,
              'emotional_tones': unit.emotionalTones,
              'annotation': unit.annotation,
            };
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Récupère le thème Thompson
  Future<String?> _getThompsonTheme(String passageId, String? verseReference) async {
    try {
      if (verseReference == null) return null;
      
      // TODO: Intégrer avec thompson_plan_service pour récupérer le thème
      // Mapping basique pour l'instant
      final book = verseReference.split(' ').first;
      
      if (book.contains('Psaumes')) {
        return 'Vie de prière — Souffle spirituel';
      } else if (book.contains('Jean')) {
        return 'Exigence spirituelle — Transformation profonde';
      } else if (book.contains('Matthieu')) {
        return 'Ne vous inquiétez pas — Apprentissages de Mt 6';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🧠 Analyse le ton émotionnel de la note
  String _analyzeEmotionalTone(String text) {
    try {
      final lowerText = text.toLowerCase();
      
      if (lowerText.contains('joie') || lowerText.contains('heureux') || lowerText.contains('béni')) {
        return 'joyful';
      } else if (lowerText.contains('paix') || lowerText.contains('calme') || lowerText.contains('sérénité')) {
        return 'peaceful';
      } else if (lowerText.contains('gratitude') || lowerText.contains('merci') || lowerText.contains('reconnaissant')) {
        return 'grateful';
      } else if (lowerText.contains('espoir') || lowerText.contains('confiance') || lowerText.contains('foi')) {
        return 'hopeful';
      } else if (lowerText.contains('réflexion') || lowerText.contains('méditation') || lowerText.contains('pensée')) {
        return 'contemplative';
      } else if (lowerText.contains('inquiétude') || lowerText.contains('souci') || lowerText.contains('anxiété')) {
        return 'concerned';
      }
      
      return 'neutral';
    } catch (e) {
      return 'neutral';
    }
  }

  /// 🧠 Calcule la profondeur spirituelle de la note
  double _calculateSpiritualDepth(String text, Map<String, dynamic>? semantic, String? thompson) {
    try {
      double depth = 0.0;
      
      // Bonus pour la longueur de la note
      final textLength = text.length;
      if (textLength > 200) {
        depth += 0.3;
      } else if (textLength > 100) depth += 0.2;
      else if (textLength > 50) depth += 0.1;
      
      // Bonus pour les termes spirituels
      final spiritualTerms = ['Dieu', 'Jésus', 'Christ', 'Esprit', 'prière', 'foi', 'amour', 'grâce', 'saint'];
      int spiritualTermCount = 0;
      for (final term in spiritualTerms) {
        spiritualTermCount += text.toLowerCase().split(term.toLowerCase()).length - 1;
      }
      
      if (spiritualTermCount > 3) {
        depth += 0.3;
      } else if (spiritualTermCount > 1) depth += 0.2;
      else if (spiritualTermCount > 0) depth += 0.1;
      
      // Bonus pour les questions spirituelles
      if (text.contains('?')) depth += 0.2;
      
      // Bonus pour les références personnelles
      if (text.toLowerCase().contains('je') || text.toLowerCase().contains('moi')) depth += 0.2;
      
      // Bonus selon le contexte sémantique
      if (semantic != null) {
        final priority = semantic['priority'] as String?;
        if (priority == 'critical') {
          depth += 0.2;
        } else if (priority == 'high') depth += 0.1;
      }
      
      return depth.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// 🧠 Sauvegarde l'analyse de la note
  Future<void> _saveNoteAnalysis(String noteId, Note note) async {
    try {
      final analysis = {
        'semantic_context': note.semanticContext,
        'thompson_theme': note.thompsonTheme,
        'emotional_tone': note.emotionalTone,
        'spiritual_depth': note.spiritualDepth,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _analysisBox?.put('analysis_$noteId', analysis);
    } catch (e) {
      print('⚠️ Erreur sauvegarde analyse note: $e');
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    notesJson.removeWhere((json) {
      final note = Note.fromJson(jsonDecode(json));
      return note.id == noteId;
    });
    
    await prefs.setStringList(_notesKey, notesJson);
  }
  
  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .toList();
  }

  /// 🧠 Récupère l'analyse d'une note
  Future<Map<String, dynamic>?> getNoteAnalysis(String noteId) async {
    try {
      if (_analysisBox == null) {
        await init();
      }
      return _analysisBox?.get('analysis_$noteId');
    } catch (e) {
      print('⚠️ Erreur récupération analyse note: $e');
      return null;
    }
  }

  /// 🧠 Récupère les tendances des notes
  Future<Map<String, dynamic>> getNotesTrends() async {
    try {
      final notes = await getAllNotes();
      if (notes.isEmpty) return {};

      final emotionalTones = <String, int>{};
      final spiritualDepths = <double>[];
      final thompsonThemes = <String, int>{};
      final semanticPriorities = <String, int>{};

      for (final note in notes) {
        // Analyser les tons émotionnels
        final tone = note.emotionalTone;
        if (tone != null) {
          emotionalTones[tone] = (emotionalTones[tone] ?? 0) + 1;
        }

        // Analyser les profondeurs spirituelles
        final depth = note.spiritualDepth;
        if (depth != null) {
          spiritualDepths.add(depth);
        }

        // Analyser les thèmes Thompson
        final thompson = note.thompsonTheme;
        if (thompson != null) {
          thompsonThemes[thompson] = (thompsonThemes[thompson] ?? 0) + 1;
        }

        // Analyser les priorités sémantiques
        final semantic = note.semanticContext;
        if (semantic != null) {
          final priority = semantic['priority'] as String?;
          if (priority != null) {
            semanticPriorities[priority] = (semanticPriorities[priority] ?? 0) + 1;
          }
        }
      }

      return {
        'total_notes': notes.length,
        'emotional_tone_distribution': emotionalTones,
        'average_spiritual_depth': spiritualDepths.isNotEmpty 
            ? spiritualDepths.reduce((a, b) => a + b) / spiritualDepths.length 
            : 0.0,
        'thompson_themes': thompsonThemes,
        'semantic_priorities': semanticPriorities,
        'most_common_emotion': emotionalTones.isNotEmpty 
            ? emotionalTones.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'neutral',
        'most_common_thompson_theme': thompsonThemes.isNotEmpty 
            ? thompsonThemes.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'aucun',
      };
    } catch (e) {
      print('⚠️ Erreur tendances notes: $e');
      return {};
    }
  }

  /// 🧠 Récupère les suggestions intelligentes pour les notes
  Future<List<Map<String, dynamic>>> getIntelligentSuggestions() async {
    try {
      final trends = await getNotesTrends();
      final suggestions = <Map<String, dynamic>>[];

      // Suggestion basée sur le ton émotionnel
      final mostCommonEmotion = trends['most_common_emotion'] as String?;
      if (mostCommonEmotion != null && mostCommonEmotion != 'neutral') {
        suggestions.add({
          'type': 'emotional_balance',
          'title': 'Équilibre émotionnel',
          'message': 'Vos notes sont principalement $mostCommonEmotion. Explorez d\'autres aspects émotionnels.',
          'priority': 'medium',
        });
      }

      // Suggestion basée sur la profondeur spirituelle
      final avgDepth = trends['average_spiritual_depth'] as double? ?? 0.0;
      if (avgDepth < 0.3) {
        suggestions.add({
          'type': 'spiritual_depth',
          'title': 'Profondeur spirituelle',
          'message': 'Vos notes pourraient être plus approfondies. Ajoutez plus de réflexion spirituelle.',
          'priority': 'high',
        });
      }

      // Suggestion basée sur les thèmes Thompson
      final thompsonThemes = trends['thompson_themes'] as Map<String, dynamic>? ?? {};
      if (thompsonThemes.isEmpty) {
        suggestions.add({
          'type': 'thompson_integration',
          'title': 'Intégration Thompson',
          'message': 'Enrichissez vos notes avec les thèmes spirituels de Thompson.',
          'priority': 'medium',
        });
      }

      return suggestions;
    } catch (e) {
      print('⚠️ Erreur suggestions intelligentes: $e');
      return [];
    }
  }

  /// 🧠 Analyse la progression des notes
  Future<Map<String, dynamic>> getNotesProgress() async {
    try {
      final notes = await getAllNotes();
      if (notes.length < 2) return {};

      // Trier par date
      notes.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final progressData = <String, dynamic>{};
      final depths = <double>[];
      final emotionalIntensities = <double>[];

      for (final note in notes) {
        final depth = note.spiritualDepth;
        if (depth != null) depths.add(depth);
        
        // Calculer l'intensité émotionnelle basique
        final tone = note.emotionalTone;
        if (tone != null && tone != 'neutral') {
          emotionalIntensities.add(1.0);
        } else {
          emotionalIntensities.add(0.0);
        }
      }

      if (depths.isNotEmpty) {
        // Calculer la tendance de progression
        final firstHalf = depths.take(depths.length ~/ 2).toList();
        final secondHalf = depths.skip(depths.length ~/ 2).toList();
        
        final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
        
        progressData['depth_progression'] = secondAvg - firstAvg;
        progressData['current_depth'] = depths.last;
        progressData['average_depth'] = depths.reduce((a, b) => a + b) / depths.length;
      }

      if (emotionalIntensities.isNotEmpty) {
        progressData['current_emotional_intensity'] = emotionalIntensities.last;
        progressData['average_emotional_intensity'] = emotionalIntensities.reduce((a, b) => a + b) / emotionalIntensities.length;
      }

      return progressData;
    } catch (e) {
      print('⚠️ Erreur analyse progression notes: $e');
      return {};
    }
  }

  /// 🧠 Retourne les statistiques du service intelligent
  static Map<String, dynamic> getIntelligentStats() {
    return {
      'service_type': 'Pasteur Intelligent',
      'features': [
        'Contexte sémantique FALCON X',
        'Thèmes Thompson enrichis',
        'Analyse émotionnelle des notes',
        'Calcul de profondeur spirituelle',
        'Tendances des notes',
        'Suggestions intelligentes',
        'Progression des notes',
      ],
      'integrations': [
        'semantic_passage_boundary_service.dart (FALCON X)',
        'bible_context_service.dart (Contexte biblique)',
        'thompson_plan_service.dart (Thompson)',
      ],
    };
  }
}
