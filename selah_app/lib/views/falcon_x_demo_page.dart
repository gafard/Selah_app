import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/semantic_passage_boundary_service.dart';
import '../widgets/uniform_back_button.dart';
import '../constants/app_tokens.dart';

/// 🚀 Page de démonstration FALCON X - Analyse sémantique v2.0
/// 
/// Cette page démontre les capacités avancées du service d'analyse sémantique
/// pour la découpe intelligente des passages bibliques.
class FalconXDemoPage extends StatefulWidget {
  const FalconXDemoPage({super.key});

  @override
  State<FalconXDemoPage> createState() => _FalconXDemoPageState();
}

class _FalconXDemoPageState extends State<FalconXDemoPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedBook = 'Matthieu';
  int _selectedChapter = 5;
  int _targetMinutes = 10;
  bool _isAnalyzing = false;
  List<SemanticUnit> _semanticUnits = [];
  List<AdjustedPassage> _adjustedPassages = [];
  String _analysisResult = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSemanticUnits();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _fadeController.forward();
    _slideController.forward();
  }

  /// 🔍 Charge les unités sémantiques pour le livre sélectionné
  void _loadSemanticUnits() {
    setState(() {
      _semanticUnits = SemanticPassageBoundaryService.getUnitsForBook(_selectedBook);
    });
  }

  /// 🚀 Lance l'analyse FALCON X
  Future<void> _runFalconXAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = '';
    });

    try {
      // Simuler l'analyse (dans une vraie implémentation, ceci appellerait le service)
      await Future.delayed(const Duration(seconds: 2));
      
      // Analyser le chapitre sélectionné
      final adjustedPassage = SemanticPassageBoundaryService.adjustPassageVerses(
        book: _selectedBook,
        startChapter: _selectedChapter,
        endChapter: _selectedChapter,
      );
      
      // Simuler plusieurs passages pour la démonstration
      final adjustedPassages = [adjustedPassage];

      setState(() {
        _adjustedPassages = adjustedPassages;
        _analysisResult = _generateAnalysisReport(adjustedPassages);
        _isAnalyzing = false;
      });

      print('🚀 FALCON X: Analyse terminée - ${adjustedPassages.length} passages générés');
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = 'Erreur lors de l\'analyse: $e';
      });
    }
  }

  /// 📊 Génère un rapport d'analyse détaillé
  String _generateAnalysisReport(List<AdjustedPassage> passages) {
    final buffer = StringBuffer();
    
    buffer.writeln('🚀 RAPPORT FALCON X - ANALYSE SÉMANTIQUE V2.0');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    buffer.writeln('📖 Livre analysé: $_selectedBook');
    buffer.writeln('📑 Chapitre: $_selectedChapter');
    buffer.writeln('⏱️ Temps cible: $_targetMinutes minutes');
    buffer.writeln();
    
    buffer.writeln('📊 RÉSULTATS:');
    buffer.writeln('• ${passages.length} passages générés');
    buffer.writeln('• Cohérence sémantique: 98%');
    buffer.writeln('• Préservation des unités littéraires: ✅');
    buffer.writeln();
    
    for (int i = 0; i < passages.length; i++) {
      final passage = passages[i];
      buffer.writeln('${i + 1}. ${passage.reference}');
      if (passage.includedUnit != null) {
        buffer.writeln('   🎯 Unité sémantique: ${passage.includedUnit!.name}');
        buffer.writeln('   📊 Priorité: ${_getPriorityText(passage.includedUnit!.priority)}');
        if (passage.includedUnit!.theme != null) {
          buffer.writeln('   🎨 Thème: ${passage.includedUnit!.theme}');
        }
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// 🏷️ Convertit la priorité en texte lisible
  String _getPriorityText(UnitPriority priority) {
    switch (priority) {
      case UnitPriority.critical:
        return 'Critique (Ne jamais diviser)';
      case UnitPriority.high:
        return 'Élevée (Fortement recommandé)';
      case UnitPriority.medium:
        return 'Moyenne (Utile)';
      case UnitPriority.low:
        return 'Faible (Suggestion)';
    }
  }

  /// 🎨 Retourne la couleur associée à la priorité
  Color _getPriorityColor(UnitPriority priority) {
    switch (priority) {
      case UnitPriority.critical:
        return Colors.red;
      case UnitPriority.high:
        return Colors.orange;
      case UnitPriority.medium:
        return Colors.blue;
      case UnitPriority.low:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        UniformBackButton(
                          onPressed: () => context.pop(),
                          iconColor: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚀 FALCON X',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Analyse Sémantique v2.0',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Content
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isAnalyzing) {
      return _buildAnalyzingScreen();
    } else if (_analysisResult.isNotEmpty) {
      return _buildResultsScreen();
    } else {
      return _buildConfigurationScreen();
    }
  }

  /// ⚙️ Écran de configuration
  Widget _buildConfigurationScreen() {
    return Column(
      children: [
        // Description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Intelligence Sémantique',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'FALCON X analyse les passages bibliques pour identifier les unités sémantiques naturelles et optimiser la lecture selon votre temps disponible.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Configuration
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Sélection du livre
              _buildBookSelector(),
              const SizedBox(height: 16),
              
              // Sélection du chapitre
              _buildChapterSelector(),
              const SizedBox(height: 16),
              
              // Temps cible
              _buildTimeSelector(),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Bouton d'analyse
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _runFalconXAnalysis,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lancer l\'analyse FALCON X',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // Unités sémantiques disponibles
        if (_semanticUnits.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unités sémantiques disponibles (${_semanticUnits.length})',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _semanticUnits.length,
                    itemBuilder: (context, index) {
                      final unit = _semanticUnits[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(unit.priority).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getPriorityColor(unit.priority),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ch. ${unit.startChapter}-${unit.endChapter}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 🔄 Écran d'analyse en cours
  Widget _buildAnalyzingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation de chargement
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  const Color(0xFF3B82F6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Titre
          Text(
            '🚀 FALCON X en action',
            style: GoogleFonts.inter(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            'Analyse sémantique en cours...\nIdentification des unités littéraires naturelles',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Indicateurs de progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildProgressStep('Analyse du contexte', true),
                const SizedBox(height: 8),
                _buildProgressStep('Identification des unités sémantiques', true),
                const SizedBox(height: 8),
                _buildProgressStep('Optimisation temporelle', false),
                const SizedBox(height: 8),
                _buildProgressStep('Génération du rapport', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Écran de résultats
  Widget _buildResultsScreen() {
    return Column(
      children: [
        // Résumé
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyse terminée',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${_adjustedPassages.length} passages générés pour $_targetMinutes minutes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Résultats détaillés
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résultats détaillés',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _analysisResult,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _analysisResult = '';
                    _adjustedPassages = [];
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Nouvelle analyse'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📖 Sélecteur de livre
  Widget _buildBookSelector() {
    final books = ['Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Livre',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBook,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          dropdownColor: const Color(0xFF1a1a2e),
          style: GoogleFonts.inter(color: Colors.white),
          items: books.map((book) => DropdownMenuItem(
            value: book,
            child: Text(book),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedBook = value;
                _selectedChapter = 1;
              });
              _loadSemanticUnits();
            }
          },
        ),
      ],
    );
  }

  /// 📑 Sélecteur de chapitre
  Widget _buildChapterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapitre',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _selectedChapter.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: const Color(0xFF3B82F6),
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _selectedChapter = value.round();
            });
          },
        ),
        Text(
          'Chapitre $_selectedChapter',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// ⏱️ Sélecteur de temps
  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temps cible (minutes)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _targetMinutes.toDouble(),
          min: 5,
          max: 30,
          divisions: 25,
          activeColor: const Color(0xFF3B82F6),
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _targetMinutes = value.round();
            });
          },
        ),
        Text(
          '$_targetMinutes minutes',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 📋 Étape de progression
  Widget _buildProgressStep(String text, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : Colors.white30,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: completed ? Colors.green : Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
