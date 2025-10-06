import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class BibleVersion {
  final String code;   // ex: 'LSG'
  final String name;   // ex: 'Louis Segond'
  BibleVersion(this.code, this.name);
}

class BibleVersionsService {
  // Ajuste l'URL selon ton déploiement de wldeh/bible-api
  static const String _base = 'https://YOUR_BIBLE_API_HOST'; 
  // Exemple possibles selon implémentation: '/versions' ; sinon expose un endpoint custom.
  static const String _versionsPath = '/versions';

  static Future<List<BibleVersion>> fetchVersions({bool forceRefresh = false}) async {
    final box = await Hive.openBox('bible_versions');
    if (!forceRefresh && box.containsKey('all')) {
      final cached = (box.get('all') as List).cast<Map>().toList();
      return cached.map((m) => BibleVersion(m['code'] as String, m['name'] as String)).toList();
    }

    final uri = Uri.parse('$_base$_versionsPath');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      // fallback cache si dispo
      if (box.containsKey('all')) {
        final cached = (box.get('all') as List).cast<Map>().toList();
        return cached.map((m) => BibleVersion(m['code'] as String, m['name'] as String)).toList();
      }
      throw Exception('Impossible de récupérer les versions (${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body);
    // Adapte selon le schéma de ta Bible API :
    // On s'attend à un tableau d'objets { code: 'LSG', name: 'Louis Segond' }
    final versions = (data as List).map((e) => BibleVersion(e['code'], e['name'])).toList();

    await box.put('all', versions.map((v) => {'code': v.code, 'name': v.name}).toList());
    return versions;
  }
}

