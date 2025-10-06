import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:http/http.dart' as http;

import '../domain/user_prefs.dart';
import '../domain/plan_repo.dart';
import '../infra/plan_service_http.dart';
import '../domain/bible_repo.dart';
import '../infra/bible_repo_http.dart';
import '../domain/telemetry.dart';
import '../infra/telemetry_console.dart';
import '../services/home_vm.dart';

List<SingleChildWidget> appProviders({
  required UserPrefs userPrefs,
}) {
  final httpClient = http.Client();

  return [
    Provider<UserPrefs>.value(value: userPrefs),
    Provider<PlanRepo>(create: (_) => PlanServiceHttp(httpClient)),
    Provider<BibleRepo>(create: (_) => BibleRepoHttp(httpClient)),
    Provider<Telemetry>(create: (_) => TelemetryConsole()),
    ChangeNotifierProvider(create: (ctx) => HomeVM(
      prefs: ctx.read<UserPrefs>(),
      plans: ctx.read<PlanRepo>(),
      bible: ctx.read<BibleRepo>(),
      telemetry: ctx.read<Telemetry>(),
    )..load()),
  ];
}
