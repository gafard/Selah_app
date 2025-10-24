import 'package:flutter/foundation.dart';
import '../services/user_prefs_hive.dart';
import '../services/local_storage_service.dart';
import '../services/telemetry_console.dart';
import '../services/plan_service_http.dart';
import '../services/intelligent_quiz_service.dart';
import '../models/plan_models.dart';

class TodayReading {
  final Plan plan;
  final PlanDay? today;
  TodayReading({required this.plan, required this.today});
}

class HomeState {
  final String firstName;
  final int tasksDone;
  final int tasksTotal;
  final QuizProgress? quizProgress; // 🏎️ Suivi du quiz Apôtre
  final int? currentStreak; // Série de jours en cours
  final int? weeksRemaining; // Semaines restantes dans le plan
  HomeState({
    required this.firstName, 
    required this.tasksDone, 
    required this.tasksTotal, 
    this.quizProgress,
    this.currentStreak,
    this.weeksRemaining,
  });
  HomeState copyWith({
    String? firstName, 
    int? tasksDone, 
    int? tasksTotal, 
    QuizProgress? quizProgress,
    int? currentStreak,
    int? weeksRemaining,
  }) =>
      HomeState(
        firstName: firstName ?? this.firstName, 
        tasksDone: tasksDone ?? this.tasksDone, 
        tasksTotal: tasksTotal ?? this.tasksTotal,
        quizProgress: quizProgress ?? this.quizProgress,
        currentStreak: currentStreak ?? this.currentStreak,
        weeksRemaining: weeksRemaining ?? this.weeksRemaining,
      );
  factory HomeState.initial() => HomeState(firstName: 'Ami', tasksDone: 0, tasksTotal: 1);
}

/// 🏎️ FERRARI - Progression du quiz intelligent
class QuizProgress {
  final int totalQuizzes;
  final int averageScore;
  final String lastQuizDate;
  final String learningStyle;
  final String spiritualLevel;
  final bool hasNewQuestions;
  
  QuizProgress({
    required this.totalQuizzes,
    required this.averageScore,
    required this.lastQuizDate,
    required this.learningStyle,
    required this.spiritualLevel,
    required this.hasNewQuestions,
  });
}

class HomeVM extends ChangeNotifier {
  final UserPrefsHive prefs;
  final TelemetryConsole telemetry;
  final PlanServiceHttp planService;

  HomeState state = HomeState.initial();
  TodayReading? today;

  HomeVM({required this.prefs, required this.telemetry, required this.planService});


  Future<void> load() async {
    // Récupérer le nom depuis LocalStorageService (même logique que OnboardingVM)
    String display = 'ami';
    try {
      // Récupérer le profil utilisateur complet depuis LocalStorageService
      final localUser = LocalStorageService.getLocalUser();
      print('🔍 HomeVM - localUser: $localUser');
      
      if (localUser != null) {
        // Essayer de récupérer depuis displayName d'abord
        if (localUser['displayName'] != null && localUser['displayName'].toString().isNotEmpty) {
          display = localUser['displayName'].toString();
        } else if (localUser['display_name'] != null && localUser['display_name'].toString().isNotEmpty) {
          display = localUser['display_name'].toString();
        } else {
          // Fallback: essayer de récupérer depuis les préférences
          final preferences = localUser['preferences'] as Map<String, dynamic>?;
          display = preferences?['name'] as String? ?? 
                   preferences?['firstName'] as String? ?? 
                   preferences?['displayName'] as String? ?? 
                   'ami';
        }
      } else {
        // Fallback vers UserPrefsHive si pas de profil local
        final profileData = prefs.profile;
        print('🔍 HomeVM - profileData fallback: $profileData');
        if (profileData['displayName'] != null && profileData['displayName'].toString().isNotEmpty) {
          display = profileData['displayName'].toString();
        } else {
          final preferences = profileData['preferences'] as Map<String, dynamic>?;
          display = preferences?['name'] as String? ?? 
                   preferences?['firstName'] as String? ?? 
                   preferences?['displayName'] as String? ?? 
                   'ami';
        }
      }
      
      // Nettoyer et prendre le premier mot
      if (display != 'ami' && display.isNotEmpty) {
        display = display.trim().split(' ').first;
        print('🔍 HomeVM - Nom trouvé: $display');
      } else {
        print('🔍 HomeVM - Aucun nom trouvé, utilisation du fallback: ami');
      }
    } catch (e) {
      print('❌ Erreur récupération nom dans HomeVM: $e');
      display = 'ami';
    }
    
    print('🔍 HomeVM - Nom final: $display');
    state = state.copyWith(firstName: display);
    notifyListeners();

    final plan = await planService.getActivePlan();
    if (plan != null) {
      // ✅ Calculer la différence en jours calendaires (change à minuit)
      final now = DateTime.now();
      final todayNormalized = DateTime(now.year, now.month, now.day);
      final startNormalized = DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
      final dayIndex = todayNormalized.difference(startNormalized).inDays + 1;
      final days = await planService.getPlanDays(plan.id, fromDay: dayIndex, toDay: dayIndex);
      today = TodayReading(plan: plan, today: days.isEmpty ? null : days.first);
      
      // Calculer la série actuelle et les semaines restantes
      final currentStreak = await _calculateCurrentStreak(plan.id);
      final weeksRemaining = await _calculateWeeksRemaining(plan);
      
      state = state.copyWith(
        currentStreak: currentStreak,
        weeksRemaining: weeksRemaining,
      );
      notifyListeners();

      planService.watchProgress(plan.id).listen((p) {
        state = state.copyWith(tasksDone: p.done, tasksTotal: p.total);
        notifyListeners();
      });
    }

    // 🏎️ FERRARI - Charger la progression du quiz
    await _loadQuizProgress();
  }

