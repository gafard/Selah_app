import 'dart:convert';

class SyncTask {
  final String id;                // uuid/ts
  final String type;              // ex: 'profile_sync'
  final Map<String, dynamic> payload;
  final String idempotencyKey;    // par ex "onboarding_...microseconds"
  final int maxRetries;
  final int backoffMs;
  final int attempt;

  SyncTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.idempotencyKey,
    this.maxRetries = 5,
    this.backoffMs = 1500,
    this.attempt = 0,
  });

  SyncTask copyWith({int? attempt}) =>
      SyncTask(
        id: id,
        type: type,
        payload: payload,
        idempotencyKey: idempotencyKey,
        maxRetries: maxRetries,
        backoffMs: backoffMs,
        attempt: attempt ?? this.attempt,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'payload': payload,
    'idempotencyKey': idempotencyKey,
    'maxRetries': maxRetries,
    'backoffMs': backoffMs,
    'attempt': attempt,
  };

  factory SyncTask.fromMap(Map<String, dynamic> m) => SyncTask(
    id: m['id'] as String,
    type: m['type'] as String,
    payload: Map<String, dynamic>.from(m['payload'] as Map),
    idempotencyKey: m['idempotencyKey'] as String,
    maxRetries: (m['maxRetries'] ?? 5) as int,
    backoffMs: (m['backoffMs'] ?? 1500) as int,
    attempt: (m['attempt'] ?? 0) as int,
  );

  String toJson() => jsonEncode(toMap());
  factory SyncTask.fromJson(String s) => SyncTask.fromMap(jsonDecode(s));
}

String newTaskId() => DateTime.now().microsecondsSinceEpoch.toString();


