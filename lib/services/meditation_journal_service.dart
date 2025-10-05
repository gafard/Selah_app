import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meditation_journal_entry.dart';

class MeditationJournalService {
  static const String _journalKey = 'meditation_journal_entries';
  static const int _maxEntries = 100; // Limiter à 100 entrées pour éviter la surcharge

  /// Sauvegarder une nouvelle entrée dans le journal
  static Future<void> saveEntry(MeditationJournalEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingEntries = await getEntries();
      
      // Ajouter la nouvelle entrée au début
      existingEntries.insert(0, entry);
      
      // Limiter le nombre d'entrées
      if (existingEntries.length > _maxEntries) {
        existingEntries.removeRange(_maxEntries, existingEntries.length);
      }
      
      // Convertir en JSON et sauvegarder
      final entriesJson = existingEntries.map((e) => e.toMap()).toList();
      await prefs.setString(_journalKey, jsonEncode(entriesJson));
      
      print('📖 ENTRÉE SAUVEGARDÉE dans le journal: ${entry.passageRef} - ${entry.memoryVerseRef}');
    } catch (e) {
      print('❌ ERREUR lors de la sauvegarde du journal: $e');
    }
  }

  /// Récupérer toutes les entrées du journal
  static Future<List<MeditationJournalEntry>> getEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_journalKey);
      
      if (entriesJson == null) {
        return [];
      }
      
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      return entriesList.map((entryMap) => 
        MeditationJournalEntry.fromMap(Map<String, dynamic>.from(entryMap))
      ).toList();
    } catch (e) {
      print('❌ ERREUR lors de la récupération du journal: $e');
      return [];
    }
  }

  /// Récupérer les entrées d'une période spécifique
  static Future<List<MeditationJournalEntry>> getEntriesForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allEntries = await getEntries();
    
    if (startDate == null && endDate == null) {
      return allEntries;
    }
    
    return allEntries.where((entry) {
      if (startDate != null && entry.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && entry.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Récupérer les entrées des 7 derniers jours
  static Future<List<MeditationJournalEntry>> getRecentEntries({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getEntriesForPeriod(startDate: startDate, endDate: endDate);
  }

  /// Récupérer les entrées d'un mois spécifique
  static Future<List<MeditationJournalEntry>> getEntriesForMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return getEntriesForPeriod(startDate: startDate, endDate: endDate);
  }

  /// Supprimer une entrée spécifique
  static Future<void> deleteEntry(String entryId) async {
    try {
      final entries = await getEntries();
      entries.removeWhere((entry) => entry.id == entryId);
      
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = entries.map((e) => e.toMap()).toList();
      await prefs.setString(_journalKey, jsonEncode(entriesJson));
      
      print('🗑️ ENTRÉE SUPPRIMÉE du journal: $entryId');
    } catch (e) {
      print('❌ ERREUR lors de la suppression de l\'entrée: $e');
    }
  }

  /// Vider tout le journal
  static Future<void> clearJournal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalKey);
      print('🗑️ JOURNAL VIDÉ');
    } catch (e) {
      print('❌ ERREUR lors du vidage du journal: $e');
    }
  }

  /// Obtenir les statistiques du journal
  static Future<Map<String, dynamic>> getJournalStats() async {
    final entries = await getEntries();
    
    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'totalDays': 0,
        'averagePerWeek': 0.0,
        'mostUsedPassage': null,
        'mostUsedGradient': 0,
        'meditationTypes': {'free': 0, 'qcm': 0},
      };
    }
    
    // Calculer les statistiques
    final totalEntries = entries.length;
    final uniqueDays = entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().length;
    final weeks = (DateTime.now().difference(entries.last.date).inDays / 7).clamp(1, double.infinity);
    final averagePerWeek = totalEntries / weeks;
    
    // Passage le plus utilisé
    final passageCounts = <String, int>{};
    for (final entry in entries) {
      passageCounts[entry.passageRef] = (passageCounts[entry.passageRef] ?? 0) + 1;
    }
    final mostUsedPassage = passageCounts.isNotEmpty 
        ? passageCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;
    
    // Dégradé le plus utilisé
    final gradientCounts = <int, int>{};
    for (final entry in entries) {
      gradientCounts[entry.gradientIndex] = (gradientCounts[entry.gradientIndex] ?? 0) + 1;
    }
    final mostUsedGradient = gradientCounts.isNotEmpty 
        ? gradientCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 0;
    
    // Types de méditation
    final meditationTypes = <String, int>{'free': 0, 'qcm': 0};
    for (final entry in entries) {
      meditationTypes[entry.meditationType] = (meditationTypes[entry.meditationType] ?? 0) + 1;
    }
    
    return {
      'totalEntries': totalEntries,
      'totalDays': uniqueDays,
      'averagePerWeek': averagePerWeek,
      'mostUsedPassage': mostUsedPassage,
      'mostUsedGradient': mostUsedGradient,
      'meditationTypes': meditationTypes,
    };
  }

  /// Créer une entrée depuis les données de méditation
  static MeditationJournalEntry createEntryFromMeditation({
    required String passageRef,
    required String passageText,
    required String memoryVerse,
    required String memoryVerseRef,
    required List<String> prayerSubjects,
    required List<String> prayerNotes,
    required int gradientIndex,
    Uint8List? posterImageBytes,
    required String meditationType,
    required Map<String, dynamic> meditationData,
  }) {
    return MeditationJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      passageRef: passageRef,
      passageText: passageText,
      memoryVerse: memoryVerse,
      memoryVerseRef: memoryVerseRef,
      prayerSubjects: prayerSubjects,
      prayerNotes: prayerNotes,
      gradientIndex: gradientIndex,
      posterImageBytes: posterImageBytes,
      meditationType: meditationType,
      meditationData: meditationData,
    );
  }
}
