import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bible_pack_tester.dart';

class BiblePackTestPage extends StatefulWidget {
  const BiblePackTestPage({super.key});

  @override
  State<BiblePackTestPage> createState() => _BiblePackTestPageState();
}

class _BiblePackTestPageState extends State<BiblePackTestPage> {
  Map<String, dynamic>? _testResults;
  bool _isRunning = false;
  String _testReport = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Test des Packs Bibliques',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Bouton de test
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runTests,
              icon: _isRunning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                _isRunning ? 'Tests en cours...' : 'Lancer les Tests',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Résultats
          Expanded(
            child: _testResults == null
                ? _buildEmptyState()
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun test exécuté',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur "Lancer les Tests" pour valider\nl\'intégration des packs bibliques',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final summary = _testResults!['summary'] as Map<String, dynamic>;
    final status = summary['status'] as String;
    final successRate = (summary['success_rate'] as double) * 100;
    final extractedPacks = summary['extracted_packs'] as int;
    final totalPacks = summary['total_packs'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: status == 'SUCCESS' 
                  ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
                  : [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status == 'SUCCESS' ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      status == 'SUCCESS' ? Icons.check_circle : Icons.warning,
                      color: status == 'SUCCESS' ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Résumé des Tests',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatRow('Statut', status, status == 'SUCCESS' ? Colors.green : Colors.orange),
                _buildStatRow('Taux de réussite', '${successRate.toStringAsFixed(1)}%', Colors.blue),
                _buildStatRow('Packs extraits', '$extractedPacks / $totalPacks', Colors.purple),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Détails par pack
          Text(
            'Détails par Pack',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._buildPackDetails(),
          
          const SizedBox(height: 24),
          
          // Services spécialisés
          Text(
            'Services Spécialisés',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._buildServiceDetails(),
          
          const SizedBox(height: 24),
          
          // Rapport complet
          ElevatedButton.icon(
            onPressed: _showFullReport,
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text(
              'Voir le Rapport Complet',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPackDetails() {
    final packs = _testResults!['packs'] as Map<String, dynamic>;
    final widgets = <Widget>[];
    
    for (final entry in packs.entries) {
      final packId = entry.key;
      final packData = entry.value as Map<String, dynamic>;
      
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: packData['extracted'] == true && packData['database_accessible'] == true
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: packData['extracted'] == true && packData['database_accessible'] == true
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                packId.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildPackStatus('Extrait', packData['extracted']),
              _buildPackStatus('Base accessible', packData['database_accessible']),
              _buildPackStatus('Manifest disponible', packData['manifest_available']),
              
              if (packData['sample_data'] != null)
                _buildPackStatus('Données d\'exemple', true, 
                  '${(packData['sample_data'] as Map)['count']} entrées'),
              
              if (packData['error'] != null)
                Text(
                  'Erreur: ${packData['error']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildPackStatus(String label, bool status, [String? detail]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: status ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 8),
            Text(
              '($detail)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildServiceDetails() {
    final services = _testResults!['services'] as Map<String, dynamic>?;
    if (services == null) return [];
    
    final widgets = <Widget>[];
    
    for (final entry in services.entries) {
      final serviceName = entry.key;
      final serviceData = entry.value as Map<String, dynamic>;
      
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: serviceData['available'] == true
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: serviceData['available'] == true
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceName.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildPackStatus('Disponible', serviceData['available']),
              
              if (serviceData['categories'] != null)
                _buildPackStatus('Catégories', true, 
                  '${(serviceData['categories'] as List).length} catégories'),
              
              if (serviceData['error'] != null)
                Text(
                  'Erreur: ${serviceData['error']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults = null;
    });

    try {
      final results = await BiblePackTester.testAllPacks();
      final report = BiblePackTester.generateTestReport(results);
      
      setState(() {
        _testResults = results;
        _testReport = report;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors des tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFullReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapport Complet'),
        content: SingleChildScrollView(
          child: Text(
            _testReport,
            style: GoogleFonts.robotoMono(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
