import 'package:flutter/material.dart';
import '../models/plan_preset.dart';

/// -------- EXPLANATIONS DTO --------
class PresetExplanation {
  final String slug;
  final String name;
  final double totalScore;
  final List<ReasonItem> reasons;

  PresetExplanation({
    required this.slug,
    required this.name,
    required this.totalScore,
    required this.reasons,
  });
}

class ReasonItem {
  final String label;   // ex: "Objectif prioritaire (prayer_life)"
  final double weight;  // ex: +0.45
  final String detail;  // ex: "Le thème correspond à l'objectif Mieux prier"

  ReasonItem({required this.label, required this.weight, required this.detail});
}

/// Entrée du journal spirituel
class SpiritualJournalEntry {
  final DateTime date;
  final String emotion;
  final String planSlug;
  final int dayIndex;
  final String reflection;
  final double satisfaction; // 0.0 à 1.0

  SpiritualJournalEntry({
    required this.date,
    required this.emotion,
    required this.planSlug,
    required this.dayIndex,
    required this.reflection,
    required this.satisfaction,
  });
}

/// Service intelligent pour générer des presets localement
/// Basé sur une grande base de données des différents livres d'études
class IntelligentLocalPresetGenerator {
  
  /// Adaptation émotionnelle automatique par profil utilisateur
  static const Map<String, List<String>> _emotionalStates = {
    'Nouveau converti': ['joy', 'anticipation', 'foundation'],
    'Rétrograde': ['repentance', 'hope', 'restoration'],
    'Fidèle pas si régulier': ['encouragement', 'peace', 'renewal'],
    'Fidèle régulier': ['discipline', 'growth', 'perseverance'],
    'Serviteur/leader': ['responsibility', 'wisdom', 'vision'],
  };

  /// Historique des plans pour éviter les redondances
  static final List<String> _userPlanHistory = [];

  /// Feedback utilisateur pour apprentissage
  static final Map<String, double> _userFeedback = {};

  /// Journal spirituel des ressentis quotidiens
  static final List<SpiritualJournalEntry> _spiritualJournal = [];

