// Exemple d'intégration du ScanBibleBanner dans les pages de méditation
// Ce fichier montre comment utiliser le widget dans différents contextes

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/scan_bible_banner.dart';
import '../widgets/modern_scan_bible_banner.dart';

class ScanBibleIntegrationExample {
  
  /// Exemple d'utilisation dans une page de méditation libre
  static Widget buildMeditationFreeWithScan() {
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
                      'Méditation Libre',
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
                    // Banner de scan
                    const ModernScanBibleBanner(
                      onTap: _handleScanTap,
                    ),
                    const SizedBox(height: 20),
                    
                    // Autres éléments de méditation...
                    _buildMeditationField('Ce texte m\'enseigne à propos de Dieu'),
                    const SizedBox(height: 20),
                    _buildMeditationField('… et à propos de mon prochain'),
                    const SizedBox(height: 20),
                    _buildMeditationField('Application concrète aujourd\'hui'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Exemple d'utilisation dans une page de méditation QCM
  static Widget buildMeditationQcmWithScan() {
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
                      'Méditation Guidée',
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
                    // Banner de scan
                    const SubtleScanBibleBanner(
                      onTap: _handleScanTap,
                    ),
                    const SizedBox(height: 20),
                    
                    // Questions QCM...
                    _buildQuestionCard('Que t\'apprend ce passage sur Dieu ?'),
                    const SizedBox(height: 20),
                    _buildQuestionCard('Y a-t-il un ordre à obéir ?'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Exemple d'utilisation dans une page de lecture
  static Widget buildReaderWithScan() {
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
                      'Lecteur Biblique',
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
                    // Banner de scan
                    const ModernScanBibleBanner(
                      onTap: _handleScanTap,
                    ),
                    const SizedBox(height: 20),
                    
                    // Texte biblique...
                    _buildBibleText(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Exemple d'utilisation avec design clair (pour les pages non-sombres)
  static Widget buildLightThemeExample() {
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
                    'Exemple Design Clair',
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
                  const ScanBibleBanner(
                    onTap: _handleScanTap,
                  ),
                  const SizedBox(height: 20),
                  
                  // Autres éléments...
                  _buildLightCard('Élément 1'),
                  const SizedBox(height: 16),
                  _buildLightCard('Élément 2'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Méthodes utilitaires pour construire les widgets
  
  static Widget _buildMeditationField(String title) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Zone de texte...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildQuestionCard(String question) {
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
        question,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
  
  static Widget _buildBibleText() {
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
        'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.4,
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
    // Par exemple, ouvrir l'appareil photo ou la galerie
  }
}

/// Widget de test pour tous les exemples
class ScanBibleIntegrationTestPage extends StatelessWidget {
  const ScanBibleIntegrationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test d\'intégration ScanBible'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanBibleIntegrationExample.buildMeditationFreeWithScan(),
                ),
              ),
              child: const Text('Test Méditation Libre'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanBibleIntegrationExample.buildMeditationQcmWithScan(),
                ),
              ),
              child: const Text('Test Méditation QCM'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanBibleIntegrationExample.buildReaderWithScan(),
                ),
              ),
              child: const Text('Test Lecteur Biblique'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanBibleIntegrationExample.buildLightThemeExample(),
                ),
              ),
              child: const Text('Test Design Clair'),
            ),
          ],
        ),
      ),
    );
  }
}
