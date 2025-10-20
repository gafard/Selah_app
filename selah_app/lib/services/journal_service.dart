import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les entrées de journal
class JournalService {
  static const String _journalEntriesKey = 'journal_entries';
  
  /// Sauvegarde une entrée de journal
  static Future<void> saveJournalEntry({
    required String date,
    required List<String> bullets,
    required String passageRef,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await getJournalEntries();
      
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        bullets: bullets,
        passageRef: passageRef,
        notes: notes ?? '',
        createdAt: DateTime.now().toIso8601String(),
      );
      
      entries.add(entry);
      
      // Sauvegarder toutes les entrées
      final entriesJson = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_journalEntriesKey, jsonEncode(entriesJson));
      
      print('📝 Entrée de journal sauvegardée: ${entry.id}');
    } catch (e) {
      print('❌ Erreur sauvegarde journal: $e');
      rethrow;
    }
  }
  
  /// Récupère toutes les entrées de journal
  static Future<List<JournalEntry>> getJournalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_journalEntriesKey);
      
      if (entriesJson == null || entriesJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      return entriesList.map((json) => JournalEntry.fromJson(json)).toList();
    } catch (e) {
      print('❌ Erreur récupération journal: $e');
      return [];
    }
  }
  
  /// Récupère les entrées d'une date spécifique
  static Future<List<JournalEntry>> getEntriesForDate(String date) async {
    final allEntries = await getJournalEntries();
    return allEntries.where((entry) => entry.date == date).toList();
  }
  
  /// Récupère les entrées des 7 derniers jours
  static Future<List<JournalEntry>> getRecentEntries({int days = 7}) async {
    final allEntries = await getJournalEntries();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allEntries.where((entry) {
      final entryDate = DateTime.parse(entry.createdAt);
      return entryDate.isAfter(cutoffDate);
    }).toList();
  }
  
  /// Supprime une entrée de journal
  static Future<void> deleteJournalEntry(String entryId) async {
    try {
      final entries = await getJournalEntries();
      entries.removeWhere((entry) => entry.id == entryId);
      
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_journalEntriesKey, jsonEncode(entriesJson));
      
      print('🗑️ Entrée de journal supprimée: $entryId');
    } catch (e) {
      print('❌ Erreur suppression journal: $e');
      rethrow;
    }
  }
  
  /// Vide tout le journal
  static Future<void> clearAllEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalEntriesKey);
      print('🗑️ Toutes les entrées de journal supprimées');
    } catch (e) {
      print('❌ Erreur suppression journal: $e');
      rethrow;
    }
  }
  
  /// Compte le nombre d'entrées
  static Future<int> getEntryCount() async {
    final entries = await getJournalEntries();
    return entries.length;
  }
  
  /// Vérifie si une entrée existe pour une date donnée
  static Future<bool> hasEntryForDate(String date) async {
    final entries = await getEntriesForDate(date);
    return entries.isNotEmpty;
  }
}

/// Modèle pour une entrée de journal
class JournalEntry {
  final String id;
  final String date;
  final List<String> bullets;
  final String passageRef;
  final String notes;
  final String createdAt;
  
  JournalEntry({
    required this.id,
    required this.date,
    required this.bullets,
    required this.passageRef,
    required this.notes,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'bullets': bullets,
      'passageRef': passageRef,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
  
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      bullets: List<String>.from(json['bullets'] ?? []),
      passageRef: json['passageRef'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
  
  @override
  String toString() {
    return 'JournalEntry(id: $id, date: $date, bullets: ${bullets.length}, passageRef: $passageRef)';
  }
}



