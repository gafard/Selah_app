import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class GeneratedDay {
  final DateTime date;
  final List<String> readings;
  GeneratedDay(this.date, this.readings);
}

class RemotePlanGenerator {
  static const String base = 'https://www.biblereadingplangenerator.com/';

  /// Construit l'URL avec les bons paramètres.
  static Uri buildUrl({
    required DateTime start,
    required int totalDays,
    required String format,       // 'calendar' (site), on tentera 'csv' d'abord
    required String order,        // 'traditional' | 'chronological'
    required String books,        // 'OT,NT' | 'NT' | 'OT'
    required String lang,         // 'fr'
    required String urlsite,      // 'biblegateway', 'biblecom', etc.
    required String urlversion,   // 'LSG'/'S21'/'NIV' etc.
    bool dailyPsalm = false,
    bool dailyProverb = false,
    bool otntOverlap = false,
    String logic = 'words',
  }) {
    final params = {
      'start': _fmtDate(start),
      'total': '$totalDays',
      'format': format, // 'calendar' (fallback), on essayera 'csv' en premier
      'order': order,
      'daysofweek': '1,2,3,4,5,6,7',
      'books': books,           // ex: 'OT,NT'
      'lang': lang,             // 'fr'
      'logic': logic,
      'checkbox': '1',
      'colors': '0',
      'dailypsalm': dailyPsalm ? '1' : '0',
      'dailyproverb': dailyProverb ? '1' : '0',
      'otntoverlap': otntOverlap ? '1' : '0',
      'reverse': '0',
      'stats': '0',
      'dailystats': '0',
      'nodates': '0',
      'includeurls': '0',
      'urlsite': urlsite,       // 'biblegateway'
      'urlversion': urlversion, // 'LSG', 'NIV', ...
    };
    return Uri.parse(base).replace(queryParameters: params);
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Essaie CSV puis fallback HTML "calendar".
  static Future<List<GeneratedDay>> fetchPlan(Uri calendarUrl) async {
    // 1) tentative CSV: remplace format=calendar -> csv
    final csvUrl = calendarUrl.replace(queryParameters: {
      ...calendarUrl.queryParameters,
      'format': 'csv',
    });

    final csvResp = await http.get(csvUrl);
    if (csvResp.statusCode == 200 && csvResp.body.contains(',')) {
      return _parseCsv(csvResp.body);
    }

    // 2) fallback calendar (HTML simple)
    final htmlResp = await http.get(calendarUrl);
    if (htmlResp.statusCode == 200) {
      return _parseCalendarHtml(htmlResp.body);
    }

    throw Exception('Échec téléchargement plan (${csvResp.statusCode}/${htmlResp.statusCode}).');
  }

  // CSV attendu: date,reading(s)
  static List<GeneratedDay> _parseCsv(String csv) {
    final lines = const LineSplitter().convert(csv).where((l) => l.trim().isNotEmpty).toList();
    // en général: en-tête sur la 1re ligne
    final startIndex = lines.first.toLowerCase().contains('date') ? 1 : 0;
    final out = <GeneratedDay>[];
    for (var i = startIndex; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.isEmpty) continue;
      final date = DateTime.tryParse(parts[0].trim()) ?? DateTime.now();
      final readings = parts.skip(1).join(',').split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      out.add(GeneratedDay(date, readings));
    }
    return out;
  }

  // Parsing "léger" : récupère lignes avec dates et lectures (ex: <td>2025-11-01</td> ...).
  static List<GeneratedDay> _parseCalendarHtml(String html) {
    final out = <GeneratedDay>[];
    final dateRegex = RegExp(r'(\d{4}-\d{2}-\d{2})');
    // Simpliste: une ligne = un bloc jour contenant la date puis les lectures séparées par <br> ou ;
    final rowRegex = RegExp(r'<tr[^>]*>(.*?)</tr>', multiLine: true, dotAll: true);
    for (final m in rowRegex.allMatches(html)) {
      final row = m.group(1) ?? '';
      final dateMatch = dateRegex.firstMatch(row);
      if (dateMatch == null) continue;
      final date = DateTime.tryParse(dateMatch.group(1)!);
      if (date == null) continue;

      // récupère ce qui ressemble à la colonne des lectures
      // cherche balises <td> après la date
      final tds = RegExp(r'<td[^>]*>(.*?)</td>', multiLine: true, dotAll: true)
          .allMatches(row)
          .map((m) => _stripHtml(m.group(1)!))
          .toList();
      // heuristique: dernière/avant-dernière cellule contient les lectures
      final candidates = tds.reversed.take(2).join(' ; ');
      final readings = candidates
          .split(RegExp(r'[;•\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !dateRegex.hasMatch(s))
          .toList();
      if (readings.isEmpty) continue;

      out.add(GeneratedDay(date, readings));
    }
    return out;
  }

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), ' ')
       .replaceAll('&nbsp;', ' ')
       .replaceAll('&amp;', '&')
       .replaceAll(RegExp(r'\s+'), ' ')
       .trim();

  /// Sauvegarde Hive (offline)
  static Future<void> cachePlan({
    required String planId,
    required List<GeneratedDay> days,
    required Map<String, dynamic> meta,
  }) async {
    final box = await Hive.openBox('readingPlan');
    await box.put('meta', {'id': planId, ...meta});
    await box.put('days', days.map((d) => {
      'date': d.date.toIso8601String(),
      'readings': d.readings,
    }).toList());
  }
}

