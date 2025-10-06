import 'package:flutter/material.dart';
import 'lib/widgets/selah_logo.dart';

/// Test simple pour vérifier l'intégration des logos Selah
/// 
/// Ce fichier peut être exécuté pour tester que tous les widgets
/// de logo fonctionnent correctement.
void main() {
  runApp(const LogoTestApp());
}

class LogoTestApp extends StatelessWidget {
  const LogoTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Logo Selah',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LogoTestPage(),
    );
  }
}

class LogoTestPage extends StatelessWidget {
  const LogoTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Logo Selah'),
        backgroundColor: const Color(0xFF1553FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test des icônes
            const Text(
              'Icônes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Fond bleu'),
                    SizedBox(height: 8),
                    SelahAppIcon(size: 48, useBlueBackground: true),
                  ],
                ),
                Column(
                  children: [
                    Text('Fond blanc'),
                    SizedBox(height: 8),
                    SelahAppIcon(size: 48, useBlueBackground: false),
                  ],
                ),
                Column(
                  children: [
                    Text('Transparent'),
                    SizedBox(height: 8),
                    SelahLogo(
                      variant: SelahLogoVariant.transparent,
                      width: 48,
                      height: 48,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Test des lockups
            const Text(
              'Lockups',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Column(
              children: [
                Text('Header Logo'),
                SizedBox(height: 8),
                SelahHeaderLogo(height: 32),
                SizedBox(height: 16),
                Text('Splash Logo'),
                SizedBox(height: 8),
                SelahSplashLogo(size: 100),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Test avec couleurs personnalisées
            const Text(
              'Couleurs personnalisées',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SelahLogo(
                  variant: SelahLogoVariant.transparent,
                  width: 48,
                  height: 48,
                  color: Color(0xFF1553FF),
                ),
                SelahLogo(
                  variant: SelahLogoVariant.transparent,
                  width: 48,
                  height: 48,
                  color: Color(0xFF49C98D),
                ),
                SelahLogo(
                  variant: SelahLogoVariant.transparent,
                  width: 48,
                  height: 48,
                  color: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Test d'intégration dans un contexte
            const Text(
              'Intégration dans un contexte',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page d\'accueil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SelahAppIcon(size: 32, useBlueBackground: false),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1553FF), Color(0xFF49C98D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SelahSplashLogo(size: 80),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Message de succès
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF49C98D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF49C98D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF49C98D)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ Tous les logos Selah fonctionnent correctement !',
                      style: TextStyle(
                        color: Color(0xFF2F9E75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
