import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

String buildGeneratorIcsUrl({
  required DateTime start,
  required int totalDays,
  required String order,
  required List<int> daysOfWeek,    // 1..7 (Lun..Dim pour l'UI, le générateur accepte 1..7)
  required String books,            // 'OT,NT' / 'NT' / ...
  required String lang,             // 'fr'
  required String logic,            // 'words'
  required bool includeUrls,        // true/false
  required String urlSite,          // 'biblegateway'
  required String urlVersion,       // 'NIV' / 'LSG'...
}) {
  final startStr = '${start.year.toString().padLeft(4,'0')}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}';
  final params = {
    'start': startStr,
    'total': totalDays.toString(),
    'format': 'calendar',
    'order': order,
    'daysofweek': daysOfWeek.join(','),
    'books': books,
    'lang': lang,
    'logic': logic,
    'checkbox': '1',
    'colors': '0',
    'dailypsalm': '0',
    'dailyproverb': '0',
    'otntoverlap': '0',
    'reverse': '0',
    'stats': '0',
    'dailystats': '0',
    'nodates': '0',
    'includeurls': includeUrls ? '1' : '0',
    'urlsite': urlSite,
    'urlversion': urlVersion,
  };
  final q = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  return 'https://www.biblereadingplangenerator.com/?$q';
}

/// Télécharge l'ICS généré, parse minimal, et stocke localement un plan lisible offline.
/// Retourne un id de plan.
Future<String> importPlanFromGenerator({
  required String userId,
  required String planName,
  required String icsUrl,
}) async {
  final resp = await http.get(Uri.parse(icsUrl));
  if (resp.statusCode != 200) {
    throw Exception('Générateur indisponible (${resp.statusCode})');
  }
  final ics = resp.body;

  // Stockage local (brut + préparse minimal)
  final box = await Hive.openBox('plans');
  final planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
  await box.put(planId, {
    'id': planId,
    'name': planName,
    'createdAt': DateTime.now().toIso8601String(),
    'ics': ics,
    'source': 'generator',
    'progress': {'day': 1, 'done': []},
  });

  // Plan courant
  final prefs = await Hive.openBox('prefs');
  await prefs.put('current_plan_id', planId);

  return planId;
}