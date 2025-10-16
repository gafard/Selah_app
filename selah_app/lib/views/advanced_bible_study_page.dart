import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bible_context_service.dart';
import '../services/themes_service.dart';
import '../services/isbe_service.dart';
import '../services/openbible_themes_service.dart';

class AdvancedBibleStudyPage extends StatefulWidget {
  final String? verseId;
  
  const AdvancedBibleStudyPage({
    super.key,
    this.verseId,
  });

  @override
  State<AdvancedBibleStudyPage> createState() => _AdvancedBibleStudyPageState();
}

class _AdvancedBibleStudyPageState extends State<AdvancedBibleStudyPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _currentVerseId = 'Jean.3.16';
  IntelligentContextData? _contextData;
  List<String> _themes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentVerseId = widget.verseId ?? 'Jean.3.16';
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
      // Charger le contexte complet
      _contextData = await BibleContextService.getFullContext(_currentVerseId);
      
      // Charger les thèmes
      _themes = await ThemesService.themes(_currentVerseId);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
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
    if (_contextData == null) {
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
                  'Verset: $_currentVerseId',
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
          
          // Contexte historique
          if (_contextData!.historical != null)
            _buildContextCard(
              'Contexte Historique',
              Icons.history,
              _contextData!.historical!,
              Colors.blue,
            ),
          
          // Contexte culturel
          if (_contextData!.cultural != null)
            _buildContextCard(
              'Contexte Culturel',
              Icons.public,
              _contextData!.cultural!,
              Colors.green,
            ),
          
          // Auteur
          if (_contextData!.author != null)
            _buildContextCard(
              'Auteur',
              Icons.person,
              _contextData!.author!.shortBio,
              Colors.purple,
            ),
          
          // Contexte sémantique FALCON X
          if (_contextData!.hasSemanticContext)
            _buildSemanticContextCard(),
          
          // Contexte ISBE
          if (_contextData!.hasISBEContext)
            _buildISBEContextCard(),
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
                  '${_themes.length} thèmes identifiés',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Liste des thèmes
          if (_themes.isEmpty)
            _buildEmptyState('Aucun thème identifié')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _themes.map((theme) => _buildThemeChip(theme)).toList(),
            ),
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

  Widget _buildSemanticContextCard() {
    final semantic = _contextData!.semanticContext!;
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
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contexte Sémantique (FALCON X)',
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
            'Unité: ${semantic.unitName}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thème: ${semantic.theme}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (semantic.annotation != null) ...[
            const SizedBox(height: 8),
            Text(
              semantic.annotation!,
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

  Widget _buildISBEContextCard() {
    final isbe = _contextData!.isbeContext!;
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
              const Icon(Icons.menu_book, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Encyclopédie ISBE',
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
            isbe['title'] ?? 'Titre non disponible',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isbe['content'] ?? 'Contenu non disponible',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChip(String theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
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
      final parts = _currentVerseId.split('.');
      if (parts.isEmpty) return [];
      
      final book = parts[0];
      return await ISBEService.searchEntries(book);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadOpenBibleData() async {
    try {
      final parts = _currentVerseId.split('.');
      if (parts.isEmpty) return [];
      
      final book = parts[0];
      return await OpenBibleThemesService.searchThemes(book);
    } catch (e) {
      return [];
    }
  }
}
