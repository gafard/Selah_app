import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/bible_highlight.dart';
import '../services/bible_highlight_service.dart';

class HighlightableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String? reference; // Référence biblique (ex: "Jean 3:16")
  final String? version; // Version de la Bible
  final String? book; // Livre biblique
  final int? startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;

  const HighlightableText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.reference,
    this.version,
    this.book,
    this.startChapter,
    this.startVerse,
    this.endChapter,
    this.endVerse,
  });

  @override
  State<HighlightableText> createState() => _HighlightableTextState();
}

class _HighlightableTextState extends State<HighlightableText>
    with TickerProviderStateMixin {
  String _selectedText = '';
  bool _isTextSelected = false;
  TextSelection? _currentSelection;
  final List<TextRange> _highlightedRanges = []; // Store highlighted ranges
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Gestion des surlignages
  List<BibleHighlight> _currentHighlights = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Charger les surlignages existants
    _loadHighlights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Charger les surlignages existants pour ce passage
  Future<void> _loadHighlights() async {
    if (widget.reference == null) return;
    
    try {
      final highlights = await BibleHighlightService.getHighlightsForReference(widget.reference!);
      setState(() {
        _currentHighlights = highlights;
      });
    } catch (e) {
      print('⚠️ Erreur chargement surlignages: $e');
    }
  }

  void _showHighlightMenu() {
    if (_selectedText.isEmpty) return;
    HapticFeedback.lightImpact();
    _animationController.forward();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // Background with blur effect
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            _animationController.reverse().then((_) {
                              context.pop();
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      // Modern floating menu
                      Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 80,
                                offset: const Offset(0, 40),
                                spreadRadius: -20,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header with selected text preview
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF8F9FA),
                                      Color(0xFFF1F3F4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(28),
                                    topRight: Radius.circular(28),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF007AFF),
                                                Color(0xFF5AC8FA),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Texte sélectionné',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF1D1D1F),
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Modern action grid
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _buildModernAction(
                                      Icons.highlight_alt_rounded,
                                      'Surligner',
                                      const Color(0xFFFFD700),
                                      const Color(0xFFFFF8E1),
                                      () {
                                        _animationController.reverse().then((_) {
                                          context.pop();
                                          _showColorPalette();
                                        });
                                      },
                                    ),
                                    _buildModernAction(
                                      Icons.edit_note_rounded,
                                      'Note',
                                      const Color(0xFF007AFF),
                                      const Color(0xFFE3F2FD),
                                      () {
                                        _animationController.reverse().then((_) {
                                          context.pop();
                                          _showModernNoteDialog();
                                        });
                                      },
                                    ),
                                    _buildModernAction(
                                      Icons.copy_all_rounded,
                                      'Copier',
                                      const Color(0xFF34C759),
                                      const Color(0xFFE8F5E8),
                                      () {
                                        _animationController.reverse().then((_) {
                                          context.pop();
                                          _copyText();
                                        });
                                      },
                                    ),
                                    _buildModernAction(
                                      Icons.search_rounded,
                                      'Rechercher',
                                      const Color(0xFFFF9500),
                                      const Color(0xFFFFF3E0),
                                      () {
                                        _animationController.reverse().then((_) {
                                          context.pop();
                                          _searchText();
                                        });
                                      },
                                    ),
                                    _buildModernAction(
                                      Icons.translate_rounded,
                                      'Traduire',
                                      const Color(0xFFAF52DE),
                                      const Color(0xFFF3E5F5),
                                      () {
                                        _animationController.reverse().then((_) {
                                          context.pop();
                                          _translateText();
                                        });
                                      },
                                    ),
                                    _buildModernAction(
                                      Icons.menu_book_rounded,
                                      'Dictionnaire',
                                      const Color(0xFFFF3B30),
                                      const Color(0xFFFFEBEE),
                                      () {
                                        _animationController.reverse().then((_) {
                                          context.pop();
                                          _showDictionary();
                                        });
                                      },
                                    ),
                                  ],
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
          },
        );
      },
    );
  }

  Widget _buildModernAction(
    IconData icon,
    String label,
    Color iconColor,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showModernNoteDialog() {
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF007AFF),
                          Color(0xFF5AC8FA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Ajouter une note',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Selected text preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E5E7),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '"$_selectedText"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Note input
                        TextField(
                          controller: noteController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre note ici...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF007AFF),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.pop();
                                  _showFeedback('Note enregistrée !', Colors.green);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007AFF),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Enregistrer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Afficher la palette de couleurs pour le surlignage
  void _showColorPalette() {
    if (_currentSelection == null || _currentSelection!.isCollapsed) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFF8E1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Choisir une couleur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"$_selectedText"',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Palette de couleurs
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: HighlightColor.availableColors.asMap().entries.map((entry) {
                        final index = entry.key;
                        final color = entry.value;
                        final colorName = HighlightColor.colorNames[index];
                        
                        return _buildColorButton(color, colorName, () {
                          context.pop();
                          _highlightTextWithColor(color);
                        });
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bouton de couleur
  Widget _buildColorButton(Color color, String name, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Surligner le texte avec une couleur spécifique
  Future<void> _highlightTextWithColor(Color color) async {
    if (_currentSelection == null || _currentSelection!.isCollapsed) return;
    
    try {
      // Créer le surlignage
      final highlight = BibleHighlight.fromSelection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reference: widget.reference ?? '',
        book: widget.book ?? '',
        startChapter: widget.startChapter ?? 1,
        startVerse: widget.startVerse ?? 1,
        endChapter: widget.endChapter ?? widget.startChapter ?? 1,
        endVerse: widget.endVerse ?? widget.startVerse ?? 1,
        selectedText: _selectedText,
        highlightColor: color,
        version: widget.version ?? 'lsg1910',
      );
      
      // Sauvegarder
      await BibleHighlightService.saveHighlight(highlight);
      
      // Mettre à jour l'affichage
      setState(() {
        _highlightedRanges.add(TextRange(start: _currentSelection!.start, end: _currentSelection!.end));
        _isTextSelected = false;
        _selectedText = '';
        _currentHighlights.add(highlight);
      });
      
      _showFeedback('Texte surligné en ${HighlightColor.getColorName(color)} !', color);
    } catch (e) {
      print('❌ Erreur sauvegarde surlignage: $e');
      _showFeedback('Erreur lors du surlignage', Colors.red);
    }
  }


  void _copyText() {
    Clipboard.setData(ClipboardData(text: _selectedText));
    _showFeedback('Texte copié !', Colors.green);
  }

  void _searchText() {
    _showFeedback('Recherche : "$_selectedText"', Colors.purple);
  }

  void _translateText() {
    _showFeedback('Traduction : "$_selectedText"', Colors.orange);
  }

  void _showDictionary() {
    _showFeedback('Dictionnaire : "$_selectedText"', Colors.teal);
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (_isTextSelected && _selectedText.isNotEmpty) {
          _showHighlightMenu();
        }
      },
      child: _buildHighlightedText(),
    );
  }

  /// Construire le texte avec les surlignages
  Widget _buildHighlightedText() {
    if (_currentHighlights.isEmpty) {
      // Pas de surlignages, affichage normal
      return SelectableText(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        onSelectionChanged: (selection, cause) {
          setState(() {
            if (selection.isCollapsed) {
              _isTextSelected = false;
              _selectedText = '';
            } else {
              _isTextSelected = true;
              _selectedText = selection.textInside(widget.text);
              _currentSelection = selection;
            }
          });
        },
      );
    }

    // Construire le texte avec les surlignages
    final textSpans = <TextSpan>[];
    int currentIndex = 0;

    for (final highlight in _currentHighlights) {
      // Ajouter le texte avant le surlignage
      if (currentIndex < highlight.startChapter) {
        textSpans.add(TextSpan(
          text: widget.text.substring(currentIndex, highlight.startChapter),
          style: widget.style,
        ));
      }

      // Ajouter le texte surligné
      textSpans.add(TextSpan(
        text: highlight.selectedText,
        style: (widget.style ?? const TextStyle()).copyWith(
          backgroundColor: highlight.highlightColor.withOpacity(0.3),
          color: highlight.highlightColor,
          fontWeight: FontWeight.w600,
        ),
      ));

      currentIndex = highlight.endChapter;
    }

    // Ajouter le texte restant
    if (currentIndex < widget.text.length) {
      textSpans.add(TextSpan(
        text: widget.text.substring(currentIndex),
        style: widget.style,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: textSpans),
      textAlign: widget.textAlign,
      onSelectionChanged: (selection, cause) {
        setState(() {
          if (selection.isCollapsed) {
            _isTextSelected = false;
            _selectedText = '';
          } else {
            _isTextSelected = true;
            _selectedText = selection.textInside(widget.text);
            _currentSelection = selection;
          }
        });
      },
    );
  }

}