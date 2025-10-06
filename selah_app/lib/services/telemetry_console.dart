class TelemetryConsole {
  void event(String name, [Map<String, dynamic>? props]) {
    // eslint: print volontaire
    // ignore: avoid_print
    print('[telemetry] $name ${props ?? {}}');
  }
}