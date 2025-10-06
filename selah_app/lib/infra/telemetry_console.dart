import '../domain/telemetry.dart';

class TelemetryConsole implements Telemetry {
  @override
  void track(String event, [Map<String, dynamic>? properties]) {
    print('📊 Event: $event${properties != null ? ' | Properties: $properties' : ''}');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('❌ Error: $message');
    if (error != null) print('   Details: $error');
    if (stackTrace != null) print('   Stack: $stackTrace');
  }
}

