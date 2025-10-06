import 'package:http/http.dart' as http;
import '../domain/bible_repo.dart';

class BibleRepoHttp implements BibleRepo {
  final http.Client _client;
  
  BibleRepoHttp(this._client);

  @override
  Future<void> prefetch(List<String> passageRefs) async {
    // Télécharge et cache les passages pour usage offline
    for (final ref in passageRefs) {
      try {
        await fetchPassage(ref);
        // Dans une vraie implémentation, on sauvegarderait en cache local
      } catch (e) {
        // Log l'erreur mais continue avec les autres passages
        print('Erreur préchargement $ref: $e');
      }
    }
  }

  @override
  Future<String> fetchPassage(String passageRef) async {
    // Mock pour l'instant - dans une vraie implémentation, on appellerait une API biblique
    await Future.delayed(const Duration(milliseconds: 200));
    return 'Texte du passage $passageRef...';
  }

  @override
  Future<void> downloadVersion(String version) async {
    // Télécharge une version complète de la Bible
    // Mock pour l'instant
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<List<dynamic>> versions() async {
    // Mock pour l'instant
    return [
      {'id': 'LSG', 'name': 'Louis Segond 1910'},
      {'id': 'NIV', 'name': 'New International Version'},
      {'id': 'ESV', 'name': 'English Standard Version'},
    ];
  }
}
