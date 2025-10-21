/// 🔄 ADAPTATEUR V2 POUR THEOLOGY GATE
/// 
/// Convertit les PlanPreset existants vers le format TheologyGateV2
/// en ajoutant automatiquement les tags et verseAnchors appropriés
library;

import '../models/plan_preset.dart' as Original;
import 'preset_theology_gate_v2.dart' as Theology;

class PresetTheologyAdapterV2 {
  
  /// 🔄 Convertit un PlanPreset existant vers le format TheologyGateV2
  static Theology.PlanPreset convertToTheologyFormat(Original.PlanPreset original) {
    final tags = _generateTags(original);
    final verseAnchors = _generateVerseAnchors(original);
    final focusScores = _calculateFocusScores(original, tags);
    
    return Theology.PlanPreset(
      id: original.slug,
      name: original.name,
      tags: tags,
      verseAnchors: verseAnchors,
      durationDays: original.durationDays,
      minutesPerDay: original.minutesPerDay,
      focusDoctrineOfChrist: focusScores['doctrine'],
      focusAuthorityOfBible: focusScores['authority'],
      focusGospelOfJesus: focusScores['gospel'],
    );
  }
  
  /// 🏷️ Génère les tags basés sur le contenu du preset
  static List<String> _generateTags(Original.PlanPreset original) {
    final tags = <String>[];
    final name = original.name.toLowerCase();
    final books = original.books.toLowerCase();
    
    // Tags basés sur le nom
    if (name.contains('évangiles') || name.contains('jésus') || name.contains('christ')) {
      tags.addAll(['christology', 'christ', 'gospel', 'jesus']);
    }
    
    if (name.contains('nouveau testament') || name.contains('nt')) {
      tags.addAll(['gospel', 'christology', 'new-testament']);
    }
    
    if (name.contains('ancien testament') || name.contains('at')) {
      tags.addAll(['old-testament', 'scripture', 'law', 'prophets']);
    }
    
    if (name.contains('bible complète') || name.contains('toute la bible')) {
      tags.addAll(['scripture', 'sola-scriptura', 'complete-bible']);
    }
    
    if (name.contains('psaumes') || name.contains('psalm')) {
      tags.addAll(['psalms', 'worship', 'prayer', 'ps119']);
    }
    
    if (name.contains('proverbes') || name.contains('proverb')) {
      tags.addAll(['wisdom', 'proverbs', 'scripture']);
    }
    
    if (name.contains('romains') || name.contains('romans')) {
      tags.addAll(['gospel', 'justification', 'grace', 'romains']);
    }
    
    if (name.contains('galates') || name.contains('galatians')) {
      tags.addAll(['gospel', 'grace', 'galates', 'justification']);
    }
    
    if (name.contains('jean') || name.contains('john')) {
      tags.addAll(['christology', 'jean', 'incarnation', 'deity']);
    }
    
    if (name.contains('colossiens') || name.contains('colossians')) {
      tags.addAll(['christology', 'colossiens', 'deity', 'incarnation']);
    }
    
    if (name.contains('hébreux') || name.contains('hebrews')) {
      tags.addAll(['christology', 'hebrews', 'priesthood', 'sacrifice']);
    }
    
    // Tags basés sur les livres
    if (books.contains('jean') || books.contains('john')) {
      tags.addAll(['christology', 'jean', 'incarnation']);
    }
    
    if (books.contains('matthieu') || books.contains('matthew')) {
      tags.addAll(['gospel', 'matthieu', 'kingdom']);
    }
    
    if (books.contains('marc') || books.contains('mark')) {
      tags.addAll(['gospel', 'marc', 'servant']);
    }
    
    if (books.contains('luc') || books.contains('luke')) {
      tags.addAll(['gospel', 'luc', 'humanity']);
    }
    
    if (books.contains('romains') || books.contains('romans')) {
      tags.addAll(['gospel', 'romains', 'justification', 'grace']);
    }
    
    if (books.contains('galates') || books.contains('galatians')) {
      tags.addAll(['gospel', 'galates', 'grace', 'freedom']);
    }
    
    if (books.contains('éphésiens') || books.contains('ephesians')) {
      tags.addAll(['gospel', 'ephesians', 'church', 'unity']);
    }
    
    if (books.contains('philippiens') || books.contains('philippians')) {
      tags.addAll(['gospel', 'philippians', 'joy', 'christology']);
    }
    
    if (books.contains('colossiens') || books.contains('colossians')) {
      tags.addAll(['christology', 'colossians', 'deity', 'supremacy']);
    }
    
    if (books.contains('hébreux') || books.contains('hebrews')) {
      tags.addAll(['christology', 'hebrews', 'priesthood', 'sacrifice']);
    }
    
    if (books.contains('psaumes') || books.contains('psalms')) {
      tags.addAll(['psalms', 'worship', 'prayer', 'ps119']);
    }
    
    if (books.contains('proverbes') || books.contains('proverbs')) {
      tags.addAll(['wisdom', 'proverbs', 'scripture']);
    }
    
    // Tags génériques
    tags.addAll(['scripture', 'bible']);
    
    // Supprimer les doublons et retourner
    return tags.toSet().toList();
  }
  
