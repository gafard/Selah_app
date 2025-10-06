abstract class Telemetry {
  void track(String event, [Map<String, dynamic>? properties]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}