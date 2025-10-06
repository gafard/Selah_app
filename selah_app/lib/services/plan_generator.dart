import 'package:intl/intl.dart';
import '../models/plan_preset.dart';

class GeneratedPlanDay {
  final int dayNumber;
  final DateTime date;
  final List<String> references; // ex: ["Matthieu 1–3"] ou ["Proverbes 1"]

  GeneratedPlanDay({
    required this.dayNumber, 
    required this.date, 
    required this.references
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
  String get dayOfWeek => DateFormat('EEEE', 'fr_FR').format(date);
}

class PlanGenerator {
  /// point d'entrée : génère les références quotidiennes à partir d'un preset + startDate
  static List<GeneratedPlanDay> generate(PlanPreset preset, DateTime startDate) {
    switch (preset.rule) {
      case 'NT_90_LINEAR':
        return _nt90(startDate);
      case 'PROVERBS_31':
        return _proverbs31(startDate);
      case 'PSALMS_40':
        return _psalmsRange(startDate,
            start: preset.params['start'] ?? 1,
            end: preset.params['end'] ?? 80,
            perDay: preset.params['per_day'] ?? 2);
      case 'RANGE_SPLIT': // ex: Genèse 1–25 sur 14 jours
        return _rangeSplit(startDate,
            book: preset.params['book'] ?? 'Genèse',
            startCh: preset.params['start_ch'] ?? 1,
            endCh: preset.params['end_ch'] ?? 25,
            days: preset.params['days'] ?? preset.durationDays);
      case 'SEQUENCE_CHAPTERS': // liste de {book, chapters}
        return _sequenceChapters(startDate, preset.params['sequence']);
      default:
        // "COMING_SOON" : on renvoie une liste vide (le preset s'affiche mais non générable)
        return <GeneratedPlanDay>[];
    }
  }

  // ===== RÈGLES IMPLÉMENTÉES =====

  // NT : Matthew(28), Mark(16), Luke(24), John(21), Acts(28), Rom(16), 1Co(16), 2Co(13),
  // Gal(6), Eph(6), Phil(4), Col(4), 1Th(5), 2Th(3), 1Ti(6), 2Ti(4), Titus(3), Phm(1),
  // Heb(13), Jas(5), 1Pe(5), 2Pe(3), 1Jn(5), 2Jn(1), 3Jn(1), Jude(1), Rev(22) = 260 chap.
  static List<GeneratedPlanDay> _nt90(DateTime start) {
    final books = <String, int>{
      'Matthieu': 28, 'Marc': 16, 'Luc': 24, 'Jean': 21, 'Actes': 28,
      'Romains': 16, '1 Corinthiens': 16, '2 Corinthiens': 13, 'Galates': 6, 'Éphésiens': 6,
      'Philippiens': 4, 'Colossiens': 4, '1 Thessaloniciens': 5, '2 Thessaloniciens': 3,
      '1 Timothée': 6, '2 Timothée': 4, 'Tite': 3, 'Philémon': 1, 'Hébreux': 13, 'Jacques': 5,
      '1 Pierre': 5, '2 Pierre': 3, '1 Jean': 5, '2 Jean': 1, '3 Jean': 1, 'Jude': 1, 'Apocalypse': 22,
    };

    // 260 chap / 90 ≈ 2-3 chap/jour → motif 2,3,3
    final pattern = [2, 3, 3];
    var pIdx = 0;

    final out = <GeneratedPlanDay>[];
    var day = 1;
    var date = start;

    String currentBook = books.keys.first;
    var chapter = 1;

    while (day <= 90) {
      final todayCount = pattern[pIdx % pattern.length];
      pIdx++;

      var remaining = todayCount;
      final refs = <String>[];

      while (remaining > 0 && currentBook.isNotEmpty) {
        final totalCh = books[currentBook]!;
        final startCh = chapter;
        final take = (chapter + remaining - 1 <= totalCh)
            ? remaining
            : (totalCh - chapter + 1);
        final endCh = startCh + take - 1;
        refs.add(take == 1
            ? '$currentBook $startCh'
            : '$currentBook $startCh–$endCh');

        remaining -= take;
        chapter += take;

        if (chapter > totalCh) {
          // passer au livre suivant
          final keys = books.keys.toList();
          final idx = keys.indexOf(currentBook);
          currentBook = (idx + 1 < keys.length) ? keys[idx + 1] : '';
          chapter = 1;
        }
      }

      out.add(GeneratedPlanDay(dayNumber: day, date: date, references: refs));
      day++;
      date = date.add(const Duration(days: 1));
    }
    return out;
  }

  static List<GeneratedPlanDay> _proverbs31(DateTime start) {
    final out = <GeneratedPlanDay>[];
    for (int i = 1; i <= 31; i++) {
      out.add(GeneratedPlanDay(
        dayNumber: i,
        date: start.add(Duration(days: i - 1)),
        references: ['Proverbes $i'],
      ));
    }
    return out;
  }

  static List<GeneratedPlanDay> _psalmsRange(DateTime startDate, {required int start, required int end, required int perDay}) {
    final out = <GeneratedPlanDay>[];
    var ps = start;
    var day = 1;
    DateTime date = startDate;

    while (ps <= end) {
      final todays = <String>[];
      for (int k = 0; k < perDay && ps <= end; k++) {
        todays.add('Psaume $ps');
        ps++;
      }
      out.add(GeneratedPlanDay(dayNumber: day, date: date, references: todays));
      day++;
      date = date.add(const Duration(days: 1));
    }
    return out;
  }

  static List<GeneratedPlanDay> _rangeSplit(DateTime start, {required String book, required int startCh, required int endCh, required int days}) {
    final total = endCh - startCh + 1;
    final base = total ~/ days;     // chapitres pleins par jour
    var extra = total % days;       // jours qui prennent +1

    final out = <GeneratedPlanDay>[];
    var current = startCh;
    var date = start;

    for (int d = 1; d <= days; d++) {
      final take = base + (extra > 0 ? 1 : 0);
      if (extra > 0) extra--;

      final s = current;
      final e = (current + take - 1).clamp(startCh, endCh);
      current = e + 1;

      final ref = (s == e) ? '$book $s' : '$book $s–$e';
      out.add(GeneratedPlanDay(dayNumber: d, date: date, references: [ref]));
      date = date.add(const Duration(days: 1));
    }
    return out;
  }

  static List<GeneratedPlanDay> _sequenceChapters(DateTime start, dynamic sequence) {
    final out = <GeneratedPlanDay>[];
    var day = 1;
    var date = start;

    for (final seg in (sequence as List)) {
      final book = seg['book'] as String;
      final chs = seg['chapters'] as int;
      for (int c = 1; c <= chs; c++) {
        out.add(GeneratedPlanDay(
          dayNumber: day++,
          date: date,
          references: ['$book $c'],
        ));
        date = date.add(const Duration(days: 1));
      }
    }
    return out;
  }
}
