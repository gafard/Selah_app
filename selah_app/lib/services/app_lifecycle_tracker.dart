import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intelligent_alarm_service.dart';

/// 📱 Gestionnaire d'état d'application pour le suivi des ouvertures
/// 
/// Enregistre quand l'application est ouverte pour annuler les rappels
class AppLifecycleTracker with WidgetsBindingObserver {
  static const String LAST_APP_OPEN_KEY = 'last_app_open_time';
  
  static final AppLifecycleTracker _instance = AppLifecycleTracker._internal();
  factory AppLifecycleTracker() => _instance;
  AppLifecycleTracker._internal();

  static AppLifecycleTracker get instance => _instance;
  
  bool _isInitialized = false;

  /// Initialise le tracker
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    print('📱 AppLifecycleTracker initialisé');
  }

  /// Dispose le tracker
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    print('📱 AppLifecycleTracker désactivé');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }

  /// Appelé quand l'application reprend
  void _onAppResumed() {
    print('📱 App reprend - Enregistrement ouverture');
    _recordAppOpen();
  }

  /// Appelé quand l'application est mise en pause
  void _onAppPaused() {
    print('📱 App mise en pause');
  }

  /// Appelé quand l'application devient inactive
  void _onAppInactive() {
    print('📱 App inactive');
  }

  /// Appelé quand l'application est détachée
  void _onAppDetached() {
    print('📱 App détachée');
  }

  /// Appelé quand l'application est cachée
  void _onAppHidden() {
    print('📱 App cachée');
  }

  /// Enregistre l'ouverture de l'application
  Future<void> _recordAppOpen() async {
    try {
      await IntelligentAlarmService.recordAppOpen();
      print('📱 Ouverture app enregistrée avec succès');
    } catch (e) {
      print('❌ Erreur enregistrement ouverture app: $e');
    }
  }

  /// Obtient le timestamp de la dernière ouverture
  Future<DateTime?> getLastAppOpenTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(LAST_APP_OPEN_KEY);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      print('❌ Erreur obtention dernière ouverture: $e');
      return null;
    }
  }

  /// Vérifie si l'app a été ouverte récemment (dans les X minutes)
  Future<bool> wasAppOpenedRecently({int minutes = 10}) async {
    try {
      final lastOpen = await getLastAppOpenTime();
      if (lastOpen == null) return false;
      
      final now = DateTime.now();
      final difference = now.difference(lastOpen);
      
      return difference.inMinutes <= minutes;
    } catch (e) {
      print('❌ Erreur vérification ouverture récente: $e');
      return false;
    }
  }

  /// Force l'enregistrement d'une ouverture (utile pour les tests)
  Future<void> forceRecordAppOpen() async {
    await _recordAppOpen();
  }
}
