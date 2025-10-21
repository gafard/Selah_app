import 'package:flutter/material.dart';
import '../services/bible_study_hydrator.dart';
import '../services/bsb_topical_service.dart';
import '../services/thomson_characters_service.dart';
// Services supprimés (packs incomplets)
import '../services/force_hydration_service.dart';

class DebugServicesPage extends StatefulWidget {
  const DebugServicesPage({super.key});

  @override
  State<DebugServicesPage> createState() => _DebugServicesPageState();
}

class _DebugServicesPageState extends State<DebugServicesPage> {
  String _status = 'Initialisation...';
  Map<String, int> _stats = {};
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _status = '🔍 DIAGNOSTIC DES SERVICES BIBLIQUES';
    });

    // 1. Vérifier l'état d'hydratation
    setState(() {
      _status = '📊 Vérification de l\'état d\'hydratation...';
    });

    final needsHydration = await BibleStudyHydrator.needsHydration();
    
    if (needsHydration) {
      setState(() {
        _status = '💧 Démarrage de l\'hydratation...';
      });
      
      await BibleStudyHydrator.hydrateAll(
        onProgress: (progress, file) {
          setState(() {
            _status = '💧 Hydratation: ${(progress * 100).toInt()}% - $file';
          });
        },
      );
    }

    // 2. Vérifier les statistiques
    setState(() {
      _status = '📈 Récupération des statistiques...';
    });
    
    _stats = await BibleStudyHydrator.getHydrationStats();

    // 3. Tester les services individuels
    setState(() {
      _status = '🧪 Test des services...';
    });

    // BSB Topical Service
    try {
      await BSBTopicalService.init();
      final themes = await BSBTopicalService.getThemesForPassage('Jean 3:16');
      _testResults.add('✅ BSB Topical: ${themes.length} thèmes pour Jean 3:16');
    } catch (e) {
      _testResults.add('❌ BSB Topical: $e');
    }

    // Thomson Characters Service
    try {
      await ThomsonCharactersService.init();
      final characters = await ThomsonCharactersService.getCharactersInPassage('Jean 3:16');
      _testResults.add('✅ Thomson Characters: ${characters.length} personnages pour Jean 3:16');
    } catch (e) {
      _testResults.add('❌ Thomson Characters: $e');
    }

    // Services supprimés (packs incomplets)
    _testResults.add('⚠️ LexiconService supprimé (packs incomplets)');
    _testResults.add('⚠️ CrossRefService supprimé (packs incomplets)');

    setState(() {
      _status = '✅ Diagnostic terminé';
    });
  }

  Future<void> _forceHydration() async {
    setState(() {
      _status = '🔄 Forçage de l\'hydratation...';
      _testResults.clear();
    });

    try {
      await ForceHydrationService.forceHydration();
      
      // Relancer le diagnostic après l'hydratation
      await _runDiagnostic();
      
    } catch (e) {
      setState(() {
        _status = '❌ Erreur lors du forçage: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Services'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Stats
            if (_stats.isNotEmpty) ...[
              const Text(
                '📊 Statistiques des services:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _stats.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value} entrées',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: entry.value > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Force Hydration Button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '🔄 Forcer l\'hydratation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Réinitialise et recharge tous les services bibliques',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _forceHydration,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Forcer l\'hydratation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Results
            if (_testResults.isNotEmpty) ...[
              const Text(
                '🧪 Résultats des tests:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          result,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
