import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/semantic_passage_boundary_service.dart';
import '../services/bsb_topical_service.dart';
import '../services/bsb_concordance_service.dart';
import '../services/bible_context_service.dart';
import '../services/bsb_book_outlines_service.dart';
import '../services/biblical_timeline_service.dart';

/// 🎯 Page d'étude thématique - Parcours aventure d'un thème biblique
class ThemeStudyPage extends StatefulWidget {
  final String? initialTheme;
  final String? passageRef; // Référence de la lecture du jour
  
  const ThemeStudyPage({
    super.key,
    this.initialTheme,
    this.passageRef,
  });

  @override
  State<ThemeStudyPage> createState() => _ThemeStudyPageState();
}

class _ThemeStudyPageState extends State<ThemeStudyPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Données de l'étude
  String? _selectedTheme;
  List<String> _availableThemes = [];
  bool _isLoadingThemes = true;
  
  // Données de progression
  List<Map<String, dynamic>> _themeReferences = [];
  List<Map<String, dynamic>> _concordanceResults = [];
  List<Map<String, dynamic>> _progressionData = [];
  List<Map<String, dynamic>> _bookOutlines = [];
  List<Map<String, dynamic>> _timelineEvents = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadThemesFromReading();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔥 Charge les thèmes depuis la lecture du jour via FalconX
  Future<void> _loadThemesFromReading() async {
    setState(() => _isLoadingThemes = true);
    
    try {
      // 1. Si un thème initial est fourni, l'utiliser
      if (widget.initialTheme != null && widget.initialTheme!.isNotEmpty) {
        _selectedTheme = widget.initialTheme;
        await _loadThemeData();
        setState(() => _isLoadingThemes = false);
        return;
      }
      
      // 2. Analyser la lecture du jour avec FalconX
      if (widget.passageRef != null) {
        final themes = await _extractThemesFromPassage(widget.passageRef!);
        if (themes.isNotEmpty) {
          _availableThemes = themes;
          _selectedTheme = themes.first;
          await _loadThemeData();
        }
      }
      
      // 3. Fallback vers thèmes populaires BSB
      if (_availableThemes.isEmpty) {
        await BSBTopicalService.init();
        _availableThemes = await BSBTopicalService.getPopularThemes();
        if (_availableThemes.isNotEmpty) {
          _selectedTheme = _availableThemes.first;
          await _loadThemeData();
        }
      }
      
    } catch (e) {
      print('❌ Erreur chargement thèmes: $e');
    } finally {
      setState(() => _isLoadingThemes = false);
    }
  }

  /// 🧠 Extrait les thèmes d'un passage via FalconX
  Future<List<String>> _extractThemesFromPassage(String passageRef) async {
    try {
      // Extraire livre et chapitre
      final parts = passageRef.split(' ');
      if (parts.length < 2) return [];
      
      final book = parts[0];
      final chapterPart = parts[1].split(':')[0];
      final chapter = int.tryParse(chapterPart);
      if (chapter == null) return [];
      
      // Utiliser FalconX pour analyser le passage
      final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
      if (unit == null) return [];
      
      List<String> themes = [];
      
      // 1. Thème principal de l'unité sémantique
      if (unit.theme != null && unit.theme!.isNotEmpty) {
        themes.add(unit.theme!);
      }
      
      // 2. Thèmes des tons émotionnels
      if (unit.emotionalTones != null) {
        themes.addAll(unit.emotionalTones!);
      }
      
      // 3. Thèmes du contexte liturgique
      if (unit.liturgicalContext != null && unit.liturgicalContext!.isNotEmpty) {
        themes.add(unit.liturgicalContext!);
      }
      
      // 4. Rechercher des thèmes BSB liés
      await BSBTopicalService.init();
      for (final theme in themes) {
        final bsbThemes = await BSBTopicalService.searchPartialTheme(theme);
        if (bsbThemes.isNotEmpty) {
          themes.addAll(bsbThemes.take(2));
        }
      }
      
      return themes.toSet().toList(); // Supprimer les doublons
      
    } catch (e) {
      print('❌ Erreur extraction thèmes FalconX: $e');
      return [];
    }
  }

  /// 📚 Charge les données complètes du thème sélectionné
  Future<void> _loadThemeData() async {
    if (_selectedTheme == null) return;
    
    try {
      // Charger les références du thème
      final references = await BSBTopicalService.searchThemeReferences(_selectedTheme!);
      _themeReferences = references;
      
      // Charger les résultats de concordance
      final concordanceResults = await BSBConcordanceService.searchPartial(_selectedTheme!);
      _concordanceResults = concordanceResults.map((word) => {
        'word': word,
        'count': 1, // Placeholder
      }).toList();
      
      // Générer la progression chronologique
      _progressionData = _generateProgressionData();
      
      // Charger les plans de livres BSB
      await _loadBookOutlines();
      
      // Charger les événements chronologiques
      await _loadTimelineEvents();
      
    } catch (e) {
      print('❌ Erreur chargement données thème: $e');
    }
  }

  /// 📈 Génère les données de progression chronologique
  List<Map<String, dynamic>> _generateProgressionData() {
    if (_themeReferences.isEmpty) return [];
    
    // Grouper par livre et ordre chronologique
    final Map<String, List<Map<String, dynamic>>> groupedByBook = {};
    
    for (final ref in _themeReferences) {
      final book = ref['book'] as String? ?? '';
      if (!groupedByBook.containsKey(book)) {
        groupedByBook[book] = [];
      }
      groupedByBook[book]!.add(ref);
    }
    
    // Ordre chronologique des livres bibliques
    const chronologicalOrder = [
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
      '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
      'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaumes',
      'Proverbes', 'Ecclésiaste', 'Cantique des Cantiques',
      'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel',
      'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas',
      'Michée', 'Nahum', 'Habacuc', 'Sophonie', 'Aggée',
      'Zacharie', 'Malachie', 'Matthieu', 'Marc', 'Luc',
      'Jean', 'Actes', 'Romains', '1 Corinthiens', '2 Corinthiens',
      'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
      '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée',
      '2 Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques',
      '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean',
      'Jude', 'Apocalypse'
    ];
    
    List<Map<String, dynamic>> progression = [];
    
    for (final book in chronologicalOrder) {
      if (groupedByBook.containsKey(book)) {
        final bookRefs = groupedByBook[book]!;
        progression.add({
          'book': book,
          'references': bookRefs,
          'count': bookRefs.length,
          'period': _getBiblicalPeriod(book),
        });
      }
    }
    
    return progression;
  }

  /// 📅 Détermine la période biblique d'un livre
  String _getBiblicalPeriod(String book) {
    const periods = {
      'Genèse': 'Patriarches',
      'Exode': 'Patriarches',
      'Lévitique': 'Patriarches',
      'Nombres': 'Patriarches',
      'Deutéronome': 'Patriarches',
      'Josué': 'Conquête',
      'Juges': 'Juges',
      'Ruth': 'Juges',
      '1 Samuel': 'Royaume uni',
      '2 Samuel': 'Royaume uni',
      '1 Rois': 'Royaume divisé',
      '2 Rois': 'Royaume divisé',
      '1 Chroniques': 'Royaume divisé',
      '2 Chroniques': 'Royaume divisé',
      'Esdras': 'Exil et retour',
      'Néhémie': 'Exil et retour',
      'Esther': 'Exil et retour',
      'Job': 'Sagesse',
      'Psaumes': 'Sagesse',
      'Proverbes': 'Sagesse',
      'Ecclésiaste': 'Sagesse',
      'Cantique des Cantiques': 'Sagesse',
      'Ésaïe': 'Prophètes majeurs',
      'Jérémie': 'Prophètes majeurs',
      'Lamentations': 'Prophètes majeurs',
      'Ézéchiel': 'Prophètes majeurs',
      'Daniel': 'Prophètes majeurs',
      'Osée': 'Prophètes mineurs',
      'Joël': 'Prophètes mineurs',
      'Amos': 'Prophètes mineurs',
      'Abdias': 'Prophètes mineurs',
      'Jonas': 'Prophètes mineurs',
      'Michée': 'Prophètes mineurs',
      'Nahum': 'Prophètes mineurs',
      'Habacuc': 'Prophètes mineurs',
      'Sophonie': 'Prophètes mineurs',
      'Aggée': 'Prophètes mineurs',
      'Zacharie': 'Prophètes mineurs',
      'Malachie': 'Prophètes mineurs',
      'Matthieu': 'Nouveau Testament',
      'Marc': 'Nouveau Testament',
      'Luc': 'Nouveau Testament',
      'Jean': 'Nouveau Testament',
      'Actes': 'Nouveau Testament',
      'Romains': 'Nouveau Testament',
      '1 Corinthiens': 'Nouveau Testament',
      '2 Corinthiens': 'Nouveau Testament',
      'Galates': 'Nouveau Testament',
      'Éphésiens': 'Nouveau Testament',
      'Philippiens': 'Nouveau Testament',
      'Colossiens': 'Nouveau Testament',
      '1 Thessaloniciens': 'Nouveau Testament',
      '2 Thessaloniciens': 'Nouveau Testament',
      '1 Timothée': 'Nouveau Testament',
      '2 Timothée': 'Nouveau Testament',
      'Tite': 'Nouveau Testament',
      'Philémon': 'Nouveau Testament',
      'Hébreux': 'Nouveau Testament',
      'Jacques': 'Nouveau Testament',
      '1 Pierre': 'Nouveau Testament',
      '2 Pierre': 'Nouveau Testament',
      '1 Jean': 'Nouveau Testament',
      '2 Jean': 'Nouveau Testament',
      '3 Jean': 'Nouveau Testament',
      'Jude': 'Nouveau Testament',
      'Apocalypse': 'Nouveau Testament',
    };
    
    return periods[book] ?? 'Inconnue';
  }

  /// 📚 Charge les plans de livres BSB pour le thème
  Future<void> _loadBookOutlines() async {
    if (_selectedTheme == null) return;
    
    try {
      await BSBBookOutlinesService.init();
      
      // Rechercher les livres qui contiennent ce thème
      final books = await BSBBookOutlinesService.searchBooksByTheme(_selectedTheme!);
      final outlines = <Map<String, dynamic>>[];
      
      for (final book in books) {
        final sections = await BSBBookOutlinesService.getSectionsForTheme(book, _selectedTheme!);
        if (sections.isNotEmpty) {
          outlines.add({
            'book': book,
            'sections': sections,
            'sectionCount': sections.length,
          });
        }
      }
      
      _bookOutlines = outlines;
    } catch (e) {
      print('❌ Erreur chargement plans de livres: $e');
    }
  }

  /// ⏰ Charge les événements chronologiques pour le thème
  Future<void> _loadTimelineEvents() async {
    if (_selectedTheme == null) return;
    
    try {
      await BiblicalTimelineService.init();
      
      // Obtenir la chronologie du thème
      final events = await BiblicalTimelineService.getThemeTimeline(_selectedTheme!);
      _timelineEvents = events;
    } catch (e) {
      print('❌ Erreur chargement chronologie: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1D29), Color(0xFF112244)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Stack(
                    children: [
                      // Ornements légers en arrière-plan
                      Positioned(
                        right: -60,
                        top: -40,
                        child: _softBlob(180),
                      ),
                      Positioned(
                        left: -40,
                        bottom: -50,
                        child: _softBlob(220),
                      ),

                      // Contenu principal
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  // Header
                                  _buildHeader(),
                                  const SizedBox(height: 20),
                                  // Sélecteur de thèmes
                                  _buildThemeSelector(),
                                  const SizedBox(height: 20),
                                  // Barre d'onglets
                                  _buildTabBar(),
                                  const SizedBox(height: 20),
                                  // Contenu des onglets
                                  SizedBox(
                                    height: 400,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildReferencesTab(),
                                        _buildConcordanceTab(),
                                        _buildProgressionTab(),
                                        _buildTimelineTab(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ÉTUDE THÉMATIQUE',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Parcours aventure d\'un thème biblique',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    if (_isLoadingThemes) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text(
              'Thèmes identifiés dans votre lecture:',
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableThemes.map((theme) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedTheme = theme;
              });
              _loadThemeData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedTheme == theme 
                    ? const Color(0xFF1553FF)
                    : Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedTheme == theme 
                      ? const Color(0xFF1553FF)
                      : Colors.white.withOpacity(0.20),
                ),
              ),
              child: Text(
                theme,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF1553FF),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Références'),
          Tab(text: 'Concordance'),
          Tab(text: 'Progression'),
          Tab(text: 'Chronologie'),
        ],
      ),
    );
  }

  Widget _buildReferencesTab() {
    return ListView.builder(
      itemCount: _themeReferences.length,
      itemBuilder: (context, index) {
        final ref = _themeReferences[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.book,
                color: Color(0xFF1553FF),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ref['reference'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConcordanceTab() {
    return ListView.builder(
      itemCount: _concordanceResults.length,
      itemBuilder: (context, index) {
        final result = _concordanceResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['word'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1553FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result['count'] ?? 0} occurrences',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressionTab() {
    return ListView.builder(
      itemCount: _progressionData.length,
      itemBuilder: (context, index) {
        final period = _progressionData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timeline,
                    color: Color(0xFF1553FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    period['book'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${period['count'] ?? 0} refs',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                period['period'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color: Color(0xFF1553FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    return ListView.builder(
      itemCount: _timelineEvents.length,
      itemBuilder: (context, index) {
        final event = _timelineEvents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event,
                    color: Color(0xFF1553FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['title'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${event['year'] ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event['description'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.book,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event['reference'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1553FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event['period'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 10,
                        color: Color(0xFF1553FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _softBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.20), Colors.transparent],
        ),
      ),
    );
  }
}
