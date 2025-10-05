import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/selah_logo.dart';

class JournalPage extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  
  const JournalPage({super.key, this.prefillData});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> with TickerProviderStateMixin {
  // --- Variables d'état ---
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _tagFilter = 'tous';
  bool _onlyScripture = false;
  String _sortBy = 'recent';
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  List<Map<String, dynamic>> _notes = [];
  bool _hasMore = true;

  // --- Pour l'édition ---
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _passageController = TextEditingController();
  Set<String> _selectedTags = {};
  String? _editingNoteId;

  Timer? _debounceTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // --- Couleurs modernes ---
  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _secondaryBlue = Color(0xFF60A5FA);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentPurple = Color(0xFF8B5CF6);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchNotes();
    
    // Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    // Si des données de pré-remplissage sont fournies, ouvrir l'éditeur
    if (widget.prefillData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNoteEditor(prefillData: widget.prefillData);
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _passageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0;
      });
      _fetchNotes();
    });
  }

  // --- Logique de chargement ---
  Future<void> _fetchNotes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Données de test modernisées
      _notes = [
        {
          'id': '1',
          'title': 'Réflexion du jour',
          'content': 'Aujourd\'hui, j\'ai lu le Psaume 23 et cela m\'a apporté beaucoup de paix. Le Seigneur est vraiment mon berger...',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'tags': ['réflexion', 'psaume'],
          'passage_ref': 'Psaume 23:1-6',
        },
        {
          'id': '2',
          'title': 'Prière du matin',
          'content': 'Seigneur, merci pour cette nouvelle journée. Guide-moi dans tes voies et aide-moi à être une bénédiction...',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'tags': ['prière', 'matin'],
        },
        {
          'id': '3',
          'title': 'Gratitude',
          'content': 'Je suis reconnaissant pour la famille que tu m\'as donnée et pour toutes tes bénédictions...',
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'tags': ['gratitude', 'famille'],
        },
      ];
      
      // Appliquer les filtres
      if (_onlyScripture) {
        _notes = _notes.where((note) => note['passage_ref'] != null).toList();
      }
      if (_tagFilter != 'tous') {
        _notes = _notes.where((note) => 
          (note['tags'] as List?)?.contains(_tagFilter) == true).toList();
      }
      
      // Appliquer la recherche
      if (_searchQuery.isNotEmpty) {
        _notes = _notes.where((note) => 
          note['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note['content'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
      }

      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _fetchNotes();
  }

  // --- Actions ---
  void _showNoteEditor({Map<String, dynamic>? note, Map<String, dynamic>? prefillData}) {
    if (note != null) {
      _editingNoteId = note['id'];
      _titleController.text = note['title'] ?? '';
      _contentController.text = note['content'];
      _passageController.text = note['passage_ref'] ?? '';
      _selectedTags = Set<String>.from(note['tags'] ?? []);
    } else if (prefillData != null) {
      _editingNoteId = null;
      _titleController.text = prefillData['title'] ?? '';
      _contentController.text = prefillData['content'] ?? '';
      _passageController.text = prefillData['passage_ref'] ?? '';
      _selectedTags = Set<String>.from(prefillData['tags'] ?? []);
    } else {
      _editingNoteId = null;
      _clearDrafts();
    }
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteEditorSheet(
        titleController: _titleController,
        contentController: _contentController,
        passageController: _passageController,
        selectedTags: _selectedTags,
        onSave: _saveNote,
      ),
    ).then((_) => _clearDrafts());
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newNote = {
        'id': _editingNoteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': content,
        'passage_ref': _passageController.text.trim().isNotEmpty ? _passageController.text : null,
        'tags': _selectedTags.toList(),
        'created_at': DateTime.now().toIso8601String(),
      };
      
      if (_editingNoteId == null) {
        _notes.insert(0, newNote);
      } else {
        final index = _notes.indexWhere((note) => note['id'] == _editingNoteId);
        if (index != -1) {
          _notes[index] = newNote;
        }
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingNoteId == null ? 'Note créée' : 'Note mise à jour')));
        _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _notes.removeWhere((note) => note['id'] == noteId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note supprimée')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _clearDrafts() {
    _titleController.clear();
    _contentController.clear();
    _passageController.clear();
    _selectedTags.clear();
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(child: _buildNoteList()),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _lightBackground,
      elevation: 0,
      title: Row(
        children: [
          const SelahAppIcon(size: 32, useBlueBackground: false),
          const SizedBox(width: 12),
          Text(
            'Journal Spirituel',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: _textSecondary),
          onPressed: _refresh,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vos réflexions',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_notes.length} notes enregistrées',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une note...',
              hintStyle: GoogleFonts.inter(color: _textSecondary),
              prefixIcon: Icon(Icons.search, color: _textSecondary),
              suffixIcon: PopupMenuButton<String>(
                icon: Icon(Icons.tune, color: _textSecondary),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                    _currentPage = 0;
                  });
                  _fetchNotes();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'recent', child: Text('Plus récent')),
                  const PopupMenuItem(value: 'oldest', child: Text('Plus ancien')),
                  const PopupMenuItem(value: 'title', child: Text('Titre (A-Z)')),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _lightBackground,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['tous', 'prière', 'promesse', 'gratitude'].map((tag) {
                      final isSelected = _tagFilter == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(tag, style: GoogleFonts.inter(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _tagFilter = selected ? tag : 'tous';
                              _currentPage = 0;
                            });
                            _fetchNotes();
                          },
                          selectedColor: _primaryBlue.withOpacity(0.2),
                          labelStyle: TextStyle(color: isSelected ? _primaryBlue : _textSecondary),
                          backgroundColor: _lightBackground,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Switch(
                value: _onlyScripture,
                onChanged: (value) {
                  setState(() {
                    _onlyScripture = value;
                    _currentPage = 0;
                  });
                  _fetchNotes();
                },
                activeColor: _primaryBlue,
              ),
              const SizedBox(width: 8),
              Text('Verset', style: GoogleFonts.inter(color: _textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteList() {
    if (_isLoading && _notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_add,
                size: 48,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune note pour l\'instant',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour en créer une',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && _hasMore) {
          _fetchNotes();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _notes.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notes.length && _hasMore) {
            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
          }
          final note = _notes[index];
          return _NoteCard(
            note: note,
            onTap: () => _showNoteEditor(note: note),
            onDelete: () => _deleteNote(note['id']),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showNoteEditor(),
      backgroundColor: _primaryBlue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Nouvelle note',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- Widgets Helper ---

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap, required this.onDelete});

  final Map<String, dynamic> note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(note['tags'] ?? []);
    final hasPassage = note['passage_ref'] != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note['title'] ?? 'Sans titre',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasPassage)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book, size: 14, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 4),
                            Text(
                              note['passage_ref'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note['content'],
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    height: 1.5,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  )
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(note['created_at'])),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteEditorSheet extends StatelessWidget {
  const _NoteEditorSheet({
    required this.titleController,
    required this.contentController,
    required this.passageController,
    required this.selectedTags,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController passageController;
  final Set<String> selectedTags;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Éditer la note',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Contenu',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passageController,
                decoration: InputDecoration(
                  labelText: 'Référence biblique (optionnel)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tags',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ['prière', 'promesse', 'gratitude', 'repentance'].map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: GoogleFonts.inter(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) => selected ? selectedTags.add(tag) : selectedTags.remove(tag),
                    selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Enregistrer',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}