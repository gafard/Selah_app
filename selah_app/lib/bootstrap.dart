import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'services/sync_queue_hive.dart';
import 'services/user_prefs_hive.dart';
import 'services/user_prefs_sync.dart';
import 'services/telemetry_console.dart';
import 'services/user_repo_supabase.dart';
import 'services/background_tasks.dart';
import 'services/plan_service.dart';
import 'services/plan_service_http.dart';
import 'services/supabase_auth.dart';
import 'services/local_storage_service.dart';
import 'services/connectivity_service.dart';
import 'services/bible_text_service.dart';
import 'services/bible_study_hydrator.dart';
import 'services/bible_context_service.dart';
import 'services/cross_ref_service.dart';
import 'services/lexicon_service.dart';
import 'services/themes_service.dart';
import 'services/mirror_verse_service.dart';
import 'services/bible_pack_manager.dart';
import 'services/isbe_service.dart';
import 'services/openbible_themes_service.dart';
import 'bootstrap_plans.dart';

late SyncQueueHive syncQueue;
late UserPrefsHive userPrefs;
late TelemetryConsole telemetry;
late UserRepoSupabase userRepo;
late BackgroundTasks background;
late PlanService planService;
late ConnectivityService connectivityService;

Future<void> appBootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  await Hive.initFlutter();
  
  // Initialiser l'état de suppression des comptes
  await SupabaseAuthService.initializeDeletionState();
  
  // Gestion robuste des erreurs de verrouillage Hive
  try {
    await Hive.openBox('user_prefs');
  } catch (e) {
    print('⚠️ Erreur ouverture user_prefs, tentative de récupération: $e');
    // Fermer toutes les boxes et réessayer
    await Hive.close();
    await Hive.initFlutter();
    await Hive.openBox('user_prefs');
  }
  
  try {
    await Hive.openBox('sync_tasks');
  } catch (e) {
    print('⚠️ Erreur ouverture sync_tasks, tentative de récupération: $e');
    await Hive.openBox('sync_tasks');
  }

  // Plan caches
  final (plansBox, planDaysBox) = await openPlanCaches();

  // Services de stockage local
  await LocalStorageService.init();
  
  // Service de textes bibliques
  await BibleTextService.init();
  
  // Initialiser tous les services bibliques
  await _initializeBibleServices();

  // Services
  userPrefs = UserPrefsHive(Hive.box('user_prefs'));
  UserPrefsSync.init(userPrefs); // Initialiser la synchronisation
  
  // Synchronisation automatique au démarrage
  await UserPrefsSync.syncBidirectional();
  print('🔄 UserPrefsSync: Synchronisation automatique au démarrage terminée');
  
  // Démarrer la surveillance automatique
  await UserPrefsSync.startAutoSync();
  
  telemetry = TelemetryConsole();
  userRepo = UserRepoSupabase(); // configure via env SUPABASE_URL/KEY ou setters
  syncQueue = SyncQueueHive(Hive.box('sync_tasks'), telemetry: telemetry, userRepo: userRepo);
  background = BackgroundTasks(telemetry: telemetry);
  connectivityService = ConnectivityService();
  await connectivityService.init();
  
  // Plan service
  planService = PlanServiceHttp(
    baseUrl: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1'),
    tokenProvider: SupabaseAuthService.getCurrentToken,
    cachePlans: plansBox,
    cachePlanDays: planDaysBox,
    syncQueue: syncQueue,
    telemetry: telemetry,
  );

  // Workmanager et android_alarm_manager_plus supprimés pour éviter les problèmes de compatibilité
}

/// Initialise tous les services bibliques et hydrate les données
Future<void> _initializeBibleServices() async {
  print('📚 Initialisation des services bibliques...');
  
  try {
    // 1. Initialiser tous les services
    await BibleContextService.init();
    await CrossRefService.init();
    await LexiconService.init();
    await ThemesService.init();
    await MirrorVerseService.init();
    
    // 1.5. Initialiser les services des packs
    await ISBEService.init();
    await OpenBibleThemesService.init();
    
    // 2. Vérifier si l'hydratation est nécessaire
    final needsHydration = await BibleStudyHydrator.needsHydration();
    
    if (needsHydration) {
      print('💧 Hydratation des données bibliques...');
      await BibleStudyHydrator.hydrateAll(
        onProgress: (progress, currentFile) {
          print('📊 Hydratation: ${(progress * 100).toInt()}% - $currentFile');
        },
      );
    } else {
      print('✅ Données bibliques déjà hydratées');
    }
    
    // 3. Populer la base SQLite si nécessaire
    await _populateSqliteIfNeeded();
    
    // 4. Extraire les packs bibliques si nécessaire
    await _extractBiblePacksIfNeeded();
    
    print('✅ Services bibliques initialisés avec succès');
  } catch (e) {
    print('⚠️ Erreur initialisation services bibliques: $e');
    // Continuer même en cas d'erreur pour ne pas bloquer l'app
  }
}

/// Popule la base SQLite avec les données bibliques si nécessaire
Future<void> _populateSqliteIfNeeded() async {
  try {
    // Vérifier si la base SQLite a des versets
    final hasVerses = await BibleTextService.hasVerses();
    
    if (!hasVerses) {
      print('📖 Population de la base SQLite...');
      await BibleTextService.populateFromAssets();
    } else {
      print('✅ Base SQLite déjà peuplée');
    }
    
    // Pré-charger la version par défaut pour éviter le "blanc" la première fois
    await BibleTextService.preloadActiveVersion('lsg1910');
  } catch (e) {
    print('⚠️ Erreur population SQLite: $e');
  }
}

/// Extrait les packs bibliques si nécessaire
Future<void> _extractBiblePacksIfNeeded() async {
  try {
    print('📦 Vérification des packs bibliques...');
    
    // Extraire tous les packs
    final results = await BiblePackManager.extractAllPacks();
    
    int extracted = 0;
    for (final entry in results.entries) {
      if (entry.value) {
        extracted++;
        print('✅ Pack ${entry.key} extrait');
      } else {
        print('❌ Échec extraction pack ${entry.key}');
      }
    }
    
    print('📊 Packs extraits: $extracted/${results.length}');
    
    // Afficher les statistiques
    final stats = await BiblePackManager.getPackStats();
    print('📈 Statistiques packs: ${stats['extracted']}/${stats['total']} extraits');
    
  } catch (e) {
    print('⚠️ Erreur extraction packs: $e');
  }
}