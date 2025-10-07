import 'dart:convert';

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

  factory PlanDay.fromJson(Map<String, dynamic> j) => PlanDay(
        id: j['id'],
        planId: j['plan_id'],
        dayIndex: j['day_index'],
        date: DateTime.parse(j['date']),
        readings: (j['readings'] as List).map((e) => ReadingRef.fromJson(e)).toList(),
        completed: j['completed'] ?? false,
      );

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
  final String book; // ex: "Jean"
  final String range; // ex: "3:16-4:10"
  final String? url; // lien BibleGateway/BOLLS/NBS si dispo

  ReadingRef({required this.book, required this.range, this.url});

  factory ReadingRef.fromJson(Map<String, dynamic> j) =>
      ReadingRef(book: j['book'], range: j['range'], url: j['url']);

  Map<String, dynamic> toJson() => {'book': book, 'range': range, 'url': url};
}

class PlanProgress {
  final String planId;
  final int done;
  final int total;
  double get ratio => total == 0 ? 0 : done / total;

  PlanProgress({required this.planId, required this.done, required this.total});
}
