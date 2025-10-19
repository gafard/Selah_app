import 'package:hive/hive.dart';

/// Modèle représentant une pratique de fondation
class FoundationPractice {
  final String date; // YYYY-MM-DD
  final String foundationId;
  final bool practiced;
  final String? note; // Micro-journal (120 chars max)
  final DateTime timestamp;

  const FoundationPractice({
    required this.date,
    required this.foundationId,
    required this.practiced,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'foundationId': foundationId,
      'practiced': practiced,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FoundationPractice.fromJson(Map<String, dynamic> json) {
    return FoundationPractice(
      date: json['date'] as String,
      foundationId: json['foundationId'] as String,
      practiced: json['practiced'] as bool,
      note: json['note'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'FoundationPractice(date: $date, foundationId: $foundationId, practiced: $practiced)';
  }
}

/// Service de gestion du progrès des fondations spirituelles
class FoundationsProgressService {
  static const String _boxName = 'foundation_practices';
  static Box<Map>? _box;

  /// Initialise la box Hive pour les pratiques
  static Future<void> _ensureBox() async {
    if (_box == null) {
      _box = await Hive.openBox<Map>(_boxName);
    }
  }

  /// Marque une fondation comme pratiquée
  static Future<void> markAsPracticed(
    String foundationId, {
    String? note,
  }) async {
    await _ensureBox();
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final practiceKey = '${dateKey}_$foundationId';
    
    final practice = FoundationPractice(
      date: dateKey,
      foundationId: foundationId,
      practiced: true,
      note: note?.isNotEmpty == true ? note : null,
      timestamp: today,
    );
    
    await _box!.put(practiceKey, practice.toJson());
    print('✅ Fondation "$foundationId" marquée comme pratiquée le $dateKey');
  }

  /// Marque une fondation comme non pratiquée
  static Future<void> markAsNotPracticed(String foundationId) async {
    await _ensureBox();
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final practiceKey = '${dateKey}_$foundationId';
    
    final practice = FoundationPractice(
      date: dateKey,
      foundationId: foundationId,
      practiced: false,
      timestamp: today,
    );
    
    await _box!.put(practiceKey, practice.toJson());
    print('❌ Fondation "$foundationId" marquée comme non pratiquée le $dateKey');
  }

  /// Récupère la pratique d'une fondation pour une date donnée
  static Future<FoundationPractice?> getPracticeForDate(
    String foundationId,
    DateTime date,
  ) async {
    await _ensureBox();
    
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final practiceKey = '${dateKey}_$foundationId';
    
    final data = _box!.get(practiceKey);
    if (data != null) {
      return FoundationPractice.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Récupère la pratique d'aujourd'hui pour une fondation
  static Future<FoundationPractice?> getTodayPractice(String foundationId) async {
    return getPracticeForDate(foundationId, DateTime.now());
  }

  /// Récupère toutes les pratiques d'une semaine
  static Future<List<FoundationPractice>> getPracticesForWeek(DateTime weekStart) async {
    await _ensureBox();
    
    final practices = <FoundationPractice>[];
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Récupérer toutes les pratiques de cette date
      final keys = _box!.keys.where((key) => key.toString().startsWith(dateKey));
      for (final key in keys) {
        final data = _box!.get(key);
        if (data != null) {
          practices.add(FoundationPractice.fromJson(Map<String, dynamic>.from(data)));
        }
      }
    }
    
    return practices;
  }

  /// Récupère les statistiques hebdomadaires
  static Future<Map<String, dynamic>> getWeeklyStats(DateTime weekStart) async {
    final practices = await getPracticesForWeek(weekStart);
    final practiced = practices.where((p) => p.practiced).length;
    final total = practices.length;
    
    return {
      'practiced': practiced,
      'total': total,
      'percentage': total > 0 ? (practiced / total * 100).round() : 0,
      'practices': practices,
    };
  }

  /// Récupère les statistiques d'une fondation spécifique
  static Future<Map<String, dynamic>> getFoundationStats(String foundationId) async {
    await _ensureBox();
    
    final practices = <FoundationPractice>[];
    final keys = _box!.keys.where((key) => key.toString().endsWith('_$foundationId'));
    
    for (final key in keys) {
      final data = _box!.get(key);
      if (data != null) {
        practices.add(FoundationPractice.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    
    final practiced = practices.where((p) => p.practiced).length;
    final total = practices.length;
    
    return {
      'foundationId': foundationId,
      'practiced': practiced,
      'total': total,
      'percentage': total > 0 ? (practiced / total * 100).round() : 0,
      'practices': practices,
    };
  }

  /// Récupère toutes les pratiques
  static Future<List<FoundationPractice>> getAllPractices() async {
    await _ensureBox();
    
    final practices = <FoundationPractice>[];
    final keys = _box!.keys;
    
    for (final key in keys) {
      final data = _box!.get(key);
      if (data != null) {
        practices.add(FoundationPractice.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    
    // Trier par date décroissante
    practices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return practices;
  }

  /// Supprime toutes les pratiques (utile pour les tests)
  static Future<void> clearAllPractices() async {
    await _ensureBox();
    await _box!.clear();
    print('🗑️ Toutes les pratiques de fondations ont été supprimées');
  }

  /// Retourne un message d'encouragement basé sur les statistiques
  static String getEncouragementMessage(int practiced, int total) {
    if (total == 0) {
      return 'Commence ton parcours spirituel !';
    }
    
    final percentage = (practiced / total * 100).round();
    
    if (practiced == total) {
      return 'Incroyable ! Tu as pratiqué toutes les fondations cette semaine !';
    } else if (percentage >= 70) {
      return 'Tu avances bien ! Continue à bâtir sur le roc ($practiced/$total pratiquées).';
    } else if (percentage >= 40) {
      return 'Continue l\'effort ! Chaque jour est une nouvelle opportunité ($practiced/$total).';
    } else {
      return 'Ne te décourage pas ! Dieu est avec toi dans ton parcours ($practiced/$total).';
    }
  }

  /// Ferme la box (à appeler à la fermeture de l'app)
  static Future<void> close() async {
    if (_box != null) {
      await _box!.close();
      _box = null;
    }
  }
}
