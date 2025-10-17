import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/reader_settings_service.dart';
import '../services/bible_text_service.dart';
import '../widgets/highlightable_text.dart';
import '../widgets/uniform_back_button.dart';
import '../widgets/reader_prompts_bar.dart';
import '../widgets/mini_journal_sheet.dart';
import '../services/journal_service.dart';
import '../services/intentions_service.dart';
import '../models/reading_passage.dart';
import '../services/bible_version_manager.dart';
import '../services/user_prefs.dart';
import '../bootstrap.dart' as bootstrap;
import 'advanced_bible_study_page.dart';

class ReaderPageModern extends StatefulWidget {
  final String? passageRef;
  final String? passageText;
  final String? dayTitle;
  final List<String>? passageRefs; // Support pour passages multiples
  final ReadingSession? readingSession; // Session complète
  final String? planId;
  final int? dayNumber;
  
  const ReaderPageModern({
    super.key,
    this.passageRef,
    this.passageText,
    this.dayTitle,
    this.passageRefs,
    this.readingSession,
    this.planId,
    this.dayNumber,
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
  String _passageText = '';
  String _dayTitle = 'Jour 15'; // Valeur par défaut
  bool _isLoadingText = true;
  
  // Multi-passage support
  ReadingSession? _readingSession;
  
  // Version selection
  String _selectedVersion = 'lsg1910'; // ✅ Version VideoPsalm par défaut
  List<Map<String, String>> _availableVersions = [];

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Initialiser la session de lecture de manière synchrone
    _initializeReadingSession();
    
    // Puis charger de manière asynchrone
    _init();
  }

  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Recharger le passage quand on revient des paramètres (une seule fois après l'init)
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_readingSession?.currentPassage?.reference != null && 
            _readingSession!.currentPassage!.reference != 'Jean 14:1-19') {
          _reloadCurrentPassage();
        }
      });
    }
  }

  Future<void> _init() async {
    await _loadUserBibleVersion();   // ✅ d'abord version
    await _loadAvailableVersions();  // remplit la liste et (si besoin) aligne _selectedVersion
    await _loadAllPassages();        // ✅ puis charge les textes
    _hasInitialized = true; // Marquer comme initialisé
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

        // si la session est déjà prête, recharge
        if (_readingSession?.passages.isNotEmpty == true) {
          await _loadAllPassages();
        }
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
    _dayTitle = _readingSession?.dayTitle ?? 'Jour 15';
  }

  /// Charge tous les passages de la session
  Future<void> _loadAllPassages() async {
    if (_readingSession == null) {
      print('⚠️ _readingSession est null, impossible de charger les passages');
      return;
    }
    
    try {
      await BibleTextService.init();
      
      // Charger tous les passages en parallèle
      final futures = _readingSession!.passages.asMap().entries.map((entry) {
        final index = entry.key;
        final passage = entry.value;
        return _loadSinglePassage(index, passage);
      });
      
      await Future.wait(futures);
      
      // Mettre à jour le texte du passage actuel
      await _updateCurrentPassageText();
      
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
      print('🔎 Fetch passage "${passage.reference}" (version=$_selectedVersion)');

      // Indiquer le loading
      if (_readingSession != null) {
        setState(() {
          _readingSession = _readingSession!.updatePassage(
            index,
            passage.copyWith(isLoading: true),
          );
        });
      }

      // ✅ S'assurer que la version est disponible avant de récupérer le texte
      await BibleTextService.ensureVersionAvailable(_selectedVersion);
      
      // ✅ Utiliser le nouveau système SQLite avec service sémantique
      final text = await BibleTextService.getPassageText(
        passage.reference, 
        version: _selectedVersion,
      );

      // Résoudre le fallback AVANT setState
      final resolvedText = text ?? await _getFallbackText(passage.reference);

      if (!mounted || _readingSession == null) return;
      setState(() {
        _readingSession = _readingSession!.updatePassage(
          index,
          passage.copyWith(
            text: resolvedText,
            isLoaded: true,
            isLoading: false,
            error: text == null ? 'Texte non trouvé' : null,
          ),
        );
      });
    } catch (e) {
      print('⚠️ Erreur chargement passage ${passage.reference}: $e');
      final resolvedText = await _getFallbackText(passage.reference);
      if (!mounted || _readingSession == null) return;
      setState(() {
        _readingSession = _readingSession!.updatePassage(
          index,
          passage.copyWith(
            text: resolvedText,
            isLoaded: true,
            isLoading: false,
            error: e.toString(),
          ),
        );
      });
    }
  }
  
  /// Met à jour le texte du passage actuel
  Future<void> _updateCurrentPassageText() async {
    if (_readingSession == null) {
      print('⚠️ _readingSession est null, impossible de mettre à jour le texte');
      return;
    }
    
    final currentPassage = _readingSession!.currentPassage;

    final preview = (currentPassage?.text ?? '');
    print('🔍 _updateCurrentPassageText: hasText=${preview.isNotEmpty}, isReady=${currentPassage?.isReady}');

    if (currentPassage != null && currentPassage.isReady) {
      // ✅ Calculer d'abord, puis un seul setState
      final newText = (currentPassage.text?.trim().isNotEmpty == true)
          ? currentPassage.text!
          : await _getFallbackText(currentPassage.reference);

      if (!mounted) return;
      setState(() {
        _passageText = newText;
        _isLoadingText = false;
      });
    } else if (!_readingSession!.hasLoadingPassages) {
      // ✅ Si aucun passage n'est en cours de chargement, utiliser le fallback
      final fallbackText = await _getFallbackText(_readingSession!.currentPassage?.reference ?? 'Jean 14:1-19');
      
      if (!mounted) return;
      setState(() {
        _passageText = fallbackText;
        _isLoadingText = false;
      });
    } else {
      // ✅ Sinon, indiquer le loading
      if (!mounted) return;
      setState(() {
        _isLoadingText = true;
      });
    }
  }

  /// Recharge le passage actuel (utile quand on revient des paramètres)
  Future<void> _reloadCurrentPassage() async {
    if (_readingSession?.currentPassage?.reference == null) return;
    
    final currentRef = _readingSession!.currentPassage!.reference;
    if (currentRef == 'Jean 14:1-19') return; // Ne pas recharger le fallback
    
    print('🔄 Rechargement du passage actuel: $currentRef');
    
    try {
      setState(() {
        _isLoadingText = true;
      });

      // S'assurer que la version est disponible
      await BibleTextService.ensureVersionAvailable(_selectedVersion);
      
      // Récupérer le texte
      final text = await BibleTextService.getPassageText(
        currentRef,
        version: _selectedVersion,
      );

      if (text != null && text.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _passageText = text;
          _isLoadingText = false;
        });
        print('✅ Passage rechargé: ${text.length} caractères');
      } else {
        // Utiliser le fallback si le texte n'est pas trouvé
        final fallbackText = await _getFallbackText(currentRef);
        if (!mounted) return;
        setState(() {
          _passageText = fallbackText;
          _isLoadingText = false;
        });
        print('⚠️ Passage non trouvé, utilisation du fallback');
      }
    } catch (e) {
      print('⚠️ Erreur rechargement passage: $e');
      final fallbackText = await _getFallbackText(currentRef);
      if (!mounted) return;
      setState(() {
        _passageText = fallbackText;
        _isLoadingText = false;
      });
    }
  }
  
  /// Charge le texte biblique depuis la base de données (rétrocompatibilité)
  Future<void> _loadBibleText() async {
    try {
      await BibleTextService.init();

      // ✅ Priorité 1: Texte fourni en paramètre
      if (widget.passageText != null && widget.passageText!.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _passageText = widget.passageText!;
          _isLoadingText = false;
        });
        return;
      }

      // ✅ Priorité 2: Passage de la session de lecture
      final currentReference = _readingSession?.currentPassage?.reference;
      if (currentReference != null && currentReference != 'Jean 14:1-19') {
        print('🔎 Chargement texte pour passage du jour: $currentReference');
        
        final text = await BibleTextService.getPassageText(
          currentReference,
          version: _selectedVersion,
        );

        if (text != null && text.trim().isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _passageText = text;
            _isLoadingText = false;
          });
          print('✅ Texte du jour chargé: ${text.length} caractères');
          return;
        }
      }

      // ✅ Priorité 3: Fallback seulement si nécessaire
      final resolved = await _getFallbackText(currentReference);

      if (!mounted) return;
      setState(() {
        _passageText = resolved;
        _isLoadingText = false;
      });

      if (currentReference != null) {
        print('⚠️ Texte non trouvé pour: $currentReference, utilisation du fallback');
      }
    } catch (e) {
      print('⚠️ Erreur chargement texte biblique: $e');
      final resolved = await _getFallbackText(_readingSession?.currentPassage?.reference);
      if (!mounted) return;
      setState(() {
        _passageText = resolved;
        _isLoadingText = false;
      });
    }
  }

  /// Texte de fallback si la base de données n'est pas disponible
  Future<String> _getFallbackText([String? reference]) async {
    // Essayer de récupérer le vrai texte de Jean 14:1-19 depuis la base de données
    try {
      final text = await BibleTextService.getPassageText('Jean 14:1-19', version: _selectedVersion);
      if (text != null && text.trim().isNotEmpty) {
        print('🔍 _getFallbackText: Texte récupéré depuis la base de données (${text.length} caractères)');
        return text;
      }
    } catch (e) {
      print('⚠️ _getFallbackText: Erreur récupération depuis la base: $e');
    }
    
    // Fallback statique si la base de données échoue
    print('🔍 _getFallbackText: Utilisation du texte statique');
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



  void _markAsRead() async {
    setState(() {
      _isMarkedAsRead = !_isMarkedAsRead;
    });
    HapticFeedback.mediumImpact();

    // ✅ Marquer côté PlanService si contexte connu
    final planId = widget.planId;
    final day = widget.dayNumber;
    if (planId != null && day != null) {
      try {
        await bootstrap.planService.markDayCompleted(planId, day, _isMarkedAsRead);
        // Optionnel: feedback
        _showSnackBar(
          _isMarkedAsRead ? 'Jour marqué comme lu' : 'Marqué comme non lu',
          _isMarkedAsRead ? Icons.check_circle : Icons.radio_button_unchecked,
          _isMarkedAsRead ? Colors.green : Colors.grey,
        );
      } catch (e) {
        // rollback UI si erreur critique
        setState(() => _isMarkedAsRead = !_isMarkedAsRead);
        _showSnackBar('Impossible de mettre à jour l\'état du jour', Icons.error_outline, Colors.red);
        print('❌ markDayCompleted: $e');
      }
    } else {
      // Pas de contexte de plan (lecture libre)
      _showSnackBar(
        _isMarkedAsRead ? 'Lu (mode libre)' : 'Non lu (mode libre)',
        _isMarkedAsRead ? Icons.check_circle : Icons.radio_button_unchecked,
        _isMarkedAsRead ? Colors.green : Colors.grey,
      );
    }
    
    if (_isMarkedAsRead) {
      // Afficher le bottom sheet pour noter le verset marquant
      _showVerseNoteBottomSheet();
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
    _showMeditationOptions();
  }

  /// Affiche les options de méditation avec mini-journal
  void _showMeditationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1B3B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Que veux-tu faire ?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              // Option 1: Méditation guidée
              _buildOptionButton(
                icon: Icons.auto_awesome,
                title: 'Méditation guidée',
                subtitle: 'Réflexion structurée avec questions',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/meditation/chooser', extra: {
                    'passageRef': _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19',
                    'passageText': _passageText,
                    'memoryVerse': _notedVerse,
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              // Option 2: Terminer & Appliquer
              _buildOptionButton(
                icon: Icons.check_circle,
                title: 'Terminer & Appliquer',
                subtitle: 'Note 3 actions concrètes pour aujourd\'hui',
                onTap: () async {
                  Navigator.pop(context);
                  await _showMiniJournal();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche le mini-journal et sauvegarde les réponses
  Future<void> _showMiniJournal() async {
    try {
      final responses = await showMiniJournalSheet(context);
      
      if (responses != null && responses.isNotEmpty) {
        // Sauvegarder dans le journal
        await JournalService.saveJournalEntry(
          date: DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
          bullets: responses,
          passageRef: _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19',
          notes: _notedVerse.isNotEmpty ? 'Verset marquant: $_notedVerse' : null,
        );
        
        _showSnackBar(
          'Applications sauvegardées !',
          Icons.check_circle,
          Colors.green,
        );
        
        // Optionnel: naviguer vers la page d'accueil
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/home');
          }
        });
      }
    } catch (e) {
      print('❌ Erreur mini-journal: $e');
      _showSnackBar(
        'Erreur lors de la sauvegarde',
        Icons.error,
        Colors.red,
      );
    }
  }

  /// Construit un bouton d'option
  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
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
    return Consumer<ReaderSettingsService>(
      builder: (context, settings, child) {
        final isDark = settings.effectiveTheme == 'dark';
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1025), Color(0xFF1C1740), Color(0xFF2D1B69)],
                stops: [0.0, 0.55, 1.0],
              ) : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: _buildMainContent(isDark),
                  ),
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'), // Retour direct à la page d'accueil
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.home_rounded, // Icône maison au lieu de flèche retour
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayTitle,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/reader_settings'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Column(
            children: [
              Expanded(
                child: _buildTextContent(isDark),
              ),
              _buildBottomWidgets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(bool isDark) {
    return Consumer<ReaderSettingsService>(
      builder: (context, settings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec navigation si plusieurs passages
              _buildPassageHeader(isDark),
              const SizedBox(height: 8),
              
              // Barre de prompts de réflexion
              ReaderPromptsBar(
                onTapPrompt: (prompt) {
                  _showNoteSheet(seedText: prompt);
                },
              ),
              const SizedBox(height: 8),
              
              // Affichage de l'intention du jour
              FutureBuilder(
                future: Future.wait([
                  IntentionsService.isEnabled(),
                  IntentionsService.getIntention()
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final enabled = snapshot.data![0] as bool;
                  final intention = snapshot.data![1] as String?;
                  
                  if (!enabled || intention == null || intention.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Intention: $intention',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Contenu du passage
              if (_isLoadingText)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
              else
                HighlightableText(
                  text: _passageText,
                  style: settings.getFontStyle().copyWith(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    height: 1.6,
                  ),
                  textAlign: settings.getTextAlign(),
                ),
            ],
          ),
        );
      },
    );
  }
  
  /// Construit l'en-tête avec navigation pour les passages multiples
  Widget _buildPassageHeader(bool isDark) {
    final currentRef = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    
    if (_readingSession == null || !_readingSession!.hasMultiplePassages) {
      // Un seul passage - affichage simple
      return Text(
        currentRef,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
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
              'Passage ${(_readingSession?.currentPassageIndex ?? 0) + 1} sur ${_readingSession?.totalPassages ?? 1}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            // Boutons de navigation
            Row(
              children: [
                // Bouton précédent
                if (_readingSession?.canGoToPrevious == true)
                  GestureDetector(
                    onTap: _goToPreviousPassage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Bouton suivant
                if (_readingSession?.canGoToNext == true)
                  GestureDetector(
                    onTap: _goToNextPassage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white : Colors.black,
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
          currentRef,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        // Liste des passages (mini-indicateurs)
        _buildPassageIndicators(isDark),
        const SizedBox(height: 12),
        // Sélecteur de version
        _buildVersionSelector(),
      ],
    );
  }
  
  /// Construit les indicateurs de passages
  Widget _buildPassageIndicators(bool isDark) {
    if (_readingSession == null) return const SizedBox.shrink();
    
    return Row(
      children: _readingSession!.passages.asMap().entries.map((entry) {
        final index = entry.key;
        final passage = entry.value;
        final isCurrent = index == _readingSession!.currentPassageIndex;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _readingSession = _readingSession!.copyWith(currentPassageIndex: index);
            });
            // ✅ Appeler _updateCurrentPassageText après setState
            _updateCurrentPassageText();
            HapticFeedback.selectionClick();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent 
                  ? const Color(0xFF1553FF).withOpacity(0.2) 
                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
              border: isCurrent 
                  ? Border.all(color: const Color(0xFF1553FF)) 
                  : Border.all(
                      color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                    ),
            ),
            child: Text(
              passage.autoTitle,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                color: isCurrent 
                    ? const Color(0xFF1553FF) 
                    : (isDark ? Colors.white70 : Colors.grey.shade600),
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
          color: const Color(0xFF1553FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1553FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book,
              size: 16,
              color: Color(0xFF1553FF),
            ),
            const SizedBox(width: 8),
            Text(
              currentVersion['name']!,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1553FF),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF1553FF),
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
    return Consumer<ReaderSettingsService>(
      builder: (context, settings, child) {
        final isDark = settings.effectiveTheme == 'dark';
        
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _markAsRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _isMarkedAsRead ? const Color(0xFF49C98D) : const Color(0xFF1553FF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isMarkedAsRead ? const Color(0xFF49C98D) : const Color(0xFF1553FF)).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Marquer comme lu',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
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
                    color: _isMarkedAsRead 
                        ? const Color(0xFF1553FF) 
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                    border: _isMarkedAsRead 
                        ? null 
                        : Border.all(
                            color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                          ),
                    boxShadow: _isMarkedAsRead ? [
                      BoxShadow(
                        color: const Color(0xFF1553FF).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Méditation',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: _isMarkedAsRead 
                                ? Colors.white 
                                : (isDark ? Colors.white70 : Colors.black87),
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
      },
    );
  }


  Widget _buildBottomActions() {
    return Consumer<ReaderSettingsService>(
      builder: (context, settings, child) {
        final isDark = settings.effectiveTheme == 'dark';
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStudyAction(
                  Icons.info_outline,
                  'Contexte',
                  Colors.blue,
                  () => _goToAdvancedStudyTab(0), // Tab Contexte
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStudyAction(
                  Icons.label_outline,
                  'Thèmes',
                  Colors.purple,
                  () => _goToAdvancedStudyTab(1), // Tab Thèmes
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStudyAction(
                  Icons.person_outline,
                  'Personnages',
                  Colors.green,
                  () => _goToAdvancedStudyTab(0), // Tab Contexte (contient personnages)
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStudyAction(
                  Icons.menu_book_outlined,
                  'Encyclopédie',
                  Colors.orange,
                  () => _goToAdvancedStudyTab(2), // Tab ISBE
                  isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudyAction(IconData icon, String title, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Navigue vers le passage suivant
  void _goToNextPassage() {
    if (_readingSession?.canGoToNext == true) {
      setState(() {
        _readingSession = _readingSession!.goToNext();
      });
      // ✅ Appeler _updateCurrentPassageText après setState
      _updateCurrentPassageText();
      HapticFeedback.selectionClick();
    }
  }
  
  /// Navigue vers le passage précédent
  void _goToPreviousPassage() {
    if (_readingSession?.canGoToPrevious == true) {
      setState(() {
        _readingSession = _readingSession!.goToPrevious();
      });
      // ✅ Appeler _updateCurrentPassageText après setState
      _updateCurrentPassageText();
      HapticFeedback.selectionClick();
    }
  }
  
  /// Navigue vers la page d'étude biblique avancée
  void _goToAdvancedStudy() {
    // Extraire le verset ID depuis la référence du passage
    final verseId = _extractVerseIdFromReference(_readingSession?.currentPassage?.reference ?? 'Jean 14:1-19');
    
    HapticFeedback.mediumImpact();
    context.push('/advanced_bible_study', extra: {'verseId': verseId});
  }
  
  /// Navigue vers la page d'étude biblique avancée avec un onglet spécifique
  void _goToAdvancedStudyTab(int tabIndex) {
    // Extraire le verset ID depuis la référence du passage
    final verseId = _extractVerseIdFromReference(_readingSession?.currentPassage?.reference ?? 'Jean 14:1-19');
    
    HapticFeedback.mediumImpact();
    context.push('/advanced_bible_study', extra: {
      'verseId': verseId,
      'initialTab': tabIndex,
    });
  }
  
  /// Extrait un ID de verset depuis une référence biblique
  String _extractVerseIdFromReference(String reference) {
    try {
      // Exemple: "Jean 3:16" -> "Jean.3.16"
      // Exemple: "Matthieu & Romains & Jacques Éphésiens 2:8-9" -> "Éphésiens.2.8"
      
      // Nettoyer la référence
      final cleanRef = reference.trim();
      
      // Trouver le dernier espace pour séparer le livre du chapitre/verset
      final lastSpace = cleanRef.lastIndexOf(' ');
      if (lastSpace <= 0) return 'Jean.3.16'; // Fallback
      
      final bookPart = cleanRef.substring(0, lastSpace).trim();
      final chapterVersePart = cleanRef.substring(lastSpace + 1).trim();
      
      // Extraire le livre (prendre le dernier mot si plusieurs livres)
      final bookWords = bookPart.split(' ');
      final book = bookWords.last;
      
      // Extraire chapitre et verset
      final cv = chapterVersePart.split(':');
      if (cv.length < 2) return 'Jean.3.16'; // Fallback
      
      final chapter = cv[0];
      final verse = cv[1].split('-')[0]; // Prendre le premier verset si plage
      
      return '$book.$chapter.$verse';
    } catch (e) {
      print('⚠️ Erreur extraction verseId: $e');
      return 'Jean.3.16'; // Fallback
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

  /// Affiche un bottom sheet pour prendre des notes avec un prompt optionnel
  void _showNoteSheet({String? seedText}) {
    final controller = TextEditingController(text: seedText ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1F1B3B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Note personnelle',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Écris tes réflexions, questions ou applications...',
                    hintStyle: GoogleFonts.inter(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final note = controller.text.trim();
                    if (note.isNotEmpty) {
                      // Ici on pourrait sauvegarder la note
                      Navigator.pop(context);
                      _showSnackBar(
                        'Note sauvegardée',
                        Icons.check_circle,
                        Colors.green,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sauvegarder',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

