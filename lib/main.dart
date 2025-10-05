import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:essai/router.dart';
import 'services/reader_settings_service.dart';
import 'views/reader_page_modern.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activer le runtime fetching de Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;
  
  runApp(
    const ProviderScope(
      child: SelahApp(),
    ),
  );
}

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});

  @override
  Widget build(BuildContext context) {
          return provider.ChangeNotifierProvider(
            create: (context) => ReaderSettingsService(),
            child: MaterialApp(
              title: 'Selah',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                fontFamily: 'Inter',
              ),
              initialRoute: '/test',
              onGenerateRoute: (settings) {
                // Protection pour les pages de méditation
                if (settings.name == '/meditation/qcm') {
                  final args = settings.arguments as Map?;
                  if (args == null || (args['passageRef'] ?? '').isEmpty) {
                    return MaterialPageRoute(builder: (_) => const ReaderPageModern());
                  }
                }
                
                if (settings.name == '/meditation/free') {
                  final args = settings.arguments as Map?;
                  if (args == null || (args['passageRef'] ?? '').isEmpty) {
                    return MaterialPageRoute(builder: (_) => const ReaderPageModern());
                  }
                }
                
                // Routes normales
                final routeBuilder = AppRouter.routes[settings.name];
                if (routeBuilder != null) {
                  return MaterialPageRoute(
                    builder: routeBuilder,
                    settings: settings,
                  );
                }
                
                // Route par défaut
                return MaterialPageRoute(
                  builder: (_) => const ReaderPageModern(),
                );
              },
            ),
          );
  }
}


