import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Temporairement désactivé
import 'package:intl/intl.dart';

class JournalPage extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  
  const JournalPage({super.key, this.prefillData});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  // --- Variables d'état (Page State) ---
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchNotes();
    
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
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0; // Reset to first page on search
      });
      _fetchNotes();
    });
  }

  // --- Logique de chargement ---
  Future<void> _fetchNotes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Simulation de données pour les tests
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Données de test
      _notes = [
        {
          'id': '1',
          'title': 'Réflexion du jour',
          'content': 'Aujourd\'hui, j\'ai lu le Psaume 23 et cela m\'a apporté beaucoup de paix...',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'tags': ['réflexion', 'psaume'],
        },
        {
          'id': '2',
          'title': 'Prière du matin',
          'content': 'Seigneur, merci pour cette nouvelle journée. Guide-moi dans tes voies...',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'tags': ['prière', 'matin'],
        },
      ];
      
      // Appliquer les filtres sur les données de test
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
          _hasMore = false; // Pas de pagination pour les données de test
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
      // Édition d'une note existante
      _editingNoteId = note['id'];
      _titleController.text = note['title'] ?? '';
      _contentController.text = note['content'];
      _passageController.text = note['passage_ref'] ?? '';
      _selectedTags = Set<String>.from(note['tags'] ?? []);
    } else if (prefillData != null) {
      // Pré-remplissage avec des données externes
      _editingNoteId = null;
      _titleController.text = prefillData['title'] ?? '';
      _contentController.text = prefillData['content'] ?? '';
      _passageController.text = prefillData['passage_ref'] ?? '';
      _selectedTags = Set<String>.from(prefillData['tags'] ?? []);
    } else {
      // Nouvelle note vide
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
      // Simulation de sauvegarde pour les tests
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
      // Simulation de suppression pour les tests
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
    // On applique un thème clair pour cette page, comme suggéré
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F5F1),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF6F5F1), foregroundColor: Colors.black54, elevation: 0),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF5B6C9D)),
      ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildNoteList()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNoteEditor(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Journal', style: TextStyle(color: Colors.black87)),
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une note...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.tune),
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
            ),
          ),
          const SizedBox(height: 8),
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
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _tagFilter = selected ? tag : 'tous';
                              _currentPage = 0;
                            });
                            _fetchNotes();
                          },
                          selectedColor: const Color(0xFF5B6C9D).withOpacity(0.2),
                          labelStyle: TextStyle(color: isSelected ? const Color(0xFF5B6C9D) : Colors.black54),
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
              ),
              const SizedBox(width: 8),
              const Text('Verset'),
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
      return const Center(child: Text('Aucune note pour l\'instant.\nAppuyez sur + pour en créer une.', textAlign: TextAlign.center));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && _hasMore) {
          _fetchNotes();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80.0), // Space for FAB
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note['title'] ?? 'Sans titre',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note['passage_ref'] != null)
                    Chip(
                      label: Text('📖 ${note['passage_ref']}', style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue.shade100,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note['content'],
                style: GoogleFonts.lato(color: Colors.black54, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.grey.shade300,
                  )).toList(),
                )
              ],
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.parse(note['created_at'])),
                style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
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
          color: Color(0xFFF6F5F1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Éditer la note', style: GoogleFonts.playfairDisplay(fontSize: 24)),
              const SizedBox(height: 16),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
              const SizedBox(height: 16),
              TextField(controller: contentController, maxLines: 8, decoration: const InputDecoration(labelText: 'Contenu', alignLabelWithHint: true)),
              const SizedBox(height: 16),
              TextField(controller: passageController, decoration: const InputDecoration(labelText: 'Référence biblique (optionnel)')),
              const SizedBox(height: 16),
              Text('Tags', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              Wrap(
                children: ['prière', 'promesse', 'gratitude', 'repentance'].map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) => selected ? selectedTags.add(tag) : selectedTags.remove(tag),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: onSave, child: const Text('Enregistrer')),
              )
            ],
          ),
        ),
      ),
    );
  }
}