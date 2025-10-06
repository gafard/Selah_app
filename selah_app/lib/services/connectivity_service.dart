import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion de la connectivité et des fonctionnalités online/offline
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  bool get isOnline => _isOnline;
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  /// Initialise le service et écoute les changements de connectivité
  Future<void> init() async {
    // Vérifier l'état initial
    _connectionStatus = await _connectivity.checkConnectivity();
    _isOnline = _connectionStatus != [ConnectivityResult.none];
    
    // Écouter les changements
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    
    notifyListeners();
  }

  /// Met à jour l'état de connectivité
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _connectionStatus = result;
    final wasOnline = _isOnline;
    _isOnline = result != [ConnectivityResult.none];
    
    if (wasOnline != _isOnline) {
      notifyListeners();
      
      // Log du changement
      if (kDebugMode) {
        print('🌐 Connectivité changée: ${_isOnline ? "EN LIGNE" : "HORS LIGNE"}');
        print('   Types: ${result.join(", ")}');
      }
    }
  }

  /// Vérifie si une fonctionnalité nécessite Internet
  bool requiresInternet(String feature) {
    const onlineFeatures = {
      'create_account': true,
      'sign_in': true,
      'download_bible': true,
      'generate_plan': true,
      'import_plan': true,
      'sync_data': true,
    };
    
    return onlineFeatures[feature] ?? false;
  }

  /// Vérifie si une fonctionnalité est disponible
  bool isFeatureAvailable(String feature) {
    if (!requiresInternet(feature)) {
      return true; // Toujours disponible offline
    }
    
    return _isOnline; // Nécessite Internet
  }

  /// Retourne un message d'erreur approprié pour une fonctionnalité
  String getFeatureErrorMessage(String feature) {
    if (!requiresInternet(feature)) {
      return 'Fonctionnalité disponible offline';
    }
    
    if (_isOnline) {
      return 'Fonctionnalité disponible';
    }
    
    return 'Connexion Internet requise pour $feature';
  }

  /// Retourne les fonctionnalités disponibles selon la connectivité
  Map<String, bool> getAvailableFeatures() {
    return {
      'read_bible': true, // Toujours disponible (stockage local)
      'view_plans': true, // Toujours disponible (stockage local)
      'track_progress': true, // Toujours disponible (stockage local)
      'take_quiz': true, // Toujours disponible (stockage local)
      'view_stats': true, // Toujours disponible (stockage local)
      'create_account': _isOnline,
      'sign_in': _isOnline,
      'download_bible': _isOnline,
      'generate_plan': _isOnline,
      'import_plan': _isOnline,
      'sync_data': _isOnline,
    };
  }

  /// Retourne le type de connexion actuel
  String getConnectionType() {
    if (!_isOnline) return 'Aucune connexion';
    
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Données mobiles';
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else {
      return 'Autre';
    }
  }

  /// Retourne la qualité de connexion estimée
  String getConnectionQuality() {
    if (!_isOnline) return 'Aucune';
    
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'Excellente';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Variable';
    } else {
      return 'Inconnue';
    }
  }

  /// Vérifie si la connexion est stable (pour les opérations longues)
  bool get isConnectionStable {
    if (!_isOnline) return false;
    
    // WiFi est considéré comme stable
    return _connectionStatus.contains(ConnectivityResult.wifi);
  }

  /// Retourne des recommandations selon l'état de connectivité
  List<String> getRecommendations() {
    final recommendations = <String>[];
    
    if (!_isOnline) {
      recommendations.addAll([
        'Vous êtes hors ligne. Toutes les fonctionnalités de lecture sont disponibles.',
        'La synchronisation se fera automatiquement quand vous serez en ligne.',
        'Vous pouvez télécharger des versions de Bible quand vous aurez Internet.',
      ]);
    } else if (!isConnectionStable) {
      recommendations.addAll([
        'Connexion mobile détectée. Les téléchargements peuvent être lents.',
        'Connectez-vous au WiFi pour une meilleure expérience.',
        'Toutes les fonctionnalités sont disponibles.',
      ]);
    } else {
      recommendations.addAll([
        'Connexion WiFi excellente. Toutes les fonctionnalités sont disponibles.',
        'Vous pouvez télécharger de nouvelles versions de Bible.',
        'La synchronisation se fait automatiquement.',
      ]);
    }
    
    return recommendations;
  }
}