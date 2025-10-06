// Exemple d'utilisation des pages de scan de Bible
// Ce fichier montre comment intégrer les pages de scan dans votre application

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../views/scan_bible_page.dart';
import '../views/advanced_scan_bible_page.dart';
import '../widgets/scan_bible_banner.dart';
import '../widgets/modern_scan_bible_banner.dart';

class ScanBiblePagesExample {
  
  /// Exemple d'utilisation de la page de scan simple
  static Future<void> openSimpleScanPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanBiblePage(),
      ),
    );
  }
  
  /// Exemple d'utilisation de la page de scan avancée
  static Future<void> openAdvancedScanPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdvancedScanBiblePage(),
      ),
    );
  }
  
  /// Exemple d'utilisation avec le banner de scan
  static Widget buildPageWithScanBanner(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1B3A),
              Color(0xFF2D1B69),
              Color(0xFF1C1740),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Exemple avec Banner',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenu principal
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: [
                    // Banner de scan moderne
                    ModernScanBibleBanner(
                      onTap: () => openSimpleScanPage(context),
                    ),
                    const SizedBox(height: 20),
                    
                    // Banner de scan subtil
                    const SubtleScanBibleBanner(
                      onTap: _handleScanTap,
                    ),
                    const SizedBox(height: 20),
                    
                    // Autres éléments...
                    _buildContentCard('Élément 1'),
                    const SizedBox(height: 16),
                    _buildContentCard('Élément 2'),
                    const SizedBox(height: 16),
                    _buildContentCard('Élément 3'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Exemple d'utilisation avec design clair
  static Widget buildLightThemePage(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Design Clair',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu principal
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: [
                  // Banner de scan avec design clair
                  ScanBibleBanner(
                    onTap: () => openSimpleScanPage(context),
                  ),
                  const SizedBox(height: 20),
                  
                  // Autres éléments...
                  _buildLightCard('Élément 1'),
                  const SizedBox(height: 16),
                  _buildLightCard('Élément 2'),
                  const SizedBox(height: 16),
                  _buildLightCard('Élément 3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Méthodes utilitaires pour construire les widgets
  
  static Widget _buildContentCard(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
  
  static Widget _buildLightCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
  
  // Gestionnaire de tap pour le scan
  static void _handleScanTap() {
    print('Scanner la page de Bible...');
    // Ici vous pouvez implémenter la logique de scan
  }
}

/// Widget de test pour toutes les pages de scan
class ScanBiblePagesTestPage extends StatelessWidget {
  const ScanBiblePagesTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des pages de scan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => ScanBiblePagesExample.openSimpleScanPage(context),
              child: const Text('Page de scan simple'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ScanBiblePagesExample.openAdvancedScanPage(context),
              child: const Text('Page de scan avancée'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanBiblePagesExample.buildPageWithScanBanner(context),
                ),
              ),
              child: const Text('Page avec banners de scan'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanBiblePagesExample.buildLightThemePage(context),
                ),
              ),
              child: const Text('Page avec design clair'),
            ),
          ],
        ),
      ),
    );
  }
}
