import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bible_context_service.dart';
import '../services/thomson_service.dart';
import '../services/bsb_topical_service.dart';
import '../services/biblical_timeline_service.dart';
import '../services/semantic_passage_boundary_service_v2.dart';
import '../services/bsb_book_outlines_service.dart';
// Services supprimés (packs incomplets)

class AdvancedBibleStudyPage extends StatefulWidget {
  final String? verseId;
  final String? passageRef;
  final int initialTab;
  
  const AdvancedBibleStudyPage({
    super.key,
    this.verseId,
    this.passageRef,
    this.initialTab = 0,
  });

  @override
  State<AdvancedBibleStudyPage> createState() => _AdvancedBibleStudyPageState();
}

class _AdvancedBibleStudyPageState extends State<AdvancedBibleStudyPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _currentVerseId = 'Jean.3.16';
  String _currentPassageRef = 'Jean 3:16';
  Map<String, dynamic> _contextData = {};
  List<String> _themes = [];
  List<String> _bsbThemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _currentVerseId = widget.verseId ?? 'Jean.3.16';
    _currentPassageRef = widget.passageRef ?? 'Jean 3:16';
    
    print('🔍 AdvancedBibleStudyPage initState:');
    print('   - verseId: $_currentVerseId');
    print('   - passageRef: $_currentPassageRef');
    
    _loadStudyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudyData() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 === DÉBUT CHARGEMENT DONNÉES ÉTUDE POUR: $_currentPassageRef ===');
      
      // Initialiser tous les services
      await Future.wait([
        BibleContextService.init(),
        ThomsonService.init(),
        BSBTopicalService.init(),
        BiblicalTimelineService.init(),
        SemanticPassageBoundaryService.init(),
        BSBBookOutlinesService.init(),
      ]);
      
      // 1. Charger le contexte historique via ThomsonService
      final thomsonContext = await ThomsonService.getContext(_currentVerseId);
      if (thomsonContext.isNotEmpty) {
        _contextData['historical'] = thomsonContext;
      }
      
      // 2. Charger le contexte culturel via BibleContextService
      final culturalContext = await BibleContextService.cultural(_currentVerseId);
      if (culturalContext != null && culturalContext.isNotEmpty) {
        _contextData['cultural'] = culturalContext;
      }
      
      // 3. Charger la période historique via BiblicalTimelineService
      final bookName = _extractBookFromReference(_currentPassageRef);
      if (bookName.isNotEmpty) {
        final period = await BiblicalTimelineService.getPeriodForBook(bookName);
        if (period != null) {
          _contextData['period'] = period;
        }
      }
      
      // 4. Charger le contexte littéraire via SemanticPassageBoundaryService
      if (bookName.isNotEmpty) {
        final units = SemanticPassageBoundaryService.getUnitsForBook(bookName);
        if (units.isNotEmpty) {
          _contextData['literary'] = {
            'name': units.first.name,
            'description': units.first.description ?? '',
          };
        }
      }
      
      // 5. Charger les thèmes Thomson
      _themes = await ThomsonService.getThemes(_currentVerseId);
      
      // 6. Charger les thèmes BSB
      _bsbThemes = await BSBTopicalService.getThemesForPassage(_currentPassageRef);
      
      // 7. Charger le plan du livre via BSBBookOutlinesService
      if (bookName.isNotEmpty) {
        final bookOutline = await BSBBookOutlinesService.getBookOutline(bookName);
        if (bookOutline != null) {
          _contextData['bookOutline'] = bookOutline;
        }
      }
      
      print('🔍 Contexte chargé: ${_contextData.keys.join(', ')}');
      print('🔍 Thèmes Thomson: ${_themes.length}');
      print('🔍 Thèmes BSB: ${_bsbThemes.length}');
      print('🔍 === FIN CHARGEMENT DONNÉES ÉTUDE ===');
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('⚠️ Erreur chargement données étude: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }
  
  /// Extrait le nom du livre d'une référence biblique
  String _extractBookFromReference(String reference) {
    final parts = reference.split(' ');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return '';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Étude Biblique Avancée',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Contexte', icon: Icon(Icons.info_outline)),
            Tab(text: 'Thèmes', icon: Icon(Icons.label_outline)),
            Tab(text: 'ISBE', icon: Icon(Icons.menu_book_outlined)),
            Tab(text: 'OpenBible', icon: Icon(Icons.auto_awesome_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContextTab(),
                _buildThemesTab(),
                _buildISBETab(),
                _buildOpenBibleTab(),
              ],
            ),
    );
  }

  Widget _buildContextTab() {
    if (_contextData.isEmpty) {
      return _buildEmptyState('Aucun contexte disponible');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du verset
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passage: $_currentPassageRef',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contexte biblique enrichi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contexte historique Thomson
          if (_contextData['historical'] != null)
            _buildContextCard(
              'Contexte Historique (Thomson)',
              Icons.history,
              _contextData['historical'],
              Colors.blue,
            ),
          
          // Contexte culturel
          if (_contextData['cultural'] != null)
            _buildContextCard(
              'Contexte Culturel',
              Icons.public,
              _contextData['cultural'],
              Colors.green,
            ),
          
          // Période historique
          if (_contextData['period'] != null)
            _buildPeriodCard(_contextData['period']),
          
          // Contexte littéraire
          if (_contextData['literary'] != null)
            _buildLiteraryContextCard(_contextData['literary']),
          
          // Plan du livre
          if (_contextData['bookOutline'] != null)
            _buildBookOutlineCard(_contextData['bookOutline']),
        ],
      ),
    );
  }

  Widget _buildThemesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thèmes Spirituels',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_themes.length + _bsbThemes.length} thèmes identifiés',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Thèmes Thomson
          if (_themes.isNotEmpty) ...[
            _buildThemeSectionHeader('🎨 Thèmes Thomson', _themes.length),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _themes.map((theme) => _buildThemeChip(theme, Colors.purple)).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Thèmes BSB
          if (_bsbThemes.isNotEmpty) ...[
            _buildThemeSectionHeader('📚 Thèmes BSB', _bsbThemes.length),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bsbThemes.map((theme) => _buildThemeChip(theme, Colors.blue)).toList(),
            ),
          ],
          
          // Message si aucun thème
          if (_themes.isEmpty && _bsbThemes.isEmpty)
            _buildEmptyState('Aucun thème identifié'),
        ],
      ),
    );
  }

  Widget _buildISBETab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadISBEData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasError) {
          return _buildEmptyState('Erreur ISBE: ${snapshot.error}');
        }
        
        final entries = snapshot.data ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encyclopédie Biblique ISBE',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${entries.length} entrées trouvées',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Entrées ISBE
              if (entries.isEmpty)
                _buildEmptyState('Aucune entrée ISBE trouvée')
              else
                ...entries.map((entry) => _buildISBEEntry(entry)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpenBibleTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadOpenBibleData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasError) {
          return _buildEmptyState('Erreur OpenBible: ${snapshot.error}');
        }
        
        final themes = snapshot.data ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thèmes OpenBible',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${themes.length} thèmes trouvés',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Thèmes OpenBible
              if (themes.isEmpty)
                _buildEmptyState('Aucun thème OpenBible trouvé')
              else
                ...themes.map((theme) => _buildOpenBibleTheme(theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextCard(String title, IconData icon, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildThemeChip(String theme, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        theme,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildThemeSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPeriodCard(Map<String, dynamic> period) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Période Historique',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            period['name'] ?? 'Période inconnue',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (period['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              period['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLiteraryContextCard(Map<String, dynamic> literary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contexte Littéraire',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            literary['name'] ?? 'Contexte inconnu',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (literary['description'] != null && literary['description'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              literary['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildISBEEntry(Map<String, dynamic> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry['title'] ?? 'Titre non disponible',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry['content'] ?? 'Contenu non disponible',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenBibleTheme(Map<String, dynamic> theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            theme['name'] ?? 'Thème non disponible',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (theme['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              theme['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookOutlineCard(Map<String, dynamic> bookOutline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book_outlined, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Plan du Livre',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bookOutline['title'] ?? 'Plan non disponible',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (bookOutline['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              bookOutline['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
          if (bookOutline['period'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Période: ${bookOutline['period']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo[200],
                ),
              ),
            ),
          ],
          if (bookOutline['sections'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Sections principales:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            ...((bookOutline['sections'] as List<dynamic>? ?? [])
                .take(3) // Limiter à 3 sections pour l'affichage
                .map((section) {
              final sectionData = section as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionData['title'] ?? 'Section',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (sectionData['chapters'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chapitres: ${sectionData['chapters']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.indigo[200],
                        ),
                      ),
                    ],
                    if (sectionData['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sectionData['description'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadISBEData() async {
    try {
      // Service supprimé (packs incomplets)
      return <Map<String, dynamic>>[];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadOpenBibleData() async {
    try {
      // Service supprimé (packs incomplets)
      return <Map<String, dynamic>>[];
    } catch (e) {
      return [];
    }
  }
}
