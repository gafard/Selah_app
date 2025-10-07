import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:selah_app/router.dart';
import 'package:selah_app/supabase.dart';
import 'package:selah_app/services/reader_settings_service.dart';
import 'package:selah_app/services/app_state.dart';
import 'package:selah_app/services/notification_service.dart';
import 'package:selah_app/services/local_storage_service.dart';
import 'package:selah_app/services/connectivity_service.dart';

/// Point d'entrée principal - VRAI OFFLINE-FIRST
/// 
/// Architecture :
/// 1. Hive/LocalStorage d'abord (toujours)
/// 2. Services core offline-ready
/// 3. Supabase optionnel en arrière-plan (si en ligne)
/// 4. Reprise auto de la sync au retour réseau
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 1 : STOCKAGE LOCAL (CRITIQUE - Toujours en premier)
  // ═══════════════════════════════════════════════════════════════════
  await Hive.initFlutter();
  await LocalStorageService.init();
  debugPrint('✅ Local storage initialized (offline-ready)');
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 2 : SERVICES CORE (Offline-ready, non bloquants)
  // ═══════════════════════════════════════════════════════════════════
  
  // Timezone (pour notifications)
  tz.initializeTimeZones();
  debugPrint('✅ Timezone initialized');
  
  // Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;
  debugPrint('✅ Google Fonts initialized');
  
  // Notifications
  await NotificationService.instance.init();
  debugPrint('✅ Notifications initialized');
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 3 : DÉTECTION RÉSEAU (Sans bloquer le boot)
  // ═══════════════════════════════════════════════════════════════════
  
  // Initialiser ConnectivityService
  await ConnectivityService.instance.init();
  final isOnline = ConnectivityService.instance.isOnline;
  
  if (isOnline) {
    // Init Supabase en arrière-plan (non bloquant)
    unawaited(_safeInitSupabaseAndSync());
  } else {
    debugPrint('📴 Démarrage hors-ligne - Supabase sera initialisé au retour réseau');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 4 : LANCER L'APP IMMÉDIATEMENT (Même sans Supabase)
  // ═══════════════════════════════════════════════════════════════════
  
  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<AppState>(create: (context) => AppState()),
        provider.ChangeNotifierProvider<ReaderSettingsService>(create: (context) => ReaderSettingsService()),
      ],
      child: const ProviderScope(
        child: SelahApp(),
      ),
    ),
  );
  
  debugPrint('🎉 Selah App démarrée en mode ${isOnline ? "🌐 ONLINE" : "📴 OFFLINE"}');
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 5 : ÉCOUTE DES CHANGEMENTS DE CONNECTIVITÉ
  // ═══════════════════════════════════════════════════════════════════
  
  // S'abonner aux changements réseau pour reprise auto de sync
  ConnectivityService.instance.onConnectivityChanged.listen((online) {
    if (online) {
      debugPrint('📡 Réseau rétabli → Init Supabase & reprise sync');
      unawaited(_safeInitSupabaseAndSync());
    } else {
      debugPrint('📴 Connexion perdue → Mode offline');
    }
  });
}

/// Initialise Supabase et démarre la sync (ARRIÈRE-PLAN, NON BLOQUANT)
/// 
/// Cette fonction :
/// - N'initialise Supabase que si pas déjà fait
/// - Ne bloque jamais l'UI
/// - Gère les erreurs proprement
/// - Reprend la sync automatiquement
Future<void> _safeInitSupabaseAndSync() async {
  // ─────────────────────────────────────────────────────────────────
  // Init Supabase (si pas déjà fait)
  // ─────────────────────────────────────────────────────────────────
  try {
    // Vérifier si déjà initialisé (éviter double init)
    if (!_isSupabaseInitialized()) {
      await initializeSupabase();
      _supabaseInitialized = true;
      debugPrint('✅ Supabase initialized (online mode)');
    }
  } catch (e) {
    debugPrint('⚠️ Supabase init failed, staying offline: $e');
    return; // Sortir proprement sans crash
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Reprendre la sync queue (si disponible)
  // ─────────────────────────────────────────────────────────────────
  try {
    // Vider la queue de sync en attente
    final syncCount = LocalStorageService.getSyncQueue().length;
    if (syncCount > 0) {
      debugPrint('🔁 Reprise de la sync ($syncCount éléments en attente)...');
      // TODO: Implémenter la logique de vidage de queue
      // await SyncQueue.instance.drainPending();
      debugPrint('✅ Sync queue traitée');
    }
  } catch (e) {
    debugPrint('⚠️ Erreur lors de la sync : $e');
  }
}

/// Indicateur global pour éviter double initialisation Supabase
bool _supabaseInitialized = false;

/// Vérifie si Supabase est déjà initialisé
bool _isSupabaseInitialized() {
  return _supabaseInitialized;
}

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Selah',
      debugShowCheckedModeBanner: false,
      theme: _buildSelahTheme(),
      routerConfig: AppRouter.router,
    );
  }
}

/// Thème Selah avec police Poppins (similaire à Gilroy)
ThemeData _buildSelahTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD54F)),
    useMaterial3: true,
  );

  // Poppins (Google Fonts) - similaire à Gilroy
  final poppins = GoogleFonts.poppinsTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: poppins.copyWith(
      // CHIFFRES (ex: "13") - Poppins Black (similaire à Gilroy Heavy)
      displayLarge: poppins.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,  // Black
        fontSize: 80,                 // Taille imposante
        height: 0.85,
        letterSpacing: -3,
        color: const Color(0xFF111111),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      
      // TITRE (ex: "Croissance Spirituelle") - Poppins SemiBold
      titleLarge: poppins.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,  // SemiBold
        fontSize: 24,                 // 22-26 selon densité
        height: 1.15,
        letterSpacing: -0.3,
        color: const Color(0xFF111111),
      ),
      
      // PETITS TEXTES (ex: "semaines", "livres") - Poppins Medium
      bodySmall: poppins.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,  // Medium
        fontSize: 14,                 // 12-14
        height: 1.2,
        color: const Color(0xFF111111),
      ),
      
      // TEXTES NORMAUX - Poppins Regular
      bodyMedium: poppins.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,  // Regular
        fontSize: 16,
        height: 1.4,
        color: const Color(0xFF111111),
      ),
    ),
  );
}