  /// 📖 Génère les références bibliques pertinentes
  static List<String> _generateVerseAnchors(Original.PlanPreset original) {
    final anchors = <String>[];
    final name = original.name.toLowerCase();
    final books = original.books.toLowerCase();
    
    // Références pour la doctrine de Christ
    if (name.contains('évangiles') || name.contains('jésus') || name.contains('christ') ||
        books.contains('jean') || books.contains('colossiens') || books.contains('hébreux')) {
      anchors.addAll(['1Jn 4:1-3', 'Jn 1:1-14', 'Col 1:15-20', 'Heb 1:1-3']);
    }
    
    // Références pour l'autorité de la Bible
    if (name.contains('bible complète') || name.contains('toute la bible') ||
        name.contains('psaumes') || books.contains('psaumes')) {
      anchors.addAll(['2Tm 3:16', 'Ap 22:18-19', 'Ps 119:11', 'Ps 119:105']);
    }
    
    // Références pour l'évangile
    if (name.contains('romains') || name.contains('galates') ||
        books.contains('romains') || books.contains('galates')) {
      anchors.addAll(['Ga 1:6-9', 'Rom 3:21-26', '1Co 15:1-4', 'Eph 2:8-9']);
    }
    
    // Références génériques
    anchors.addAll(['2Tm 3:16', 'Ap 22:18-19']);
    
    // Supprimer les doublons et retourner
    return anchors.toSet().toList();
  }
  
  /// 📊 Calcule les scores de focus pour chaque critère
  static Map<String, double> _calculateFocusScores(Original.PlanPreset original, List<String> tags) {
    final name = original.name.toLowerCase();
    final books = original.books.toLowerCase();
    
    // Score pour la doctrine de Christ
    double doctrineScore = 0.0;
    if (name.contains('évangiles') || name.contains('jésus') || name.contains('christ')) {
      doctrineScore += 0.4;
    }
    if (books.contains('jean') || books.contains('colossiens') || books.contains('hébreux')) {
      doctrineScore += 0.3;
    }
    if (tags.contains('christology') || tags.contains('incarnation') || tags.contains('deity')) {
      doctrineScore += 0.3;
    }
    
    // Score pour l'autorité de la Bible
    double authorityScore = 0.0;
    if (name.contains('bible complète') || name.contains('toute la bible')) {
      authorityScore += 0.5;
    }
    if (books.contains('psaumes') || name.contains('psaumes')) {
      authorityScore += 0.2;
    }
    if (tags.contains('scripture') || tags.contains('sola-scriptura')) {
      authorityScore += 0.3;
    }
    
    // Score pour l'évangile
    double gospelScore = 0.0;
    if (name.contains('romains') || name.contains('galates') || name.contains('évangile')) {
      gospelScore += 0.4;
    }
    if (books.contains('romains') || books.contains('galates')) {
      gospelScore += 0.3;
    }
    if (tags.contains('gospel') || tags.contains('grace') || tags.contains('justification')) {
      gospelScore += 0.3;
    }
    
    return {
      'doctrine': doctrineScore.clamp(0.0, 1.0),
      'authority': authorityScore.clamp(0.0, 1.0),
      'gospel': gospelScore.clamp(0.0, 1.0),
    };
  }
  
  /// 🔄 Convertit une liste de presets
  static List<Theology.PlanPreset> convertList(List<Original.PlanPreset> originals) {
    return originals.map((preset) => convertToTheologyFormat(preset)).toList();
  }
}
