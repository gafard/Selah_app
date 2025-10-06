import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:essai/router.dart';
import 'services/reader_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activer le runtime fetching de Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;
  
  runApp(
    ProviderScope(
      child: const SelahApp(),
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
              routes: AppRouter.routes,
            ),
          );
  }
}


