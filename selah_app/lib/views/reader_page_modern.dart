import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/reader_settings_service.dart';
import '../services/bible_text_service.dart';
import '../widgets/highlightable_text.dart';
import '../widgets/uniform_back_button.dart';
import '../models/reading_passage.dart';
import '../services/bible_version_manager.dart';
import '../services/user_prefs.dart';

class ReaderPageModern extends StatefulWidget {
  final String? passageRef;
  final String? passageText;
  final String? dayTitle;
  final List<String>? passageRefs; // Support pour passages multiples
  final ReadingSession? readingSession; // Session complète
  
  const ReaderPageModern({
    super.key,
    this.passageRef,
    this.passageText,
    this.dayTitle,
    this.passageRefs,
    this.readingSession,
  });

  @override
  State<ReaderPageModern> createState() => _ReaderPageModernState();
}

class _ReaderPageModernState extends State<ReaderPageModern>
    with TickerProviderStateMixin {
  final bool _isFavorite = false;
  bool _isMarkedAsRead = false;
  late AnimationController _buttonAnimationController;
  String _notedVerse = ''; // Verset noté par l'utilisateur
  
  
  // Passage data
  late final String _passageRef;
  String _passageText = '';
  late final String _dayTitle;
  bool _isLoadingText = true;
  
  // Multi-passage support
  late ReadingSession _readingSession;
  
  // Version selection
  String _selectedVersion = 'lsg1910'; // ✅ Version VideoPsalm par défaut
  List<Map<String, String>> _availableVersions = [];

  @override
  void initState() {
    super.initState();
    
    // ✅ Charger la version de Bible de l'utilisateur
    _loadUserBibleVersion();
    
    // Initialiser la session de lecture
    _initializeReadingSession();
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
  }
  
  /// ✅ Charge la version de Bible de l'utilisateur
  Future<void> _loadUserBibleVersion() async {
    try {
      final profile = await UserPrefs.loadProfile();
      final userVersion = profile['bibleVersion'] as String?;
      if (userVersion != null && userVersion.isNotEmpty) {
        setState(() {
          _selectedVersion = userVersion;
        });
        print('📖 Version utilisateur chargée: $userVersion');
      }
    } catch (e) {
      print('⚠️ Erreur chargement version utilisateur: $e');
    }
  }
  
  /// Initialise la session de lecture selon les paramètres fournis
  void _initializeReadingSession() {
    if (widget.readingSession != null) {
      // Session complète fournie
      _readingSession = widget.readingSession!;
    } else if (widget.passageRefs != null && widget.passageRefs!.isNotEmpty) {
      // Plusieurs références fournies
      _readingSession = ReadingSession.fromReferences(
        references: widget.passageRefs!,
        dayTitle: widget.dayTitle,
      );
    } else {
      // Une seule référence (rétrocompatibilité)
      _readingSession = ReadingSession.fromSingleReference(
        reference: widget.passageRef ?? 'Jean 14:1-19',
        text: widget.passageText,
        title: widget.dayTitle,
        dayTitle: widget.dayTitle ?? 'Jour 15',
      );
    }
    
    // Initialiser les variables de compatibilité
    _passageRef = _readingSession.currentPassage?.reference ?? 'Jean 14:1-19';
    _dayTitle = _readingSession.dayTitle ?? 'Jour 15';
    
    // Charger les versions disponibles
    _loadAvailableVersions();
    
    // Charger tous les passages
    _loadAllPassages();
  }

  /// Charge tous les passages de la session
  Future<void> _loadAllPassages() async {
    try {
      await BibleTextService.init();
      
      // Charger tous les passages en parallèle
      final futures = _readingSession.passages.asMap().entries.map((entry) {
        final index = entry.key;
        final passage = entry.value;
        return _loadSinglePassage(index, passage);
      });
      
      await Future.wait(futures);
      
      // Mettre à jour le texte du passage actuel
      _updateCurrentPassageText();
      
    } catch (e) {
      print('⚠️ Erreur chargement passages multiples: $e');
      setState(() {
        _isLoadingText = false;
      });
    }
  }
  
  /// Charge un passage spécifique
  Future<void> _loadSinglePassage(int index, ReadingPassage passage) async {
    try {
      // Marquer comme en cours de chargement
      setState(() {
        _readingSession = _readingSession.updatePassage(
          index,
          passage.copyWith(isLoading: true),
        );
      });
      
      // Récupérer le texte depuis la base de données avec la version sélectionnée
      final text = await BibleTextService.getPassageText(passage.reference, version: _selectedVersion);
      
      if (mounted) {
        setState(() {
          _readingSession = _readingSession.updatePassage(
            index,
            passage.copyWith(
              text: text ?? _getFallbackText(passage.reference),
              isLoaded: true,
              isLoading: false,
              error: text == null ? 'Texte non trouvé' : null,
            ),
          );
        });
      }
    } catch (e) {
      print('⚠️ Erreur chargement passage ${passage.reference}: $e');
      if (mounted) {
        setState(() {
          _readingSession = _readingSession.updatePassage(
            index,
            passage.copyWith(
              text: _getFallbackText(passage.reference),
              isLoaded: true,
              isLoading: false,
              error: e.toString(),
            ),
          );
        });
      }
    }
  }
  
  /// Met à jour le texte du passage actuel
  void _updateCurrentPassageText() {
    final currentPassage = _readingSession.currentPassage;
    if (currentPassage != null && currentPassage.isReady) {
      setState(() {
        _passageText = currentPassage.text!;
        _isLoadingText = false;
      });
    } else {
      setState(() {
        _isLoadingText = _readingSession.hasLoadingPassages;
      });
    }
  }
  
  /// Charge le texte biblique depuis la base de données (rétrocompatibilité)
  Future<void> _loadBibleText() async {
    try {
      // Initialiser le service si nécessaire
      await BibleTextService.init();
      
      // Si un texte est déjà fourni, l'utiliser
      if (widget.passageText != null && widget.passageText!.isNotEmpty) {
        setState(() {
          _passageText = widget.passageText!;
          _isLoadingText = false;
        });
        return;
      }
      
      // Sinon, récupérer depuis la base de données avec la version sélectionnée
      final text = await BibleTextService.getPassageText(_passageRef, version: _selectedVersion);
      
      if (mounted) {
        setState(() {
          _passageText = text ?? _getFallbackText();
          _isLoadingText = false;
        });
      }
      
      if (text == null) {
        print('⚠️ Texte non trouvé pour: $_passageRef');
      }
    } catch (e) {
      print('⚠️ Erreur chargement texte biblique: $e');
      if (mounted) {
        setState(() {
          _passageText = _getFallbackText();
          _isLoadingText = false;
        });
      }
    }
  }

  /// Texte de fallback si la base de données n'est pas disponible
  String _getFallbackText([String? reference]) {
    return '''Que votre cœur ne se trouble point. Croyez en Dieu, et croyez en moi.

Il y a plusieurs demeures dans la maison de mon Père. Si cela n'était pas, je vous l'aurais dit. Je vais vous préparer une place.

Et, lorsque je m'en serai allé, et que je vous aurai préparé une place, je reviendrai, et je vous prendrai avec moi, afin que là où je suis vous y soyez aussi.

Vous savez où je vais, et vous en savez le chemin.

Thomas lui dit: Seigneur, nous ne savons où tu vas; comment pouvons-nous en savoir le chemin?

Jésus lui dit: Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.

Si vous me connaissiez, vous connaîtriez aussi mon Père. Et dès maintenant vous le connaissez, et vous l'avez vu.

Philippe lui dit: Seigneur, montre-nous le Père, et cela nous suffit.

Jésus lui dit: Il y a si longtemps que je suis avec vous, et tu ne m'as pas connu, Philippe! Celui qui m'a vu a vu le Père; comment dis-tu: Montre-nous le Père?

Ne crois-tu pas que je suis dans le Père, et que le Père est en moi? Les paroles que je vous dis, je ne les dis pas de moi-même; et le Père qui demeure en moi, c'est lui qui fait les œuvres.

Croyez-moi, je suis dans le Père, et le Père est en moi; croyez du moins à cause de ces œuvres.

En vérité, en vérité, je vous le dis, celui qui croit en moi fera aussi les œuvres que je fais, et il en fera de plus grandes, parce que je m'en vais au Père;

et tout ce que vous demanderez en mon nom, je le ferai, afin que le Père soit glorifié dans le Fils.

Si vous demandez quelque chose en mon nom, je le ferai.

Si vous m'aimez, gardez mes commandements.

Et moi, je prierai le Père, et il vous donnera un autre consolateur, afin qu'il demeure éternellement avec vous,

l'Esprit de vérité, que le monde ne peut recevoir, parce qu'il ne le voit point et ne le connaît point; mais vous, vous le connaissez, car il demeure avec vous, et il sera en vous.

Je ne vous laisserai pas orphelins, je viendrai à vous.

Encore un peu de temps, et le monde ne me verra plus; mais vous, vous me verrez, car je vis, et vous vivrez aussi.''';
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }



  void _markAsRead() {
    setState(() {
      _isMarkedAsRead = !_isMarkedAsRead;
    });
    HapticFeedback.mediumImpact();
    
    if (_isMarkedAsRead) {
      // Afficher le bottom sheet pour noter le verset marquant
      _showVerseNoteBottomSheet();
    } else {
      _showSnackBar(
        'Marqué comme non lu',
        Icons.radio_button_unchecked,
        Colors.grey,
      );
    }
  }

  void _goToMeditation() {
    // Vérifier si le texte est marqué comme lu
    if (!_isMarkedAsRead) {
      _showSnackBar(
        'Veuillez d\'abord marquer le texte comme lu',
        Icons.info,
        Colors.orange,
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    context.go('/meditation/chooser', extra: {
      'passageRef': _passageRef,
      'passageText': _passageText,
      'memoryVerse': _notedVerse, // Verset noté par l'utilisateur
    }); // page avec 2 options
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _findExactVerse(String userText) {
    // Use the dynamic passage text
    final fullPassage = _passageText;

    // Normaliser le texte utilisateur (supprimer espaces, ponctuation, majuscules)
    final normalizedUserText = userText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Diviser le passage en phrases/versets
    final sentences = fullPassage.split(RegExp(r'[.!?]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Chercher la correspondance la plus proche
    String bestMatch = '';
    int bestScore = 0;

    for (final sentence in sentences) {
      final normalizedSentence = sentence
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Calculer un score de similarité basique
      int score = 0;
      final userWords = normalizedUserText.split(' ');
      final sentenceWords = normalizedSentence.split(' ');

      for (final userWord in userWords) {
        if (userWord.length > 2) { // Ignorer les mots trop courts
          for (final sentenceWord in sentenceWords) {
            if (sentenceWord.contains(userWord) || userWord.contains(sentenceWord)) {
              score += userWord.length; // Plus le mot est long, plus il compte
            }
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = sentence;
      }
    }

    // Si on trouve une correspondance significative, la retourner
    if (bestScore > 10 && bestMatch.isNotEmpty) {
      return bestMatch;
    }

    // Sinon, retourner le texte utilisateur tel quel
    return userText;
  }

  void _showVerseNoteBottomSheet() {
    final TextEditingController verseController = TextEditingController(text: _notedVerse);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Notez le verset qui vous a marqué',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Recopiez simplement le texte qui vous a touché. Il sera utilisé pour créer votre poster.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Zone de texte
                Expanded(
                  child: TextField(
                    controller: verseController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    enableInteractiveSelection: true,
                    autocorrect: false,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écrivez le verset qui vous a marqué...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Passer',
                          style: GoogleFonts.inter(
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
                          final userText = verseController.text.trim();
                          if (userText.isNotEmpty) {
                            // Analyser le texte pour trouver le verset exact
                            final exactVerse = _findExactVerse(userText);
                            setState(() {
                              _notedVerse = exactVerse;
                            });
                            Navigator.of(context).pop();
                            _showSnackBar(
                              'Verset analysé et noté !',
                              Icons.check_circle,
                              Colors.green,
                            );
                          } else {
                            Navigator.of(context).pop();
                            _showSnackBar(
                              'Aucun texte saisi',
                              Icons.info,
                              Colors.orange,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sauvegarder',
                          style: GoogleFonts.inter(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildMainContent(),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return UniformHeader(
      title: _dayTitle,
      subtitle: _passageRef,
      onBackPressed: () => context.pop(),
      textColor: Colors.grey.shade800,
      iconColor: Colors.grey.shade700,
      titleAlignment: CrossAxisAlignment.center,
      trailing: GestureDetector(
        onTap: () => context.go('/reader_settings'),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_rounded,
            color: Colors.grey.shade700,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: _buildTextContent(),
          ),
          _buildBottomWidgets(),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Consumer<ReaderSettingsService>(
      builder: (context, settings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec navigation si plusieurs passages
              _buildPassageHeader(),
              const SizedBox(height: 16),
              
              // Contenu du passage
              if (_isLoadingText)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                HighlightableText(
                  text: _passageText,
                  style: settings.getFontStyle(),
                  textAlign: settings.getTextAlign(),
                ),
            ],
          ),
        );
      },
    );
  }
  
  /// Construit l'en-tête avec navigation pour les passages multiples
  Widget _buildPassageHeader() {
    if (!_readingSession.hasMultiplePassages) {
      // Un seul passage - affichage simple
      return Text(
        _passageRef,
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D2D2D),
        ),
      );
    }
    
    // Plusieurs passages - affichage avec navigation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur de progression
        Row(
          children: [
            Text(
              'Passage ${_readingSession.currentPassageIndex + 1} sur ${_readingSession.totalPassages}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            // Boutons de navigation
            Row(
              children: [
                // Bouton précédent
                if (_readingSession.canGoToPrevious)
                  GestureDetector(
                    onTap: _goToPreviousPassage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Bouton suivant
                if (_readingSession.canGoToNext)
                  GestureDetector(
                    onTap: _goToNextPassage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Référence du passage actuel
        Text(
          _passageRef,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        // Liste des passages (mini-indicateurs)
        _buildPassageIndicators(),
        const SizedBox(height: 12),
        // Sélecteur de version
        _buildVersionSelector(),
      ],
    );
  }
  
  /// Construit les indicateurs de passages
  Widget _buildPassageIndicators() {
    return Row(
      children: _readingSession.passages.asMap().entries.map((entry) {
        final index = entry.key;
        final passage = entry.value;
        final isCurrent = index == _readingSession.currentPassageIndex;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _readingSession = _readingSession.copyWith(currentPassageIndex: index);
              _updateCurrentPassageText();
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent ? Border.all(color: Colors.blue.shade300) : null,
            ),
            child: Text(
              passage.autoTitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                color: isCurrent ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  /// Construit le sélecteur de version
  Widget _buildVersionSelector() {
    if (_availableVersions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentVersion = _availableVersions.firstWhere(
      (v) => v['id'] == _selectedVersion,
      orElse: () => _availableVersions.first,
    );
    
    return GestureDetector(
      onTap: _showVersionSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              currentVersion['name']!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomWidgets() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildActionButtons(),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _markAsRead,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _isMarkedAsRead ? Colors.green.shade600 : Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // ✅ Éviter l'overflow
                children: [
                  Flexible( // ✅ Permettre au texte de se réduire
                    child: Text(
                      'Marquer comme lu',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _goToMeditation,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _isMarkedAsRead ? Colors.black : Colors.grey[400],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // ✅ Éviter l'overflow
                children: [
                  Flexible( // ✅ Permettre au texte de se réduire
                    child: Text(
                      'Méditation',
                      style: GoogleFonts.inter(
                        color: _isMarkedAsRead ? Colors.white : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomAction(Icons.note_add_rounded, 'Note', Colors.blue),
          _buildBottomAction(Icons.highlight_alt_rounded, 'Surligner', Colors.yellow),
          _buildBottomAction(Icons.share_rounded, 'Partager', Colors.green),
          _buildBottomAction(Icons.bookmark_rounded, 'Marque-page', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSnackBar('$label activé', icon, color);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Navigue vers le passage suivant
  void _goToNextPassage() {
    if (_readingSession.canGoToNext) {
      setState(() {
        _readingSession = _readingSession.goToNext();
        _updateCurrentPassageText();
      });
      HapticFeedback.selectionClick();
    }
  }
  
  /// Navigue vers le passage précédent
  void _goToPreviousPassage() {
    if (_readingSession.canGoToPrevious) {
      setState(() {
        _readingSession = _readingSession.goToPrevious();
        _updateCurrentPassageText();
      });
      HapticFeedback.selectionClick();
    }
  }
  
  /// Charge les versions de Bible disponibles
  Future<void> _loadAvailableVersions() async {
    try {
      final stats = await BibleVersionManager.getDownloadStats();
      final downloadedVersions = stats['versions'] as List<dynamic>? ?? [];
      
      setState(() {
        _availableVersions = downloadedVersions.map((v) => {
          'id': v['id'] as String,
          'name': v['name'] as String,
          'language': v['language'] as String,
        }).toList();
        
        // Sélectionner la première version disponible ou LSG par défaut
        if (_availableVersions.isNotEmpty) {
          _selectedVersion = _availableVersions.first['id']!;
        }
      });
    } catch (e) {
      print('⚠️ Erreur chargement versions: $e');
    }
  }
  
  /// Change la version de Bible
  Future<void> _changeVersion(String versionId) async {
    if (versionId == _selectedVersion) return;
    
    setState(() {
      _selectedVersion = versionId;
      _isLoadingText = true;
    });
    
    // Recharger le passage avec la nouvelle version
    await _loadAllPassages();
  }
  
  /// Affiche le sélecteur de version
  void _showVersionSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir une version',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ..._availableVersions.map((version) => _buildVersionOption(version)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construit une option de version
  Widget _buildVersionOption(Map<String, String> version) {
    final isSelected = version['id'] == _selectedVersion;
    
    return GestureDetector(
      onTap: () {
        _changeVersion(version['id']!);
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.blue
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version['name']!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    version['language']!.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

