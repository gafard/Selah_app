import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/uniform_back_button.dart';

class JournalPage extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  
  const JournalPage({super.key, this.prefillData});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> with TickerProviderStateMixin {
  // Variables d'état
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _tagFilter = 'tous';
  final bool _onlyScripture = false;
  final String _sortBy = 'recent';
  final int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  List<Map<String, dynamic>> _notes = [];
  final bool _hasMore = true;

  // Pour l'édition
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _passageController = TextEditingController();
  Set<String> _selectedTags = {};
  String? _editingNoteId;

  Timer? _debounceTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _loadNotes();
    _fadeController.forward();
    
    // Pré-remplir avec les données si disponibles
    if (widget.prefillData != null) {
      _titleController.text = widget.prefillData!['title'] ?? '';
      _contentController.text = widget.prefillData!['content'] ?? '';
      _passageController.text = widget.prefillData!['passage'] ?? '';
      if (widget.prefillData!['tags'] != null) {
        _selectedTags = Set<String>.from(widget.prefillData!['tags']);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _passageController.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    try {
      // Simuler le chargement des notes
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Données de démonstration
      final demoNotes = [
        {
          'id': '1',
          'title': 'Réflexion sur Jean 3:16',
          'content': 'Dieu a tant aimé le monde qu\'il a donné son Fils unique...',
          'passage': 'Jean 3:16',
          'tags': ['amour', 'salut', 'foi'],
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'isScripture': true,
        },
        {
          'id': '2',
          'title': 'Méditation du matin',
          'content': 'Ce matin, je me sens reconnaissant pour...',
          'passage': null,
          'tags': ['gratitude', 'méditation'],
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'isScripture': false,
        },
        {
          'id': '3',
          'title': 'Psaume 23 - Mon berger',
          'content': 'L\'Éternel est mon berger, je ne manquerai de rien...',
          'passage': 'Psaume 23:1',
          'tags': ['protection', 'foi', 'paix'],
          'createdAt': DateTime.now().subtract(const Duration(days: 7)),
          'isScripture': true,
        },
      ];
      
      setState(() {
        _notes = demoNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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
            colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          bottom: false, // Permettre au contenu d'aller jusqu'en bas
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _notes.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              UniformBackButton(
                onPressed: () => Navigator.pop(context),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Journal Spirituel',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _showSearchDialog,
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'tous', 'label': 'Tous'},
      {'key': 'scripture', 'label': 'Écritures'},
      {'key': 'personal', 'label': 'Personnel'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _tagFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter['label']!,
                style: GoogleFonts.inter(
                  color: isSelected ? const Color(0xFF1C1740) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _tagFilter = filter['key']!;
                });
                _loadNotes();
              },
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: Colors.white,
              checkmarkColor: const Color(0xFF1C1740),
              side: BorderSide(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 60,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Votre journal est vide',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez à écrire vos réflexions spirituelles et vos méditations.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showAddNoteDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1740),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Écrire ma première note',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques
            _buildStatsCard(),
            const SizedBox(height: 24),
            
            // Notes
            Text(
              'Mes Notes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._notes.map((note) => _buildNoteCard(note)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalNotes = _notes.length;
    final scriptureNotes = _notes.where((n) => n['isScripture'] == true).length;
    final thisWeek = _notes.where((n) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      return n['createdAt'].isAfter(weekAgo);
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Statistiques du Journal',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', totalNotes.toString(), Icons.book),
              ),
              Expanded(
                child: _buildStatItem('Écritures', scriptureNotes.toString(), Icons.menu_book),
              ),
              Expanded(
                child: _buildStatItem('Cette semaine', thisWeek.toString(), Icons.calendar_today),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: note['isScripture'] 
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  note['isScripture'] ? Icons.menu_book : Icons.edit_note,
                  color: note['isScripture'] ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDate(note['createdAt']),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editNote(note);
                  } else if (value == 'delete') {
                    _deleteNote(note['id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Color(0xFF3B82F6)),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note['passage'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note['passage'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            note['content'],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (note['tags'] != null && note['tags'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: note['tags'].take(3).map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddNoteDialog,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1C1740),
      icon: const Icon(Icons.add),
      label: Text(
        'Nouvelle note',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: Text(
          'Rechercher',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(color: Colors.white),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          enableInteractiveSelection: true,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Rechercher dans vos notes...',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
              _loadNotes();
            },
            child: Text(
              'Rechercher',
              style: GoogleFonts.inter(color: const Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    _titleController.clear();
    _contentController.clear();
    _passageController.clear();
    _selectedTags.clear();
    _editingNoteId = null;

    showDialog(
      context: context,
      builder: (context) => _buildNoteDialog(),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    _titleController.text = note['title'];
    _contentController.text = note['content'];
    _passageController.text = note['passage'] ?? '';
    _selectedTags = Set<String>.from(note['tags'] ?? []);
    _editingNoteId = note['id'];

    showDialog(
      context: context,
      builder: (context) => _buildNoteDialog(),
    );
  }

  Widget _buildNoteDialog() {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      title: Text(
        _editingNoteId == null ? 'Nouvelle note' : 'Modifier la note',
        style: GoogleFonts.inter(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              enableInteractiveSelection: true,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Titre',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passageController,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              enableInteractiveSelection: true,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Passage biblique (optionnel)',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableInteractiveSelection: true,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Contenu',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
          ),
        ),
        TextButton(
          onPressed: _saveNote,
          child: Text(
            'Sauvegarder',
            style: GoogleFonts.inter(color: const Color(0xFF3B82F6)),
          ),
        ),
      ],
    );
  }

  void _saveNote() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir le titre et le contenu'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final note = {
      'id': _editingNoteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _titleController.text,
      'content': _contentController.text,
      'passage': _passageController.text.isEmpty ? null : _passageController.text,
      'tags': _selectedTags.toList(),
      'createdAt': DateTime.now(),
      'isScripture': _passageController.text.isNotEmpty,
    };

    setState(() {
      if (_editingNoteId != null) {
        final index = _notes.indexWhere((n) => n['id'] == _editingNoteId);
        if (index != -1) {
          _notes[index] = note;
        }
      } else {
        _notes.insert(0, note);
      }
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingNoteId == null ? 'Note créée' : 'Note modifiée'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _deleteNote(String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: Text(
          'Supprimer la note',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette note ?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notes.removeWhere((n) => n['id'] == noteId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note supprimée'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}