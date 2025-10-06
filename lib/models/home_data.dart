// lib/models/home_data.dart

class HomeData {
  final String displayName;
  final String planName;
  final int totalDays;
  final int doneCount;
  final TodayReading? todayReading;
  final List<NextDay> nextDays;

  HomeData({
    required this.displayName,
    required this.planName,
    required this.totalDays,
    required this.doneCount,
    this.todayReading,
    required this.nextDays,
  });

  // Factory constructor pour créer depuis les données Supabase
  factory HomeData.fromSupabase({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> currentPlan,
    required List<Map<String, dynamic>> completedDays,
    Map<String, dynamic>? todayReadingData,
    required List<Map<String, dynamic>> nextDaysData,
  }) {
    return HomeData(
      displayName: userProfile['full_name'] ?? 'Ami(e)',
      planName: currentPlan['name'] ?? 'Plan de lecture',
      totalDays: currentPlan['total_days'] ?? 0,
      doneCount: completedDays.length,
      todayReading: todayReadingData != null 
        ? TodayReading.fromSupabase(todayReadingData)
        : null,
      nextDays: nextDaysData
        .map((data) => NextDay.fromSupabase(data))
        .toList(),
    );
  }

  // Getters calculés
  double get progressPercentage => 
    totalDays > 0 ? (doneCount / totalDays) : 0.0;
  
  int get progressPercentageRounded => 
    (progressPercentage * 100).round();
  
  bool get isCompleted => doneCount >= totalDays;
  
  int get remainingDays => totalDays - doneCount;
}

class TodayReading {
  final String id;
  final String planId;
  final int dayNumber;
  final List<String> references;
  final String status; // 'pending', 'completed', 'skipped'
  final DateTime? completedAt;

  TodayReading({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.references,
    required this.status,
    this.completedAt,
  });

  factory TodayReading.fromSupabase(Map<String, dynamic> data) {
    return TodayReading(
      id: data['id'] ?? '',
      planId: data['plan_id'] ?? '',
      dayNumber: data['day_number'] ?? 0,
      references: List<String>.from(data['bible_references'] ?? []),
      status: data['status'] ?? 'pending',
      completedAt: data['completed_at'] != null 
        ? DateTime.parse(data['completed_at'])
        : null,
    );
  }

  // Getters calculés
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isSkipped => status == 'skipped';
  
  String get referencesText => references.join(', ');
  
  String get statusDisplayText {
    switch (status) {
      case 'completed':
        return 'Terminé';
      case 'pending':
        return 'En attente';
      case 'skipped':
        return 'Ignoré';
      default:
        return 'Inconnu';
    }
  }

  // Méthode pour créer une copie avec un nouveau statut
  TodayReading copyWith({
    String? status,
    DateTime? completedAt,
  }) {
    return TodayReading(
      id: id,
      planId: planId,
      dayNumber: dayNumber,
      references: references,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class NextDay {
  final int dayNumber;
  final DateTime date;
  final List<String> references;
  final String status;

  NextDay({
    required this.dayNumber,
    required this.date,
    required this.references,
    this.status = 'pending',
  });

  factory NextDay.fromSupabase(Map<String, dynamic> data) {
    return NextDay(
      dayNumber: data['day_number'] ?? 0,
      date: DateTime.parse(data['date']),
      references: List<String>.from(data['bible_references'] ?? []),
      status: data['status'] ?? 'pending',
    );
  }

  // Getters calculés
  String get referencesText => references.join(', ');
  
  String get formattedDate {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    
    if (difference == 0) {
      return "Aujourd'hui";
    } else if (difference == 1) {
      return "Demain";
    } else if (difference == 2) {
      return "Après-demain";
    } else {
      return "${date.day}/${date.month}";
    }
  }
  
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }
}

// Extension pour faciliter le travail avec les données
extension HomeDataExtensions on HomeData {
  // Vérifie si l'utilisateur est en avance sur son planning
  bool get isAhead {
    if (todayReading == null) return false;
    return doneCount > todayReading!.dayNumber;
  }
  
  // Vérifie si l'utilisateur est en retard
  bool get isBehind {
    if (todayReading == null) return false;
    return doneCount < todayReading!.dayNumber - 1;
  }
  
  // Retourne un message d'encouragement basé sur la progression
  String get motivationalMessage {
    if (isCompleted) {
      return "🎉 Félicitations ! Vous avez terminé votre plan !";
    } else if (progressPercentage >= 0.8) {
      return "🔥 Plus que $remainingDays jours ! Vous y êtes presque !";
    } else if (progressPercentage >= 0.5) {
      return "💪 Excellent travail ! Vous êtes à mi-parcours !";
    } else if (progressPercentage >= 0.2) {
      return "📖 Continuez ainsi, vous êtes sur la bonne voie !";
    } else {
      return "🌱 Chaque jour compte, continuez votre lecture !";
    }
  }
  
  // Retourne la streak actuelle (jours consécutifs)
  int get currentStreak {
    // Cette logique nécessiterait des données supplémentaires
    // Pour l'instant, on retourne 0
    return 0;
  }
}
