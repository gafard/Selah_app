import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/user_prefs_hive.dart';
import 'services/background_tasks.dart';
import 'viewmodels/home_vm.dart';
import 'views/home_page.dart'; // ton widget existant

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await UserPrefsHive.init();
  await BackgroundTasks.setup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeVM()..bootstrap()),
      ],
      child: const SelahApp(),
    ),
  );
}

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Selah',
      debugShowCheckedModeBanner: false,
      home: HomePageWidget(), // ou ton router
    );
  }
}

