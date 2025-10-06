import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'bootstrap.dart';
import 'state/app_state.dart';
import 'services/home_vm.dart';
import 'services/plan_service.dart';
import 'services/connectivity_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://rvwwgvzuwlxnnzumsqvg.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2d3dndnp1d2x4bm56dW1zcXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MDY3NTIsImV4cCI6MjA3NDk4Mjc1Mn0.FK28ps82t97Yo9vz9CB7FbKpo-__YnXYo8GHIw-8GmQ'),
  );
  
  await appBootstrap();
  runApp(const SelahApp());
}

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: userPrefs),
        Provider.value(value: telemetry),
        Provider.value(value: syncQueue),
        Provider.value(value: background),
        Provider<PlanService>.value(value: planService),
        ChangeNotifierProvider.value(value: connectivityService),
        ChangeNotifierProvider(create: (_) => AppState(syncQueue: syncQueue)),
        ChangeNotifierProvider(create: (_) => HomeVM(
          prefs: userPrefs,
          telemetry: telemetry,
          planService: planService,
        )..load()),
      ],
      child: MaterialApp(
        title: 'Selah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
        ),
        initialRoute: '/splash',
        routes: AppRouter.routes,
        onUnknownRoute: (settings) {
          // Fallback vers la page d'accueil si route inconnue
          return MaterialPageRoute(
            builder: (context) => AppRouter.routes['/home']!(context),
          );
        },
      ),
    );
  }
}