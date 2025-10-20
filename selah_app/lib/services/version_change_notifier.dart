import 'dart:async';

/// Service simple pour notifier les changements de version de Bible
class VersionChangeNotifier {
  static final StreamController<String> _versionController = StreamController<String>.broadcast();
  
  /// Stream des changements de version
  static Stream<String> get versionStream => _versionController.stream;
  
  /// Notifie un changement de version
  static void notifyVersionChange(String newVersion) {
    _versionController.add(newVersion);
    print('📢 VersionChangeNotifier: Version changée vers $newVersion');
  }
  
  /// Libère les ressources
  static void dispose() {
    _versionController.close();
  }
}