  Future<void> toggleTodayCompleted() async {
    if (today?.today == null) return;
    final d = today!.today!;
    await planService.setDayCompleted(d.planId, d.dayIndex, !d.completed);
    
    // Rafraîchir les données du jour actuel
    await _refreshTodayData();
  }
  
  /// Rafraîchir les données du jour actuel
  Future<void> _refreshTodayData() async {
    final plan = await planService.getActivePlan();
    if (plan != null) {
      final now = DateTime.now();
      final todayNormalized = DateTime(now.year, now.month, now.day);
      final startNormalized = DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
      final dayIndex = todayNormalized.difference(startNormalized).inDays + 1;
      final days = await planService.getPlanDays(plan.id, fromDay: dayIndex, toDay: dayIndex);
      today = TodayReading(plan: plan, today: days.isEmpty ? null : days.first);
      notifyListeners();
    }
  }
  
  /// Rafraîchir le calendrier (pour notifier les changements visuels)
  void refreshCalendar() {
    notifyListeners();
  }

  /// Rafraîchir spécifiquement le calendrier après un marquage
  Future<void> refreshCalendarAfterCompletion() async {
    await _refreshTodayData();
    notifyListeners();
  }

  /// 🏎️ FERRARI - Charger la progression du quiz intelligent
  Future<void> _loadQuizProgress() async {
    try {
      // Initialiser le service si nécessaire
      await IntelligentQuizService.init();
      
      // Récupérer l'ID utilisateur (TODO: utiliser l'ID réel)
      const userId = 'current_user';
      
      // Analyser les patterns cognitifs
      final cognitiveAnalysis = await IntelligentQuizService.analyzeCognitivePatterns(userId);
      
      // Analyser la progression spirituelle
      final spiritualProgress = await IntelligentQuizService.analyzeSpiritualQuizProgress(userId);
      
      // Créer l'objet de progression
      final quizProgress = QuizProgress(
        totalQuizzes: cognitiveAnalysis.patterns['total_quizzes'] ?? 0,
        averageScore: cognitiveAnalysis.patterns['average_score'] ?? 0,
        lastQuizDate: cognitiveAnalysis.patterns['last_quiz_date'] ?? 'Jamais',
        learningStyle: cognitiveAnalysis.patterns['learning_style'] ?? 'Équilibré',
        spiritualLevel: spiritualProgress.progress['spiritual_level'] ?? 'Débutant',
        hasNewQuestions: true, // Le service Apôtre génère toujours de nouvelles questions
      );
      
      // Mettre à jour l'état
      state = state.copyWith(quizProgress: quizProgress);
      notifyListeners();
      
      print('🏎️ Apôtre: Progression quiz chargée - ${quizProgress.totalQuizzes} quiz, score moyen: ${quizProgress.averageScore}%');
      
    } catch (e) {
      print('⚠️ Erreur chargement progression quiz: $e');
      // En cas d'erreur, créer une progression par défaut
      final defaultProgress = QuizProgress(
        totalQuizzes: 0,
        averageScore: 0,
        lastQuizDate: 'Jamais',
        learningStyle: 'Équilibré',
        spiritualLevel: 'Débutant',
        hasNewQuestions: true,
      );
      state = state.copyWith(quizProgress: defaultProgress);
      notifyListeners();
    }
  }

  /// 🏎️ FERRARI - Rafraîchir la progression du quiz
  Future<void> refreshQuizProgress() async {
    await _loadQuizProgress();
  }

  /// 🏎️ FERRARI - Obtenir les statistiques du quiz
  QuizProgress? get quizProgress => state.quizProgress;

  /// Calculer la série actuelle de jours consécutifs
  Future<int> _calculateCurrentStreak(String planId) async {
    try {
      final today = DateTime.now();
      int streak = 0;
      
      // Récupérer les 30 derniers jours pour vérifier la série
      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dayIndex = checkDate.difference(DateTime.now().subtract(const Duration(days: 30))).inDays + 1;
        
        try {
          final days = await planService.getPlanDays(planId, fromDay: dayIndex, toDay: dayIndex);
          if (days.isNotEmpty && days.first.completed) {
            streak++;
          } else {
            break; // Arrêter dès qu'on trouve un jour non complété
          }
        } catch (e) {
          // Si on ne peut pas récupérer le jour, on arrête
          break;
        }
      }
      
      return streak;
    } catch (e) {
      print('❌ Erreur calcul série: $e');
      return 0;
    }
  }

  /// Calculer les semaines restantes dans le plan
  Future<int> _calculateWeeksRemaining(Plan plan) async {
    try {
      final today = DateTime.now();
      final endDate = plan.startDate.add(Duration(days: plan.totalDays));
      
      if (endDate.isBefore(today)) {
        return 0; // Plan terminé
      }
      
      final daysRemaining = endDate.difference(today).inDays;
      final weeksRemaining = (daysRemaining / 7).ceil();
      
      return weeksRemaining;
    } catch (e) {
      print('❌ Erreur calcul semaines restantes: $e');
      return 0;
    }
  }
}