
class Plan {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final int totalDays;
  final bool isActive;
  final String books;
  final String? specificBooks;
  final int minutesPerDay;
  final List<int>? daysOfWeek; // ✅ NOUVEAU - Jours de lecture (1=Lun, 7=Dim)

  Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.totalDays,
    required this.isActive,
    required this.books,
    this.specificBooks,
    required this.minutesPerDay,
    this.daysOfWeek, // ✅ NOUVEAU
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'],
        userId: j['user_id'],
        name: j['name'],
        startDate: DateTime.parse(j['start_date']),
        totalDays: j['total_days'],
        isActive: j['is_active'] ?? false,
        books: j['books'] ?? '',
        specificBooks: j['specific_books'],
        minutesPerDay: j['minutes_per_day'] ?? 15,
        daysOfWeek: (j['days_of_week'] as List?)?.cast<int>(), // ✅ NOUVEAU
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'start_date': startDate.toIso8601String(),
        'total_days': totalDays,
        'is_active': isActive,
        'books': books,
        'specific_books': specificBooks,
        'minutes_per_day': minutesPerDay,
        'days_of_week': daysOfWeek, // ✅ NOUVEAU
      };
}

class PlanDay {
  final String id;
  final String planId;
  final int dayIndex; // 1..N
  final DateTime date;
  final List<ReadingRef> readings;
  final bool completed;

  PlanDay({
    required this.id,
    required this.planId,
    required this.dayIndex,
    required this.date,
    required this.readings,
    required this.completed,
  });

  factory PlanDay.fromJson(Map jAny) {
    final j = Map<String, dynamic>.from(jAny);

    final readingsRaw = (j['readings'] as List? ?? const []);
    final readings = readingsRaw
        .map((e) => ReadingRef.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PlanDay(
      id: j['id'].toString(),
      planId: j['plan_id'].toString(),
      dayIndex: (j['day_index'] is int)
          ? j['day_index'] as int
          : int.tryParse(j['day_index'].toString()) ?? 1,
      date: (j['date'] is DateTime)
          ? j['date'] as DateTime
          : DateTime.parse(j['date'].toString()),
      readings: readings,
      completed: (j['completed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'day_index': dayIndex,
        'date': date.toIso8601String(),
        'readings': readings.map((e) => e.toJson()).toList(),
        'completed': completed,
      };
}

class ReadingRef {
  final String book;   // ex: "Jean"
  final String range;  // ex: "3:16-4:10"
  final String? url;

  ReadingRef({required this.book, required this.range, this.url});

  /// Accepte String **ou** Map legacy (range/reference)
  factory ReadingRef.fromJson(Map jAny) {
    final j = Map<String, dynamic>.from(jAny);

    // book
    final book = (j['book'] ?? 'Jean').toString();

    // range: accepter "3:16-4:10" (String) ou {"range":"..."} / {"reference":"..."}
    final raw = j['range'];
    String range;
    if (raw is String) {
      range = raw;
    } else if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      range = (m['range'] ?? m['reference'] ?? '1:1').toString();
    } else {
      range = '1:1';
    }

    return ReadingRef(book: book, range: range, url: (j['url'] as String?));
  }

  Map<String, dynamic> toJson() => {'book': book, 'range': range, 'url': url};
  
  @override
  String toString() => '$book $range';
}

class PlanProgress {
  final String planId;
  final int done;
  final int total;
  double get ratio => total == 0 ? 0 : done / total;

  PlanProgress({required this.planId, required this.done, required this.total});
}
