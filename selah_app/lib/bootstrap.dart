import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'services/sync_queue_hive.dart';
import 'services/user_prefs_hive.dart';
import 'services/telemetry_console.dart';
import 'services/user_repo_supabase.dart';
import 'services/background_tasks.dart';
import 'services/plan_service.dart';
import 'services/plan_service_http.dart';
import 'services/supabase_auth.dart';
import 'services/local_storage_service.dart';
import 'services/bible_download_service.dart';
import 'services/connectivity_service.dart';
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
  await Hive.openBox('user_prefs');
  await Hive.openBox('sync_tasks');

  // Plan caches
  final (plansBox, planDaysBox) = await openPlanCaches();

  // Services de stockage local
  await LocalStorageService.init();

  // Services
  userPrefs = UserPrefsHive(Hive.box('user_prefs'));
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

  // Workmanager (pas supporté sur web)
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    // Optionnel: relance un worker périodique discret pour vider la file
    await Workmanager().registerPeriodicTask(
      'sync-loop', 'sync.loop',
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(networkType: NetworkType.connected),
      inputData: {'kind': 'sync_all'},
    );
  }
}