  /// Base de données complète des livres bibliques avec leurs caractéristiques détaillées (pour usage futur)
  static const Map<String, Map<String, dynamic>> _bibleKnowledgeBase = {
    // ANCIEN TESTAMENT - PENTATEUQUE
    'Genèse': {
      'category': 'Pentateuque',
      'themes': ['création', 'promesses', 'alliance', 'foi', 'origines'],
      'difficulty': 'beginner',
      'duration': [14, 21, 30, 50],
      'keyVerses': ['1:1', '12:1-3', '15:6', '50:20'],
      'studyPoints': ['Origines du monde', 'Promesses divines', 'Foi d\'Abraham', 'Providence divine'],
      'recommendedFor': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier'],
      'emotionalTone': 'foundational'
    },
    'Exode': {
      'category': 'Pentateuque',
      'themes': ['délivrance', 'alliance', 'loi', 'présence', 'libération'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40],
      'keyVerses': ['3:14', '12:13', '20:1-17', '33:14'],
      'studyPoints': ['Délivrance divine', 'Alliance sinaïtique', 'Dix Commandements', 'Présence divine'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'powerful'
    },
    'Lévitique': {
      'category': 'Pentateuque',
      'themes': ['sainteté', 'sacrifices', 'purification', 'adoration'],
      'difficulty': 'advanced',
      'duration': [30, 40, 60],
      'keyVerses': ['11:44', '17:11', '19:2', '20:26'],
      'studyPoints': ['Sainteté divine', 'Système sacrificiel', 'Lois de pureté', 'Adoration'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'sacred'
    },
    'Nombres': {
      'category': 'Pentateuque',
      'themes': ['pèlerinage', 'obéissance', 'providence', 'direction'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40],
      'keyVerses': ['6:24-26', '14:18', '23:19', '32:23'],
      'studyPoints': ['Pèlerinage spirituel', 'Obéissance', 'Providence divine', 'Direction divine'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'journey'
    },
    'Deutéronome': {
      'category': 'Pentateuque',
      'themes': ['alliance', 'obéissance', 'bénédictions', 'choix'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40],
      'keyVerses': ['4:29', '6:4-5', '8:2', '30:19-20'],
      'studyPoints': ['Renouvellement d\'alliance', 'Amour de Dieu', 'Épreuves', 'Choix de vie'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'covenant'
    },

    // ANCIEN TESTAMENT - LIVRES HISTORIQUES
    'Josué': {
      'category': 'Historiques',
      'themes': ['conquête', 'promesse', 'fidélité', 'victoire'],
      'difficulty': 'beginner',
      'duration': [14, 21, 24],
      'keyVerses': ['1:8-9', '24:15'],
      'studyPoints': ['Fidélité divine', 'Promesses accomplies', 'Conquête spirituelle'],
      'recommendedFor': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier'],
      'emotionalTone': 'victorious'
    },
    'Juges': {
      'category': 'Historiques',
      'themes': ['cycles', 'repentance', 'délivrance', 'fidélité'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['2:18', '21:25'],
      'studyPoints': ['Cycles de péché', 'Grâce divine', 'Besoin d\'un roi'],
      'recommendedFor': ['Fidèle régulier'],
      'emotionalTone': 'cyclical'
    },
    'Ruth': {
      'category': 'Historiques',
      'themes': ['loyalty', 'providence', 'rédemption', 'amour'],
      'difficulty': 'beginner',
      'duration': [4, 7, 14],
      'keyVerses': ['1:16-17', '4:14'],
      'studyPoints': ['Loyauté', 'Providence divine', 'Rédemption', 'Amour inconditionnel'],
      'recommendedFor': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier'],
      'emotionalTone': 'loving'
    },
    '1 Samuel': {
      'category': 'Historiques',
      'themes': ['royaume', 'onction', 'humilité', 'obéissance'],
      'difficulty': 'intermediate',
      'duration': [21, 31],
      'keyVerses': ['2:3', '15:22', '16:7'],
      'studyPoints': ['Établissement de la royauté', 'Importance du cœur', 'Obéissance vs sacrifice'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'royal'
    },
    '2 Samuel': {
      'category': 'Historiques',
      'themes': ['royaume', 'repentance', 'grâce', 'alliance'],
      'difficulty': 'intermediate',
      'duration': [21, 31],
      'keyVerses': ['7:16', '12:13', '22:2'],
      'studyPoints': ['Alliance davidique', 'Repentance', 'Grâce divine', 'Psaumes de David'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'covenant'
    },
    '1 Rois': {
      'category': 'Historiques',
      'themes': ['royaume', 'sagesse', 'idolâtrie', 'prophètes'],
      'difficulty': 'intermediate',
      'duration': [21, 31],
      'keyVerses': ['3:9', '8:23', '11:4'],
      'studyPoints': ['Sagesse de Salomon', 'Temple de Jérusalem', 'Division du royaume'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'wise'
    },
    '2 Rois': {
      'category': 'Historiques',
      'themes': ['chute', 'jugement', 'espérance', 'restauration'],
      'difficulty': 'intermediate',
      'duration': [21, 31],
      'keyVerses': ['17:13', '25:21'],
      'studyPoints': ['Chute d\'Israël', 'Chute de Juda', 'Exil', 'Espérance de restauration'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'judgment'
    },

    // LIVRES POÉTIQUES ET DE SAGESSE
    'Psaumes': {
      'category': 'Poésie',
      'themes': ['adoration', 'lamentation', 'confiance', 'louange', 'prière'],
      'difficulty': 'beginner',
      'duration': [30, 40, 60, 90, 150],
      'keyVerses': ['23:1', '46:10', '91:1-2', '139:14', '150:6'],
      'studyPoints': ['Adoration', 'Confiance en Dieu', 'Protection divine', 'Louange', 'Prière'],
      'recommendedFor': ['Nouveau converti', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'worshipful'
    },
    'Proverbes': {
      'category': 'Sagesse',
      'themes': ['sagesse', 'conduite', 'relations', 'prudence', 'caractère'],
      'difficulty': 'beginner',
      'duration': [21, 31, 40],
      'keyVerses': ['1:7', '3:5-6', '9:10', '31:10-31'],
      'studyPoints': ['Sagesse pratique', 'Conduite quotidienne', 'Relations', 'Femme vertueuse'],
      'recommendedFor': ['Nouveau converti', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'wise'
    },
    'Ecclésiaste': {
      'category': 'Sagesse',
      'themes': ['vanité', 'sagesse', 'temporalité', 'finalité'],
      'difficulty': 'advanced',
      'duration': [14, 21, 30],
      'keyVerses': ['1:2', '3:1', '12:13', '12:14'],
      'studyPoints': ['Vanité des choses', 'Cycles de vie', 'Crainte de Dieu', 'Jugement final'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'contemplative'
    },
    'Cantique des Cantiques': {
      'category': 'Poésie',
      'themes': ['amour', 'relation', 'intimité', 'union'],
      'difficulty': 'advanced',
      'duration': [8, 14, 21],
      'keyVerses': ['2:16', '8:6-7'],
      'studyPoints': ['Amour conjugal', 'Intimité', 'Relation avec Dieu', 'Union spirituelle'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'intimate'
    },
    'Job': {
      'category': 'Sagesse',
      'themes': ['souffrance', 'justice', 'sagesse', 'foi'],
      'difficulty': 'advanced',
      'duration': [21, 30, 42],
      'keyVerses': ['1:21', '2:10', '42:5-6'],
      'studyPoints': ['Souffrance et justice', 'Souveraineté divine', 'Foi dans l\'épreuve', 'Repentance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'suffering'
    },

    // PROPHÈTES MAJEURS
    'Ésaïe': {
      'category': 'Prophètes majeurs',
      'themes': ['salut', 'messie', 'consolation', 'sainteté'],
      'difficulty': 'advanced',
      'duration': [30, 40, 66],
      'keyVerses': ['6:3', '7:14', '9:6', '53:5'],
      'studyPoints': ['Sainteté divine', 'Promesse messianique', 'Serviteur souffrant', 'Consolation'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'prophetic'
    },
    'Jérémie': {
      'category': 'Prophètes majeurs',
      'themes': ['jugement', 'repentance', 'nouvelle alliance', 'espérance'],
      'difficulty': 'advanced',
      'duration': [30, 40, 52],
      'keyVerses': ['1:5', '17:9', '29:11', '31:33'],
      'studyPoints': ['Appel prophétique', 'Nouvelle alliance', 'Espérance future', 'Repentance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'urgent'
    },
    'Ézéchiel': {
      'category': 'Prophètes majeurs',
      'themes': ['gloire', 'jugement', 'restauration', 'esprit'],
      'difficulty': 'advanced',
      'duration': [30, 40, 48],
      'keyVerses': ['1:28', '36:26', '37:5'],
      'studyPoints': ['Gloire de Dieu', 'Nouveau cœur', 'Résurrection', 'Restauration'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'visionary'
    },
    'Daniel': {
      'category': 'Prophètes majeurs',
      'themes': ['fidélité', 'prophétie', 'royaume', 'persévérance'],
      'difficulty': 'intermediate',
      'duration': [12, 21],
      'keyVerses': ['3:17-18', '6:23', '7:13-14'],
      'studyPoints': ['Fidélité dans l\'épreuve', 'Prophéties eschatologiques', 'Royaume éternel'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'faithful'
    },

    // NOUVEAU TESTAMENT - ÉVANGILES
    'Matthieu': {
      'category': 'Évangiles',
      'themes': ['royaume', 'enseignement', 'accomplissement', 'mission'],
      'difficulty': 'beginner',
      'duration': [21, 30, 40, 60],
      'keyVerses': ['4:17', '5:3-12', '6:33', '28:19-20'],
      'studyPoints': ['Royaume des cieux', 'Sermon sur la montagne', 'Accomplissement prophétique', 'Mission'],
      'recommendedFor': ['Nouveau converti', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'kingdom'
    },
    'Marc': {
      'category': 'Évangiles',
      'themes': ['action', 'serviteur', 'miraculeux', 'urgence'],
      'difficulty': 'beginner',
      'duration': [14, 21, 30],
      'keyVerses': ['1:15', '8:34', '10:45', '16:15'],
      'studyPoints': ['Action de Jésus', 'Serviteur souffrant', 'Miracles', 'Urgence du message'],
      'recommendedFor': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier'],
      'emotionalTone': 'urgent'
    },
    'Luc': {
      'category': 'Évangiles',
      'themes': ['salut', 'compassion', 'prière', 'universel'],
      'difficulty': 'beginner',
      'duration': [21, 30, 40, 60],
      'keyVerses': ['2:11', '4:18-19', '15:11-32', '19:10'],
      'studyPoints': ['Salut universel', 'Compassion divine', 'Vie de prière', 'Grâce'],
      'recommendedFor': ['Nouveau converti', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'compassionate'
    },
    'Jean': {
      'category': 'Évangiles',
      'themes': ['vie', 'vérité', 'amour', 'éternité'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40, 60],
      'keyVerses': ['1:1', '3:16', '14:6', '20:31'],
      'studyPoints': ['Divinité de Christ', 'Vie éternelle', 'Vérité absolue', 'Amour divin'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'eternal'
    },

    // ACTES ET ÉPÎTRES PAULINIENNES
    'Actes': {
      'category': 'Histoire',
      'themes': ['mission', 'église', 'esprit', 'évangélisation'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40, 60],
      'keyVerses': ['1:8', '2:42-47', '4:12', '9:15'],
      'studyPoints': ['Naissance de l\'Église', 'Puissance du Saint-Esprit', 'Mission universelle', 'Conversion de Paul'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'missionary'
    },
    'Romains': {
      'category': 'Épîtres pauliniennes',
      'themes': ['justification', 'grâce', 'foi', 'élection'],
      'difficulty': 'advanced',
      'duration': [30, 40, 60],
      'keyVerses': ['1:16', '3:23', '5:8', '8:28'],
      'studyPoints': ['Justification par la foi', 'Grâce divine', 'Prédestination', 'Espérance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'theological'
    },
    '1 Corinthiens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['unité', 'amour', 'résurrection', 'liberté'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40],
      'keyVerses': ['13:4-8', '15:3-4', '15:55', '16:14'],
      'studyPoints': ['Unité dans l\'Église', 'Amour chrétien', 'Résurrection', 'Liberté en Christ'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'corrective'
    },
    '2 Corinthiens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['souffrance', 'grâce', 'ministère', 'faiblesse'],
      'difficulty': 'intermediate',
      'duration': [21, 30],
      'keyVerses': ['3:18', '4:16-18', '5:17', '12:9'],
      'studyPoints': ['Ministère de la réconciliation', 'Grâce suffisante', 'Transformation', 'Faiblesse et puissance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'vulnerable'
    },
    'Galates': {
      'category': 'Épîtres pauliniennes',
      'themes': ['liberté', 'grâce', 'loi', 'fruits'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['2:20', '5:1', '5:22-23', '6:14'],
      'studyPoints': ['Liberté en Christ', 'Justification par la foi', 'Fruits de l\'Esprit', 'Croix de Christ'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'liberating'
    },
    'Éphésiens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['bénédictions', 'unité', 'armure', 'grâce'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40],
      'keyVerses': ['1:3', '2:8-9', '4:32', '6:10-18'],
      'studyPoints': ['Bénédictions spirituelles', 'Salut par grâce', 'Unité de l\'Église', 'Armure spirituelle'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'blessed'
    },
    'Philippiens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['joie', 'humilité', 'suffisance', 'contentement'],
      'difficulty': 'beginner',
      'duration': [14, 21, 30],
      'keyVerses': ['1:21', '2:5-11', '4:4', '4:13'],
      'studyPoints': ['Joie en Christ', 'Humilité de Jésus', 'Suffisance divine', 'Contentement'],
      'recommendedFor': ['Nouveau converti', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'joyful'
    },
    'Colossiens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['christ', 'plénitude', 'sagesse', 'vie'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['1:15-20', '2:6-7', '3:1-4', '3:23'],
      'studyPoints': ['Suprématie de Christ', 'Plénitude en Christ', 'Sagesse divine', 'Vie cachée en Christ'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'exalting'
    },
    '1 Thessaloniciens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['retour', 'sainteté', 'encouragement', 'espérance'],
      'difficulty': 'beginner',
      'duration': [14, 21],
      'keyVerses': ['4:13-18', '5:17', '5:23-24'],
      'studyPoints': ['Retour de Christ', 'Vie sainte', 'Prière continuelle', 'Sanctification'],
      'recommendedFor': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier'],
      'emotionalTone': 'expectant'
    },
    '2 Thessaloniciens': {
      'category': 'Épîtres pauliniennes',
      'themes': ['retour', 'apostasie', 'persévérance', 'ordre'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['2:3-4', '3:10', '3:13'],
      'studyPoints': ['Signes de la fin', 'Apostasie', 'Travail et foi', 'Persévérance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'warning'
    },
    '1 Timothée': {
      'category': 'Épîtres pastorales',
      'themes': ['leadership', 'doctrine', 'piété', 'service'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['3:15', '4:12', '6:6', '6:12'],
      'studyPoints': ['Qualifications pastorales', 'Saine doctrine', 'Piété', 'Bon combat'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'pastoral'
    },
    '2 Timothée': {
      'category': 'Épîtres pastorales',
      'themes': ['fidélité', 'persécution', 'héritage', 'persévérance'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['1:7', '2:2', '3:16-17', '4:7'],
      'studyPoints': ['Fidélité dans l\'épreuve', 'Transmission de la foi', 'Autorité de l\'Écriture', 'Fin de course'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'faithful'
    },
    'Tite': {
      'category': 'Épîtres pastorales',
      'themes': ['bonnes œuvres', 'doctrine', 'qualités', 'ordre'],
      'difficulty': 'intermediate',
      'duration': [8, 14],
      'keyVerses': ['2:11-14', '3:5', '3:8'],
      'studyPoints': ['Bonnes œuvres', 'Grâce qui enseigne', 'Régénération', 'Fruits de la foi'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'instructive'
    },
    'Philémon': {
      'category': 'Épîtres pauliniennes',
      'themes': ['réconciliation', 'grâce', 'fraternité', 'transformation'],
      'difficulty': 'beginner',
      'duration': [1, 3, 7],
      'keyVerses': ['15-16', '17'],
      'studyPoints': ['Réconciliation', 'Grâce transformatrice', 'Fraternité en Christ', 'Amour pratique'],
      'recommendedFor': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier'],
      'emotionalTone': 'reconciling'
    },

    // ÉPÎTRE AUX HÉBREUX
    'Hébreux': {
      'category': 'Épître générale',
      'themes': ['christ', 'sacrifice', 'foi', 'persévérance'],
      'difficulty': 'advanced',
      'duration': [21, 30, 40],
      'keyVerses': ['1:3', '4:12', '11:1', '12:1-2'],
      'studyPoints': ['Suprématie de Christ', 'Nouvelle alliance', 'Exemples de foi', 'Persévérance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'exhortative'
    },

    // ÉPÎTRES GÉNÉRALES
    'Jacques': {
      'category': 'Épîtres générales',
      'themes': ['foi', 'œuvres', 'sagesse', 'persévérance'],
      'difficulty': 'intermediate',
      'duration': [14, 21, 30],
      'keyVerses': ['1:2-4', '1:5', '2:17', '5:16'],
      'studyPoints': ['Foi et œuvres', 'Sagesse divine', 'Épreuves', 'Puissance de la prière'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'practical'
    },
    '1 Pierre': {
      'category': 'Épîtres générales',
      'themes': ['souffrance', 'espérance', 'élection', 'persévérance'],
      'difficulty': 'intermediate',
      'duration': [21, 30, 40],
      'keyVerses': ['1:3', '2:9', '4:12', '5:7'],
      'studyPoints': ['Espérance vivante', 'Sacerdoce royal', 'Souffrances', 'Humilité'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'encouraging'
    },
    '2 Pierre': {
      'category': 'Épîtres générales',
      'themes': ['croissance', 'prophétie', 'sainteté', 'vigilance'],
      'difficulty': 'intermediate',
      'duration': [14, 21],
      'keyVerses': ['1:5-8', '3:9', '3:18'],
      'studyPoints': ['Croissance spirituelle', 'Fiabilité de la prophétie', 'Patience de Dieu', 'Vigilance'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'warning'
    },
    '1 Jean': {
      'category': 'Épîtres générales',
      'themes': ['amour', 'vérité', 'communion', 'assurance'],
      'difficulty': 'intermediate',
      'duration': [14, 21, 30],
      'keyVerses': ['1:9', '3:16', '4:8', '5:13'],
      'studyPoints': ['Amour divin', 'Vérité et amour', 'Communion fraternelle', 'Assurance du salut'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'loving'
    },
    '2 Jean': {
      'category': 'Épîtres générales',
      'themes': ['vérité', 'amour', 'hospitalité', 'doctrine'],
      'difficulty': 'beginner',
      'duration': [1, 3, 7],
      'keyVerses': ['6', '9-10'],
      'studyPoints': ['Marche dans la vérité', 'Amour et obéissance', 'Hospitalité sélective', 'Saine doctrine'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'caring'
    },
    '3 Jean': {
      'category': 'Épîtres générales',
      'themes': ['hospitalité', 'vérité', 'imitation', 'bien'],
      'difficulty': 'beginner',
      'duration': [1, 3, 7],
      'keyVerses': ['8', '11'],
      'studyPoints': ['Hospitalité chrétienne', 'Marche dans la vérité', 'Imitation du bien', 'Service'],
      'recommendedFor': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'supportive'
    },
    'Jude': {
      'category': 'Épîtres générales',
      'themes': ['vigilance', 'apostasie', 'conservation', 'miséricorde'],
      'difficulty': 'intermediate',
      'duration': [1, 3, 7],
      'keyVerses': ['3', '24-25'],
      'studyPoints': ['Contre l\'apostasie', 'Conservation des saints', 'Miséricorde divine', 'Gloire éternelle'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'urgent'
    },

    // APOCALYPSE
    'Apocalypse': {
      'category': 'Prophétique',
      'themes': ['révélation', 'victoire', 'jugement', 'nouveau'],
      'difficulty': 'advanced',
      'duration': [21, 30, 40],
      'keyVerses': ['1:18', '3:20', '21:4', '22:20'],
      'studyPoints': ['Révélation de Christ', 'Victoire finale', 'Nouveau ciel et terre', 'Retour imminent'],
      'recommendedFor': ['Fidèle régulier', 'Serviteur/leader'],
      'emotionalTone': 'triumphant'
    }
  };

  /// Thèmes spirituels avec leurs caractéristiques détaillées
  static const Map<String, Map<String, dynamic>> _spiritualThemes = {
    'spiritual_growth': {
      'books': ['Philippiens', 'Colossiens', 'Éphésiens', 'Romains'],
      'duration': [21, 30, 40],
      'focus': 'Croissance spirituelle et maturité',
      'verses': ['Philippiens 1:6', 'Colossiens 2:6-7', 'Éphésiens 4:15'],
      'emotions': ['encouragement', 'growth', 'maturity'],
      'targetAudience': ['Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    },
    'prayer_life': {
      'books': ['Psaumes', 'Luc', 'Matthieu', '1 Thessaloniciens'],
      'duration': [21, 30, 40],
      'focus': 'Développement de la vie de prière',
      'verses': ['Matthieu 6:9-13', 'Luc 11:1-13', '1 Thessaloniciens 5:17'],
      'emotions': ['peace', 'communion', 'intimacy'],
      'targetAudience': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    },
    'wisdom_understanding': {
      'books': ['Proverbes', 'Jacques', 'Ecclésiaste', 'Job'],
      'duration': [21, 31, 40],
      'focus': 'Sagesse et discernement spirituel',
      'verses': ['Proverbes 1:7', 'Jacques 1:5', 'Ecclésiaste 12:13'],
      'emotions': ['wisdom', 'discernment', 'understanding'],
      'targetAudience': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    },
    'faith_foundation': {
      'books': ['Jean', 'Romains', 'Hébreux', 'Galates'],
      'duration': [21, 30, 40],
      'focus': 'Fondements de la foi chrétienne',
      'verses': ['Jean 3:16', 'Romains 10:17', 'Hébreux 11:1'],
      'emotions': ['foundation', 'assurance', 'confidence'],
      'targetAudience': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier']
    },
    'christian_character': {
      'books': ['Galates', 'Éphésiens', 'Colossiens', '1 Pierre'],
      'duration': [21, 30, 40],
      'focus': 'Développement du caractère chrétien',
      'verses': ['Galates 5:22-23', 'Éphésiens 4:32', '1 Pierre 2:9'],
      'emotions': ['transformation', 'character', 'holiness'],
      'targetAudience': ['Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    },
    'hope_encouragement': {
      'books': ['Romains', 'Philippiens', '1 Pierre', 'Apocalypse'],
      'duration': [21, 30, 40],
      'focus': 'Espérance et encouragement',
      'verses': ['Romains 8:28', 'Philippiens 4:13', '1 Pierre 1:3'],
      'emotions': ['hope', 'encouragement', 'comfort'],
      'targetAudience': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    },
    'forgiveness_healing': {
      'books': ['Matthieu', 'Luc', '1 Jean', 'Psaumes'],
      'duration': [21, 30, 40],
      'focus': 'Pardon et guérison spirituelle',
      'verses': ['Matthieu 6:14-15', 'Luc 15:11-32', '1 Jean 1:9'],
      'emotions': ['healing', 'forgiveness', 'restoration'],
      'targetAudience': ['Nouveau converti', 'Rétrogarde', 'Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    },
    'mission_evangelism': {
      'books': ['Actes', 'Matthieu', 'Marc', 'Luc'],
      'duration': [21, 30, 40],
      'focus': 'Mission et évangélisation',
      'verses': ['Matthieu 28:19-20', 'Actes 1:8', 'Marc 16:15'],
      'emotions': ['mission', 'urgency', 'compassion'],
      'targetAudience': ['Fidèle pas si régulier', 'Fidèle régulier', 'Serviteur/leader']
    }
  };

  /// Génère des presets intelligents basés sur le profil utilisateur
  static List<PlanPreset> generateIntelligentPresets(Map<String, dynamic>? userProfile) {
    final presets = <PlanPreset>[];
    
    // Ajouter un timestamp pour garantir l'unicité et la variété
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = timestamp % 1000; // Pour plus de variété
    
    // Déterminer le niveau et les objectifs de l'utilisateur
    final level = userProfile?['level'] as String? ?? 'Fidèle régulier';
    final goal = userProfile?['goal'] as String? ?? 'Discipline quotidienne';
    final meditation = userProfile?['meditation'] as String? ?? 'Méditation biblique';
    final durationMin = userProfile?['durationMin'] as int? ?? 15;
    
    // Adapter la difficulté selon le niveau
    final difficultyMultiplier = _getDifficultyMultiplier(level);
    
    // Générer des presets selon l'objectif principal
    final theme = _mapGoalToTheme(goal);
    final themeData = _spiritualThemes[theme];
    
    if (themeData != null) {
      // Créer plusieurs variations du même thème
      final books = themeData['books'] as List<String>;
      final targetAudience = themeData['targetAudience'] as List<String>;
      
      // Vérifier si le niveau utilisateur correspond au thème
      if (targetAudience.contains(level)) {
        // Générer 3 presets avec différentes combinaisons de livres
        for (int i = 0; i < 3 && i < books.length; i++) {
          final bookCombo = _getBookCombination(books, i, level);
          final preset = _createAdvancedPresetFromTheme(
            theme, 
            themeData, 
            bookCombo, 
            level, 
            durationMin,
            difficultyMultiplier,
            meditation,
            randomSeed + i // Ajouter de la variété
          );
          presets.add(preset);
        }
      }
    }
    
    // Ajouter des presets spécialisés selon le niveau avec timestamp
    if (level == 'Nouveau converti') {
      presets.addAll(_generateBeginnerPresets(durationMin, meditation, randomSeed));
    } else if (level == 'Rétrogarde') {
      presets.addAll(_generateRetrogradePresets(durationMin, meditation, randomSeed));
    } else if (level == 'Fidèle pas si régulier') {
      presets.addAll(_generateIrregularPresets(durationMin, meditation, randomSeed));
    } else if (level == 'Serviteur/leader') {
      presets.addAll(_generateAdvancedPresets(durationMin, meditation, randomSeed));
    } else {
      // Fidèle régulier - presets équilibrés
      presets.addAll(_generateBalancedPresets(durationMin, meditation, randomSeed));
    }
    
    // Générer des presets selon le type de méditation
    presets.addAll(_generateMeditationSpecificPresets(meditation, level, durationMin, randomSeed));
    
    // Mélanger les presets pour plus de variété
    presets.shuffle();
    
    return presets.take(6).toList(); // Maximum 6 presets pour plus de variété
  }

  /// Mappe les objectifs utilisateur vers les thèmes spirituels
  static String _mapGoalToTheme(String goal) {
    final goalMapping = {
      'Discipline quotidienne': 'spiritual_growth',
      'Discipline de prière': 'prayer_life',
      'Approfondir la Parole': 'wisdom_understanding',
      'Grandir dans la foi': 'faith_foundation',
      'Développer mon caractère': 'christian_character',
      'Trouver de l\'encouragement': 'hope_encouragement',
      'Expérimenter la guérison': 'forgiveness_healing',
      'Partager ma foi': 'mission_evangelism',
      'Mieux prier': 'prayer_life',
    };
    
    return goalMapping[goal] ?? 'spiritual_growth';
  }

  /// Obtient le multiplicateur de difficulté selon le niveau
  static double _getDifficultyMultiplier(String level) {
    switch (level) {
      case 'Nouveau converti':
        return 0.7; // Plus facile, moins de jours
      case 'Rétrogarde':
        return 0.6; // Très facile, pour encourager la reprise
      case 'Fidèle pas si régulier':
        return 0.8; // Légèrement plus facile pour la constance
      case 'Fidèle régulier':
        return 1.0; // Normal
      case 'Serviteur/leader':
        return 1.3; // Plus difficile, plus de jours
      default:
        return 1.0; // Normal
    }
  }

  /// Crée un preset avancé à partir d'un thème spirituel
  static PlanPreset _createAdvancedPresetFromTheme(
    String theme, 
    Map<String, dynamic> themeData, 
    List<String> bookCombo, 
    String level, 
    int durationMin,
    double difficultyMultiplier,
    String meditation,
    [int randomSeed = 0]
  ) {
    final focus = themeData['focus'] as String;
    final verses = themeData['verses'] as List<String>;
    final emotions = themeData['emotions'] as List<String>;
    
    // Calculer la durée basée sur les livres sélectionnés
    final finalDuration = _calculateDurationFromBooks(bookCombo, level, durationMin);
    
    // Générer un nom intelligent basé sur la combinaison de livres avec variété
    final name = _generateAdvancedIntelligentName(theme, focus, bookCombo, emotions, randomSeed);
    
    // Créer le slug
    final slug = 'intelligent_${theme}_${bookCombo.join('_')}_${finalDuration}d';
    
    // Générer une description enrichie
    final description = _generateRichDescription(theme, focus, bookCombo, finalDuration, meditation);
    
    return PlanPreset(
      slug: slug,
      name: name,
      durationDays: finalDuration,
      order: 'thematic',
      books: bookCombo.join(','),
      coverImage: null,
      minutesPerDay: durationMin,
      recommended: _getRecommendedLevels(level),
      description: description,
      gradient: _getAdvancedThemeGradient(theme, emotions),
      specificBooks: _getAdvancedSpecificBooksDescription(bookCombo, verses),
    );
  }

  /// Obtient une combinaison de livres intelligente
  static List<String> _getBookCombination(List<String> books, int index, String level) {
    if (index == 0) {
      // Combinaison principale
      return books.take(2).toList();
    } else if (index == 1) {
      // Combinaison alternative
      return books.skip(1).take(2).toList();
    } else {
      // Combinaison complémentaire
      return [books.first, books.last];
    }
  }

  /// Calcule la durée basée sur les livres sélectionnés
  static int _calculateDurationFromBooks(List<String> books, String level, int durationMin) {
    int baseDuration = 21;
    
    // Ajuster selon le niveau
    switch (level) {
      case 'Nouveau converti':
        baseDuration = 14;
        break;
      case 'Serviteur/leader':
        baseDuration = 40;
        break;
      default:
        baseDuration = 30;
    }
    
    // Ajuster selon la durée quotidienne
    if (durationMin <= 10) {
      baseDuration = (baseDuration * 0.7).round();
    } else if (durationMin >= 25) {
      baseDuration = (baseDuration * 1.3).round();
    }
    
    // Ajuster selon le nombre de livres
    if (books.length == 1) {
      baseDuration = (baseDuration * 0.8).round();
    } else if (books.length >= 3) {
      baseDuration = (baseDuration * 1.2).round();
    }
    
    return baseDuration.clamp(7, 90);
  }

  /// Génère un nom intelligent avancé
  static String _generateAdvancedIntelligentName(
    String theme, 
    String focus, 
    List<String> bookCombo, 
    List<String> emotions,
    [int randomSeed = 0]
  ) {
    // Variantes de noms pour plus de dynamisme
    final themeNames = {
      'spiritual_growth': ['Croissance Spirituelle', 'Évolution de la Foi', 'Développement Chrétien', 'Progression Spirituelle'],
      'prayer_life': ['Vie de Prière', 'Communion Divine', 'Dialogue avec Dieu', 'Intimité Spirituelle'],
      'wisdom_understanding': ['Sagesse Divine', 'Compréhension Biblique', 'Intelligence Spirituelle', 'Discernement Chrétien'],
      'faith_foundation': ['Fondements de la Foi', 'Bases Chrétiennes', 'Piliers de la Foi', 'Racines Spirituelles'],
      'christian_character': ['Caractère Chrétien', 'Transformation Intérieure', 'Santé Spirituelle', 'Intégrité Chrétienne'],
      'hope_encouragement': ['Espérance & Encouragement', 'Renaissance Spirituelle', 'Restauration du Cœur', 'Nouvelle Espérance'],
      'forgiveness_healing': ['Pardon & Guérison', 'Libération Spirituelle', 'Guérison Intérieure', 'Rédemption Personnelle'],
      'mission_evangelism': ['Mission & Évangélisation', 'Appel Missionnaire', 'Témoignage Chrétien', 'Service Divin'],
    };
    
    final baseNameOptions = themeNames[theme] ?? ['Plan Spirituel', 'Parcours Biblique', 'Découverte Divine'];
    final baseName = baseNameOptions[randomSeed % baseNameOptions.length];
    
    // Ajouter des qualificatifs basés sur les émotions avec variété
    final emotionQualifiers = {
      'encouragement': ['Inspirant', 'Motivant', 'Stimulant', 'Enrichissant'],
      'peace': ['Apaisant', 'Serein', 'Tranquille', 'Calmant'],
      'wisdom': ['Sage', 'Profond', 'Réfléchi', 'Éclairant'],
      'hope': ['Espérant', 'Optimiste', 'Révélateur', 'Prometteur'],
      'healing': ['Guérissant', 'Restaureur', 'Libérateur', 'Rénovateur'],
      'mission': ['Missionnaire', 'Évangélique', 'Témoin', 'Serviteur'],
      'growth': ['Transformateur', 'Évolutif', 'Progressif', 'Développeur'],
      'intimacy': ['Intime', 'Personnel', 'Authentique', 'Vrai'],
    };
    
    String qualifier = '';
    for (final emotion in emotions) {
      if (emotionQualifiers.containsKey(emotion)) {
        final options = emotionQualifiers[emotion]!;
        qualifier = ' ${options[randomSeed % options.length]}';
        break;
      }
    }
    
    // Formater les livres avec des variantes
    final bookNames = _formatBookNames(bookCombo.join(','));
    
    // Ajouter des variantes de séparateurs
    final separators = [' — ', ' • ', ' : ', ' - '];
    final separator = separators[randomSeed % separators.length];
    
    return '$baseName$qualifier$separator$bookNames';
  }

  /// Génère une description enrichie
  static String _generateRichDescription(
    String theme, 
    String focus, 
    List<String> books, 
    int duration,
    String meditation
  ) {
    final meditationDescriptions = {
      'Méditation biblique': 'méditation biblique approfondie',
      'Lectio Divina': 'lectio divina contemplative',
      'Contemplation': 'temps de contemplation silencieuse',
      'Prière silencieuse': 'prière et silence spirituel',
    };
    
    final meditationDesc = meditationDescriptions[meditation] ?? 'méditation spirituelle';
    
    return 'Plan intelligent généré localement pour une $meditationDesc. '
           'Parcours de $duration jours à travers ${_formatBookNames(books.join(','))} '
           'pour approfondir ${focus.toLowerCase()} et nourrir votre vie spirituelle quotidienne.';
  }

  /// Obtient un gradient avancé basé sur les émotions
  static List<Color> _getAdvancedThemeGradient(String theme, List<String> emotions) {
    // Gradients basés sur les émotions
    if (emotions.contains('peace')) {
      return [Color(0xFF4FD1C5), Color(0xFF06B6D4)]; // Teal apaisant
    } else if (emotions.contains('encouragement')) {
      return [Color(0xFFF59E0B), Color(0xFFFBBF24)]; // Orange encourageant
    } else if (emotions.contains('wisdom')) {
      return [Color(0xFF8B5CF6), Color(0xFFA78BFA)]; // Violet sage
    } else if (emotions.contains('hope')) {
      return [Color(0xFF06B6D4), Color(0xFF67E8F9)]; // Cyan espérant
    } else if (emotions.contains('healing')) {
      return [Color(0xFFEC4899), Color(0xFFF472B6)]; // Rose guérissant
    } else if (emotions.contains('mission')) {
      return [Color(0xFFEF4444), Color(0xFFF87171)]; // Rouge missionnaire
    } else if (emotions.contains('growth')) {
      return [Color(0xFF34D399), Color(0xFF6EE7B7)]; // Vert transformateur
    } else if (emotions.contains('intimacy')) {
      return [Color(0xFF7C3AED), Color(0xFFA855F7)]; // Violet intime
    }
    
    return _getThemeGradient(theme);
  }

  /// Obtient une description avancée des livres spécifiques
  static String _getAdvancedSpecificBooksDescription(List<String> books, List<String> verses) {
    final bookNames = _formatBookNames(books.join(','));
    final verseRefs = verses.take(2).join(', ');
    return '$bookNames • Versets clés: $verseRefs';
  }

  /// Génère un nom intelligent pour le preset
  static String _generateIntelligentName(String theme, String focus, String books) {
    final themeNames = {
      'spiritual_growth': 'Croissance Spirituelle',
      'prayer_life': 'Vie de Prière',
      'wisdom_understanding': 'Sagesse Divine',
      'faith_foundation': 'Fondements de la Foi',
      'christian_character': 'Caractère Chrétien',
      'hope_encouragement': 'Espérance & Encouragement',
      'forgiveness_healing': 'Pardon & Guérison',
      'mission_evangelism': 'Mission & Évangélisation',
    };
    
    final baseName = themeNames[theme] ?? 'Plan Spirituel';
    final bookNames = _formatBookNames(books);
    
    return '$baseName — $bookNames';
  }

  /// Formate les noms des livres pour l'affichage
  static String _formatBookNames(String books) {
    final bookMapping = {
      'Philippiens,Colossiens': 'Philippiens & Colossiens',
      'Psaumes,Luc': 'Psaumes & Luc',
      'Proverbes,Jacques': 'Proverbes & Jacques',
      'Jean,Romains': 'Jean & Romains',
      'Galates,Éphésiens': 'Galates & Éphésiens',
      'Romains,Philippiens': 'Romains & Philippiens',
      'Matthieu,Luc': 'Matthieu & Luc',
      'Actes,Matthieu': 'Actes & Matthieu',
    };
    
    return bookMapping[books] ?? books.replaceAll(',', ' & ');
  }

  /// Calcule les minutes par jour selon le niveau et la durée
  static int _calculateMinutesPerDay(String level, int duration) {
    int baseMinutes;
    
    switch (level) {
      case 'Nouveau converti':
        baseMinutes = 10;
        break;
      case 'Serviteur/leader':
        baseMinutes = 25;
        break;
      default:
        baseMinutes = 15;
    }
    
    // Ajuster selon la durée
    if (duration > 40) {
      baseMinutes = (baseMinutes * 0.8).round();
    } else if (duration < 21) {
      baseMinutes = (baseMinutes * 1.2).round();
    }
    
    return baseMinutes.clamp(5, 35);
  }

  /// Obtient les niveaux recommandés
  static List<PresetLevel> _getRecommendedLevels(String level) {
    switch (level) {
      case 'Nouveau converti':
        return [PresetLevel.beginner];
      case 'Serviteur/leader':
        return [PresetLevel.regular];
      default:
        return [PresetLevel.regular];
    }
  }

  /// Obtient le gradient pour un thème
  static List<Color> _getThemeGradient(String theme) {
    final gradients = {
      'spiritual_growth': [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      'prayer_life': [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
      'wisdom_understanding': [Color(0xFFFF9800), Color(0xFFE65100)],
      'faith_foundation': [Color(0xFF2196F3), Color(0xFF0D47A1)],
      'christian_character': [Color(0xFF00BCD4), Color(0xFF006064)],
      'hope_encouragement': [Color(0xFFFFEB3B), Color(0xFFF57F17)],
      'forgiveness_healing': [Color(0xFFE91E63), Color(0xFF880E4F)],
      'mission_evangelism': [Color(0xFF795548), Color(0xFF3E2723)],
    };
    
    return gradients[theme] ?? [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  }

  /// Obtient la description des livres spécifiques
  static String _getSpecificBooksDescription(String books, List<String> verses) {
    final bookNames = _formatBookNames(books);
    final verseRefs = verses.take(2).join(', ');
    return '$bookNames ($verseRefs)';
  }

  /// Génère des presets pour les nouveaux convertis
  static List<PlanPreset> _generateBeginnerPresets(int durationMin, String meditation, [int randomSeed = 0]) {
    return [
      PlanPreset(
        slug: 'beginner_john_gospel',
        name: 'Découvrir Jésus${randomSeed % 2 == 0 ? ' — Jean & Luc' : ' • Évangiles de Vie'}',
        durationDays: 21,
        order: 'thematic',
        books: 'Jean,Luc',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.beginner],
        description: 'Plan spécialement conçu pour les nouveaux convertis. '
                    'Découvrez Jésus à travers les Évangiles de Jean et Luc '
                    'en 21 jours de lecture quotidienne.',
        gradient: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        specificBooks: 'Jean & Luc (Jean 3:16, Luc 19:10)',
      ),
      PlanPreset(
        slug: 'beginner_psalms_intro',
        name: 'Premiers Psaumes${randomSeed % 3 == 0 ? ' — Psaumes 1-30' : randomSeed % 3 == 1 ? ' • Louange & Adoration' : ' : Cantiques de Grâce'}',
        durationDays: 30,
        order: 'thematic',
        books: 'Psaumes',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.beginner],
        description: 'Introduction aux Psaumes pour nouveaux convertis. '
                    'Découvrez la prière et la louange à travers les premiers psaumes.',
        gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        specificBooks: 'Psaumes 1-30 (Psaumes 23, 27)',
      ),
    ];
  }

  /// Génère des presets pour les rétrogrades
  static List<PlanPreset> _generateRetrogradePresets(int durationMin, String meditation, [int randomSeed = 0]) {
    return [
      PlanPreset(
        slug: 'retrograde_restoration',
        name: 'Retour à Dieu — Psaumes & Jean',
        durationDays: 14,
        order: 'thematic',
        books: 'Psaumes,Jean',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.beginner],
        description: 'Plan doux pour retrouver Dieu. '
                    'Redécouvrez l\'amour divin à travers les Psaumes '
                    'et l\'Évangile de Jean en 14 jours.',
        gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        specificBooks: 'Psaumes & Jean (Psaumes 51, Jean 21:15-17)',
      ),
      PlanPreset(
        slug: 'retrograde_mercy',
        name: 'Grâce et Miséricorde — Luc & 1 Jean',
        durationDays: 21,
        order: 'thematic',
        books: 'Luc,1 Jean',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.beginner],
        description: 'Renouez avec la grâce de Dieu. '
                    'Découvrez Sa miséricorde à travers Luc et 1 Jean.',
        gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        specificBooks: 'Luc & 1 Jean (Luc 15:11-32, 1 Jean 1:9)',
      ),
    ];
  }

  /// Génère des presets pour les fidèles pas si réguliers
  static List<PlanPreset> _generateIrregularPresets(int durationMin, String meditation, [int randomSeed = 0]) {
    return [
      PlanPreset(
        slug: 'irregular_consistency',
        name: 'Retrouver la Constance — Proverbes & Matthieu',
        durationDays: 31,
        order: 'thematic',
        books: 'Proverbes,Matthieu',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.regular],
        description: 'Plan pour retrouver une discipline régulière. '
                    'Développez la sagesse et la constance avec Proverbes et Matthieu.',
        gradient: [Color(0xFF10B981), Color(0xFF059669)],
        specificBooks: 'Proverbes & Matthieu (Proverbes 6:6-11, Matthieu 6:33)',
      ),
      PlanPreset(
        slug: 'irregular_motivation',
        name: 'Raviver la Flamme — Philippiens & Psaumes',
        durationDays: 21,
        order: 'thematic',
        books: 'Philippiens,Psaumes',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.regular],
        description: 'Retrouvez la joie et la motivation. '
                    'Laissez-vous encourager par Philippiens et les Psaumes.',
        gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
        specificBooks: 'Philippiens & Psaumes (Philippiens 4:13, Psaumes 27)',
      ),
    ];
  }

  /// Génère des presets pour les serviteurs/leaders
  static List<PlanPreset> _generateAdvancedPresets(int durationMin, String meditation, [int randomSeed = 0]) {
    return [
      PlanPreset(
        slug: 'advanced_leadership',
        name: 'Leadership Chrétien — Romains & Éphésiens',
        durationDays: 60,
        order: 'thematic',
        books: 'Romains,Éphésiens',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.regular],
        description: 'Plan approfondi pour les leaders spirituels. '
                    'Étude approfondie des doctrines fondamentales '
                    'et des principes de leadership chrétien.',
        gradient: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
        specificBooks: 'Romains & Éphésiens (Romains 8:28, Éphésiens 4:32)',
      ),
      PlanPreset(
        slug: 'advanced_prophets',
        name: 'Prophètes Majeurs — Ésaïe & Jérémie',
        durationDays: 45,
        order: 'thematic',
        books: 'Ésaïe,Jérémie',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.regular],
        description: 'Étude approfondie des prophètes majeurs pour leaders. '
                    'Découvrez les prophéties messianiques et la nouvelle alliance.',
        gradient: [Color(0xFFEF4444), Color(0xFFF87171)],
        specificBooks: 'Ésaïe & Jérémie (Ésaïe 53:5, Jérémie 31:33)',
      ),
    ];
  }

  /// Génère des presets équilibrés pour les fidèles réguliers
  static List<PlanPreset> _generateBalancedPresets(int durationMin, String meditation, [int randomSeed = 0]) {
    return [
      PlanPreset(
        slug: 'balanced_gospels',
        name: 'Évangiles Complets — Matthieu & Jean',
        durationDays: 40,
        order: 'thematic',
        books: 'Matthieu,Jean',
        coverImage: null,
        minutesPerDay: durationMin,
        recommended: [PresetLevel.regular],
        description: 'Étude équilibrée des Évangiles synoptique et johannique. '
                    'Découvrez Jésus à travers deux perspectives complémentaires.',
        gradient: [Color(0xFF10B981), Color(0xFF34D399)],
        specificBooks: 'Matthieu & Jean (Matthieu 6:33, Jean 14:6)',
      ),
    ];
  }

  /// Génère des presets selon le type de méditation
  static List<PlanPreset> _generateMeditationSpecificPresets(String meditation, String level, int durationMin, [int randomSeed = 0]) {
    switch (meditation) {
      case 'Lectio Divina':
        return [
          PlanPreset(
            slug: 'lectio_psalms',
            name: 'Lectio Divina — Psaumes & Jean',
            durationDays: 21,
            order: 'thematic',
            books: 'Psaumes,Jean',
            coverImage: null,
            minutesPerDay: durationMin,
            recommended: [PresetLevel.regular],
            description: 'Pratique de la Lectio Divina avec les Psaumes et l\'Évangile de Jean. '
                        'Méthode contemplative de lecture spirituelle.',
            gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            specificBooks: 'Psaumes & Jean (Psaumes 46:10, Jean 1:1)',
          ),
        ];
      case 'Contemplation':
        return [
          PlanPreset(
            slug: 'contemplation_john',
            name: 'Contemplation — Jean & 1 Jean',
            durationDays: 30,
            order: 'thematic',
            books: 'Jean,1 Jean',
            coverImage: null,
            minutesPerDay: durationMin,
            recommended: [PresetLevel.regular],
            description: 'Temps de contemplation avec l\'Évangile et l\'Épître de Jean. '
                        'Méditation profonde sur l\'amour et la vérité.',
            gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            specificBooks: 'Jean & 1 Jean (Jean 3:16, 1 Jean 4:8)',
          ),
        ];
      case 'Prière silencieuse':
        return [
          PlanPreset(
            slug: 'silent_prayer_psalms',
            name: 'Prière Silencieuse — Psaumes & Luc',
            durationDays: 28,
            order: 'thematic',
            books: 'Psaumes,Luc',
            coverImage: null,
            minutesPerDay: durationMin,
            recommended: [PresetLevel.regular],
            description: 'Prière silencieuse avec les Psaumes et l\'Évangile de Luc. '
                        'Développez une vie de prière contemplative.',
            gradient: [Color(0xFF4FD1C5), Color(0xFF06B6D4)],
            specificBooks: 'Psaumes & Luc (Psaumes 23:1, Luc 11:1-13)',
          ),
        ];
      default: // Méditation biblique
        return [
          PlanPreset(
            slug: 'biblical_meditation_balanced',
            name: 'Méditation Biblique — Évangiles & Épîtres',
            durationDays: 35,
            order: 'thematic',
            books: 'Matthieu,Philippiens',
            coverImage: null,
            minutesPerDay: durationMin,
            recommended: [PresetLevel.regular],
            description: 'Méditation biblique équilibrée avec les Évangiles et les Épîtres. '
                        'Approfondissez votre compréhension de la Parole.',
            gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            specificBooks: 'Matthieu & Philippiens (Matthieu 5:3-12, Philippiens 4:13)',
          ),
        ];
    }
  }

  // === PUBLIC: génère explications pour une liste de presets ===
  static List<PresetExplanation> explainPresets(
    List<PlanPreset> presets,
    Map<String, dynamic>? profile,
  ) {
    final themeKey = _mapGoalToTheme((profile?['goal'] as String?) ?? 'Discipline quotidienne');
    final season = _detectSeason(DateTime.now());
    return presets.map((p) => _explainOne(p, profile, themeKey, season)).toList();
  }

  // === PRIVATE: calcule et détaille le scoring d'un preset ===
  static PresetExplanation _explainOne(
    PlanPreset p,
    Map<String, dynamic>? profile,
    String themeKey,
    String season,
  ) {
    final reasons = <ReasonItem>[];
    double total = 0;

    final level = (profile?['level'] as String?) ?? 'Fidèle régulier';
    final goal  = (profile?['goal']  as String?) ?? 'Discipline quotidienne';
    final minutes = (profile?['durationMin'] as int?) ?? 15;

    // 1) Objectif pivot
    double wGoal = p.slug.contains(themeKey) ? 0.45 : 0.0;
    reasons.add(ReasonItem(
      label: 'Objectif prioritaire',
      weight: wGoal,
      detail: wGoal > 0
        ? 'Le thème du preset correspond à l\'objectif "$goal".'
        : 'Le preset ne correspond pas directement à l\'objectif "$goal".',
    ));
    total += wGoal;

    // 2) Saison
    double wSeason = 0.0;
    if (p.slug.contains('season_')) {
      final seasonKey = _spiritualThemes.entries.firstWhere(
        (e) => p.slug.contains(e.key),
        orElse: () => const MapEntry('none', {}),
      ).value['season'];
      if (seasonKey == season) wSeason = 0.20;
    }
    reasons.add(ReasonItem(
      label: 'Pertinence saisonnière',
      weight: wSeason,
      detail: wSeason > 0
        ? 'Ce preset est aligné avec la saison liturgique actuelle ($season).'
        : 'Pas de bonus saisonnier.',
    ));
    total += wSeason;

    // 3) Minutes/jour (adéquation)
    final presetMinutes = p.minutesPerDay ?? 15; // Valeur par défaut si null
    final delta = (presetMinutes - minutes).abs();
    double wMinutes = (delta == 0 ? 0.15 : (delta <= 5 ? 0.10 : (delta <= 10 ? 0.05 : 0.0)));
    reasons.add(ReasonItem(
      label: 'Compatibilité temps quotidien',
      weight: wMinutes,
      detail: 'Préférence: ${minutes}min/j • Plan: ${presetMinutes}min/j • Écart: ±$delta min.',
    ));
    total += wMinutes;

    // 4) Niveau (difficulté cohérente)
    final levelDiff = _getDifficultyMultiplier(level) >= 1.2 ? 'advanced' : 
                     _getDifficultyMultiplier(level) <= 0.8 ? 'beginner' : 'intermediate';
    double wLevel = 0.0;
    if (levelDiff == 'beginner' && p.durationDays <= 21) wLevel = 0.10;
    if (levelDiff == 'advanced' && p.durationDays >= 35) wLevel = 0.10;
    if (levelDiff == 'intermediate' && p.durationDays >= 21 && p.durationDays <= 35) wLevel = 0.10;
    reasons.add(ReasonItem(
      label: 'Adéquation au niveau',
      weight: wLevel,
      detail: 'Niveau: $level • Durée plan: ${p.durationDays} j • Difficulté cible: $levelDiff.',
    ));
    total += wLevel;

    // 5) Diversité des livres (petit plus si 2 livres)
    final bookCount = p.books.split(',').length;
    final wDiversity = (bookCount == 2) ? 0.05 : 0.0;
    reasons.add(ReasonItem(
      label: 'Diversité des livres',
      weight: wDiversity,
      detail: bookCount == 2
        ? 'Deux livres complémentaires pour une progression équilibrée.'
        : 'Nombre de livres: $bookCount.',
    ));
    total += wDiversity;

    return PresetExplanation(
      slug: p.slug,
      name: p.name,
      totalScore: double.parse(total.toStringAsFixed(3)),
      reasons: reasons,
    );
  }

  /// Détecte la saison liturgique actuelle
  static String _detectSeason(DateTime now) {
    final month = now.month;
    final day = now.day;
    
    // Advent (décembre avant Noël)
    if (month == 12 && day <= 25) return 'advent';
    // Christmas (Noël à Épiphanie)
    if ((month == 12 && day >= 25) || (month == 1 && day <= 6)) return 'christmas';
    // Lent (40 jours avant Pâques)
    if (month == 3 || month == 4) return 'lent';
    // Easter (Pâques à Pentecôte)
    if (month == 4 || month == 5 || month == 6) return 'easter';
    // Ordinary Time
    return 'ordinary';
  }

  // === ENRICHISSEMENTS AVANCÉS ===

  /// 1. Historique des plans suivis → pour éviter les redondances et proposer une continuité spirituelle
  static void addToPlanHistory(String planSlug) {
    _userPlanHistory.add(planSlug);
    // Garder seulement les 10 derniers plans
    if (_userPlanHistory.length > 10) {
      _userPlanHistory.removeAt(0);
    }
  }

  /// Vérifie si un preset a déjà été utilisé récemment
  static bool _hasRecentPlan(String slug) {
    return _userPlanHistory.contains(slug);
  }

  /// 2. Feedback utilisateur → ajuster les propositions par apprentissage
  static void recordUserFeedback(String planSlug, double rating) {
    _userFeedback[planSlug] = rating;
    print('📊 Feedback enregistré: $planSlug → $rating');
  }

  /// Obtient le score de feedback pour un preset
  static double _getFeedbackScore(String slug) {
    return _userFeedback[slug] ?? 0.5; // Score neutre par défaut
  }

  /// 3. Journal spirituel intégré → relier les ressentis quotidiens à la recommandation future
  static void addSpiritualJournalEntry(SpiritualJournalEntry entry) {
    _spiritualJournal.add(entry);
    print('📖 Journal spirituel: ${entry.emotion} (satisfaction: ${entry.satisfaction})');
  }

  /// Analyse les émotions dominantes du journal spirituel
  static List<String> _getDominantEmotions() {
    if (_spiritualJournal.isEmpty) return [];
    
    final emotionCounts = <String, int>{};
    final recentEntries = _spiritualJournal
        .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();
    
    for (final entry in recentEntries) {
      emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
    }
    
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEmotions.take(3).map((e) => e.key).toList();
  }

  /// Adaptation émotionnelle automatique basée sur le profil et l'historique
  static List<String> getEmotionalState(String level) {
    final baseEmotions = _emotionalStates[level] ?? ['peace', 'growth', 'wisdom'];
    final dominantEmotions = _getDominantEmotions();
    
    // Mélanger les émotions de base avec les émotions dominantes du journal
    final combinedEmotions = <String>[...baseEmotions];
    for (final emotion in dominantEmotions) {
      if (!combinedEmotions.contains(emotion)) {
        combinedEmotions.add(emotion);
      }
    }
    
    return combinedEmotions.take(4).toList();
  }

  /// Génération enrichie avec tous les facteurs d'apprentissage
  static List<PlanPreset> generateEnrichedPresets(Map<String, dynamic>? profile) {
    final basePresets = generateIntelligentPresets(profile);
    
    // Appliquer les enrichissements
    final enrichedPresets = basePresets.where((preset) {
      // Éviter les plans récents
      if (_hasRecentPlan(preset.slug)) return false;
      
      // Appliquer le feedback utilisateur
      final feedbackScore = _getFeedbackScore(preset.slug);
      return feedbackScore >= 0.3; // Seuil minimum de satisfaction
    }).toList();

    // Si pas assez de presets après filtrage, ajouter des nouveaux
    if (enrichedPresets.length < 3) {
      final additionalPresets = generateIntelligentPresets(profile);
      for (final preset in additionalPresets) {
        if (!enrichedPresets.any((p) => p.slug == preset.slug) && 
            !_hasRecentPlan(preset.slug)) {
          enrichedPresets.add(preset);
          if (enrichedPresets.length >= 6) break;
        }
      }
    }

    return enrichedPresets.take(6).toList();
  }

  /// Obtient des recommandations basées sur l'historique spirituel
  static List<String> getSpiritualRecommendations() {
    if (_spiritualJournal.isEmpty) {
      return ['Commencez votre journal spirituel pour des recommandations personnalisées'];
    }

    final recentEntries = _spiritualJournal
        .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 14))))
        .toList();

    if (recentEntries.isEmpty) {
      return ['Continuez votre parcours spirituel avec régularité'];
    }

    final avgSatisfaction = recentEntries
        .map((e) => e.satisfaction)
        .reduce((a, b) => a + b) / recentEntries.length;

    if (avgSatisfaction >= 0.8) {
      return [
        'Excellent! Votre satisfaction spirituelle est élevée',
        'Continuez avec des plans plus approfondis',
        'Partagez votre expérience avec d\'autres'
      ];
    } else if (avgSatisfaction >= 0.6) {
      return [
        'Bon parcours spirituel en cours',
        'Essayez des plans plus courts pour maintenir la motivation',
        'Réfléchissez sur ce qui vous nourrit le plus'
      ];
    } else {
      return [
        'Votre satisfaction spirituelle pourrait être améliorée',
        'Essayez des plans plus courts et plus accessibles',
        'Consultez des passages d\'encouragement'
      ];
    }
  }
}
