import 'dart:async';
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
import '../services/user_prefs_hive.dart';
import '../services/user_prefs_sync.dart';
import '../services/version_change_notifier.dart';
import '../bootstrap.dart' as bootstrap;
import 'advanced_bible_study_page.dart';
import '../services/spiritual_foundations_service.dart';
import '../models/spiritual_foundation.dart';
import '../services/themes_service.dart';
import '../services/bible_context_service.dart';
import '../services/bible_comparison_service.dart';
import '../services/thomson_service.dart';
import 'bible_comparison_page.dart';

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
  SpiritualFoundation? _foundationOfDay;
  late AnimationController _buttonAnimationController;
  String _notedVerse = ''; // Verset noté par l'utilisateur
  
  
  // Passage data
  String _passageText = '';
  String _dayTitle = 'Jour 15'; // Valeur par défaut
  bool _isLoadingText = true;
  bool _isOfflineMode = false;
  
  // Multi-passage support
  ReadingSession? _readingSession;
  
  // Version selection
  String _selectedVersion = 'lsg1910'; // ✅ Version VideoPsalm par défaut
  List<Map<String, String>> _availableVersions = [];
  StreamSubscription<String>? _versionChangeSubscription;

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
    
    // Charger la fondation du jour
    _loadFoundationOfDay();
    
    // Écouter les changements de version
    _versionChangeSubscription = VersionChangeNotifier.versionStream.listen((newVersion) {
      print('📢 ReaderPage: Changement de version détecté: $newVersion');
      _changeVersion(newVersion);
    });
  }

  bool _hasInitialized = false;

  /// Charge la fondation du jour
  Future<void> _loadFoundationOfDay() async {
    try {
      final userPrefs = context.read<UserPrefsHive>();
      final profile = userPrefs.profile;
      
      // Calculer le jour actuel du plan
      int dayNumber = 1;
      if (widget.planId != null && widget.dayNumber != null) {
        dayNumber = widget.dayNumber!;
      }
      
      final foundation = await SpiritualFoundationsService.getFoundationOfDay(
        null, // Pas de plan spécifique pour le moment
        dayNumber,
        profile,
      );
      
      if (mounted) {
        setState(() {
          _foundationOfDay = foundation;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement fondation du jour: $e');
    }
  }

  String? _lastAppliedVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadUserBibleVersion();
        if (_selectedVersion != _lastAppliedVersion) {
          _lastAppliedVersion = _selectedVersion;
          await _reloadCurrentPassage();
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
      // Synchroniser d'abord les deux systèmes
      await UserPrefsSync.syncBidirectional();
      
      // Essayer UserPrefsHive d'abord (système principal)
      final prefs = context.read<UserPrefsHive?>();
      String? userVersion;
      
      if (prefs != null) {
        final profile = prefs.profile;
        userVersion = profile['bibleVersion'] as String?;
        print('🔍 _loadUserBibleVersion (UserPrefsHive): userVersion="$userVersion"');
      } else {
        // Fallback vers UserPrefs si UserPrefsHive non disponible
        final profile = await UserPrefs.loadProfile();
        userVersion = profile['bibleVersion'] as String?;
        print('🔍 _loadUserBibleVersion (UserPrefs fallback): userVersion="$userVersion"');
      }
      
      if (userVersion != null && userVersion.isNotEmpty) {
        // Vérifier si la version est disponible
        print('🔍 Vérification disponibilité de "$userVersion"...');
        final isAvailable = await _checkVersionAvailability(userVersion);
        print('🔍 Résultat vérification "$userVersion": isAvailable=$isAvailable');
        if (isAvailable) {
          setState(() {
            _selectedVersion = userVersion!;
          });
          print('📖 Version utilisateur chargée: $userVersion');
        } else {
          // Essayer de forcer la réimportation pour francais_courant et semeur
          if (userVersion == 'francais_courant' || userVersion == 'semeur') {
            print('🔄 Tentative de réimportation forcée de $userVersion...');
            try {
              await BibleTextService.forceReimportVersion(userVersion);
              // Vérifier à nouveau après réimportation
              final isAvailableAfterReimport = await _checkVersionAvailability(userVersion);
              if (isAvailableAfterReimport) {
                setState(() {
                  _selectedVersion = userVersion!;
                });
                print('✅ Version $userVersion réimportée avec succès');
              } else {
                setState(() {
                  _selectedVersion = 'lsg1910';
                });
                print('⚠️ Réimportation échouée, fallback vers lsg1910');
              }
            } catch (e) {
              setState(() {
                _selectedVersion = 'lsg1910';
              });
              print('❌ Erreur réimportation $userVersion: $e, fallback vers lsg1910');
            }
          } else {
            // Fallback vers LSG1910 pour les autres versions
            setState(() {
              _selectedVersion = 'lsg1910';
            });
            print('⚠️ Version utilisateur "$userVersion" non disponible, fallback vers lsg1910');
          }
        }

        // si la session est déjà prête, recharge
        if (_readingSession?.passages.isNotEmpty == true) {
          await _loadAllPassages();
        }
      } else {
        setState(() {
          _selectedVersion = 'lsg1910';
        });
        print('⚠️ Aucune version utilisateur trouvée, fallback vers lsg1910');
      }
    } catch (e) {
      print('⚠️ Erreur chargement version utilisateur: $e');
      setState(() {
        _selectedVersion = 'lsg1910';
      });
    }
  }

  /// Vérifie si une version de Bible est disponible
  Future<bool> _checkVersionAvailability(String versionId) async {
    try {
      await BibleTextService.ensureVersionAvailable(versionId);
      // Vérifier spécifiquement cette version
      return await BibleTextService.hasVerses(versionId);
    } catch (e) {
      print('⚠️ Version "$versionId" non disponible: $e');
      return false;
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
      setState(() => _isLoadingText = true);

      // Démarrer un timer pour détecter les chargements longs
      Timer? offlineTimer;
      offlineTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isLoadingText) {
          setState(() => _isOfflineMode = true);
        }
      });

      final updated = <int, ReadingPassage>{};
      final tasks = _readingSession!.passages.asMap().entries.map((entry) async {
        final index = entry.key;
        final passage = entry.value;

        try {
          await BibleTextService.ensureVersionAvailable(_selectedVersion);
          final text = await BibleTextService.getPassageText(passage.reference, version: _selectedVersion);
          final resolved = text ?? await _getFallbackText(passage.reference);
          updated[index] = passage.copyWith(text: resolved, isLoaded: true, isLoading: false, error: text == null ? 'Texte non trouvé' : null);
        } catch (e) {
          final resolved = await _getFallbackText(passage.reference);
          updated[index] = passage.copyWith(text: resolved, isLoaded: true, isLoading: false, error: e.toString());
        }
      }).toList();

      await Future.wait(tasks);
      offlineTimer.cancel();

      if (!mounted) return;
      setState(() {
        var rs = _readingSession!;
        updated.forEach((i, p) => rs = rs.updatePassage(i, p));
        _readingSession = rs;
        _isLoadingText = false;
      });
      await _updateCurrentPassageText();
    } catch (e) {
      print('⚠️ Erreur chargement passages multiples: $e');
      if (!mounted) return;
      setState(() => _isLoadingText = false);
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
    // Essayer d'abord avec LSG1910 qui fonctionne toujours
    try {
      final text = await BibleTextService.getPassageText(reference ?? 'Jean 14:1-19', version: 'lsg1910');
      if (text != null && text.trim().isNotEmpty) {
        print('🔍 _getFallbackText: Texte récupéré depuis LSG1910 (${text.length} caractères)');
        return text;
      }
    } catch (e) {
      print('⚠️ _getFallbackText: Erreur récupération LSG1910: $e');
    }
    
    // Essayer avec la version sélectionnée
    try {
      final text = await BibleTextService.getPassageText(reference ?? 'Jean 14:1-19', version: _selectedVersion);
      if (text != null && text.trim().isNotEmpty) {
        print('🔍 _getFallbackText: Texte récupéré depuis $_selectedVersion (${text.length} caractères)');
        return text;
      }
    } catch (e) {
      print('⚠️ _getFallbackText: Erreur récupération $_selectedVersion: $e');
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
    _versionChangeSubscription?.cancel();
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
      // Afficher les prompts de réflexion au lieu du bottom sheet
      _showReflectionPrompts();
    }
  }

  /// Affiche les prompts de réflexion dans un bottom sheet
  void _showReflectionPrompts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          
          return Container(
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF1F1B3B) 
                : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Réflexion sur le passage',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez un prompt pour approfondir votre méditation',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: isDark 
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                     // ReaderPromptsBar contextuel
                     ReaderPromptsBar(
                       isDark: isDark,
                       passageRef: _readingSession?.currentPassage?.reference ?? '',
                       foundation: _foundationOfDay,
                       userLevel: 'intermédiaire', // TODO: Récupérer depuis le profil utilisateur
                       onTapPrompt: (prompt) {
                         Navigator.pop(context);
                         _showNoteSheet(seedText: prompt);
                       },
                     ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
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
                    const SizedBox(width: 8),
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
              
              // Les prompts de réflexion sont maintenant dans le bottom sheet
              
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        if (_isOfflineMode) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Mode hors ligne – chargement de secours',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: _passageText));
                    _showSnackBar('Verset copié !', Icons.copy, Colors.blue);
                    HapticFeedback.mediumImpact();
                  },
                  child: HighlightableText(
                    text: _passageText,
                    style: settings.getFontStyle().copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    textAlign: settings.getTextAlign(),
                  ),
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
                          _isMarkedAsRead ? 'Marqué comme lu' : 'Marquer comme lu',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Aperçus intelligents enrichis
              _buildSmartInsights(isDark),
              
              const SizedBox(height: 12),
              
              // Actions d'étude
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStudyAction(
                      Icons.info_outline,
                      'Contexte',
                      'Contexte historique et culturel',
                      Colors.blue,
                      () => _goToAdvancedStudyTab(0),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.label_outline,
                      'Thèmes',
                      'Thèmes bibliques et doctrines',
                      Colors.purple,
                      () => _showThemesBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.person_outline,
                      'Personnages',
                      'Personnages bibliques',
                      Colors.green,
                      () => _showCharactersBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.menu_book_outlined,
                      'Encyclopédie',
                      'Encyclopédie biblique',
                      Colors.orange,
                      () => _goToAdvancedStudyTab(2),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.search_outlined,
                      'Concordance',
                      'Références croisées BSB',
                      Colors.teal,
                      () => _showConcordanceBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.translate_outlined,
                      'Lexique',
                      'Mots grecs et hébreux',
                      Colors.indigo,
                      () => _goToAdvancedStudyTab(3),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.library_books_outlined,
                      'Index BSB',
                      'Index thématique BSB',
                      Colors.deepOrange,
                      () => _showTopicalIndexBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.compare_arrows_outlined,
                      'Versions',
                      'Comparer 14 versions',
                      Colors.cyan,
                      () => _showBibleComparison(),
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construit les aperçus intelligents simplifiés (optimisé)
  Widget _buildSmartInsights(bool isDark) {
    // Version simplifiée sans FutureBuilder lourd
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark 
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade50,
            isDark 
                ? Colors.white.withOpacity(0.03)
                : Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.15)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Aperçus intelligents',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Aperçu simplifié
          _buildSmartInsightItem(
            'Étude approfondie',
            'Explorez ce passage avec nos outils d\'analyse',
            Colors.purple,
            Icons.auto_awesome,
            isDark,
          ),
        ],
      ),
    );
  }
  
  /// Construit un élément d'aperçu intelligent
  Widget _buildSmartInsightItem(String label, String content, Color color, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: color,
            size: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  
  /// Extrait le nom du livre d'une référence biblique
  String _extractBookFromReference(String reference) {
    final parts = reference.split(' ');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return '';
  }

  Widget _buildStudyAction(IconData icon, String title, String subtitle, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône et titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Description
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 8,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Indicateur d'action
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  'Explorer',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    final verseId = _extractVerseIdFromReference(_readingSession?.currentPassage?.reference ?? 'Jean 14:1-19');
    final ref = _readingSession?.currentPassage?.reference;
    context.push('/advanced_bible_study', extra: {
      'verseId': verseId,
      'initialTab': tabIndex,
      'passageRef': ref, // pour TopicService/ConcordanceService
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
        
        // Ne change pas la version si déjà fixée et présente
        final hasCurrent = _availableVersions.any((v) => v['id'] == _selectedVersion);
        if (!hasCurrent) {
          // Si l'utilisateur a une préférence mais pas encore dispo, on garde _selectedVersion
          // sinon fallback sur la première dispo
          if (_availableVersions.isNotEmpty) {
            _selectedVersion = _availableVersions.first['id']!;
          }
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
      onTap: () async {
        final id = version['id']!;
        await context.read<UserPrefsHive>().patchProfile({'bibleVersion': id}); // ← persist
        await _changeVersion(id);
        if (mounted) Navigator.of(context).pop();
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

  /// Affiche les thèmes du passage dans un bottom sheet
  void _showThemesBottomSheet() {
    final verseId = _extractVerseIdFromReference(_readingSession?.currentPassage?.reference ?? 'Jean 14:1-19');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          
          return Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1F1B3B) 
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      color: Colors.purple,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thèmes bibliques',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Thèmes identifiés dans ce passage',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: isDark 
                        ? Colors.white.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Liste des thèmes
                FutureBuilder<List<String>>(
                  future: ThomsonService.getThemes(verseId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final themes = snapshot.data ?? [];
                    
                    if (themes.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun thème identifié',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: themes.map((theme) => _buildThemeItem(theme, isDark)).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Affiche les personnages du passage dans un bottom sheet
  void _showCharactersBottomSheet() {
    final verseId = _extractVerseIdFromReference(_readingSession?.currentPassage?.reference ?? 'Jean 14:1-19');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          
          return Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1F1B3B) 
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personnages bibliques',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Personnages mentionnés dans ce passage',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: isDark 
                        ? Colors.white.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Liste des personnages
                FutureBuilder<List<String>>(
                  future: ThomsonService.getCharacters(verseId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final characters = snapshot.data ?? [];
                    
                    if (characters.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun personnage identifié',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: characters.map((character) => _buildCharacterItem(character, isDark)).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Construit un élément de thème
  Widget _buildThemeItem(String theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.label,
            color: Colors.purple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              theme,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construit un élément de personnage
  Widget _buildCharacterItem(String character, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              character,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Affiche la concordance BSB dans un bottom sheet
  void _showConcordanceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1F1B3B) 
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_outlined,
                        color: Colors.teal,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Concordance BSB',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un mot...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) {
                      // TODO: Implémenter la recherche en temps réel
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Results area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          'Recherchez un mot pour voir ses références bibliques',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            color: isDark 
                                ? Colors.white.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Icon(
                          Icons.search_off,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune recherche effectuée',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Affiche l'index thématique BSB dans un bottom sheet
  void _showTopicalIndexBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1F1B3B) 
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        color: Colors.deepOrange,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Index Thématique BSB',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un thème...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.deepOrange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepOrange.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepOrange.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepOrange,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) {
                      // TODO: Implémenter la recherche en temps réel
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Results area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          'Recherchez un thème pour voir ses références bibliques',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            color: isDark 
                                ? Colors.white.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Icon(
                          Icons.library_books_outlined,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune recherche effectuée',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

  /// Affiche la page de comparaison de versions
  void _showBibleComparison() {
    final currentReference = _readingSession?.currentPassage?.reference;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleComparisonPage(
          initialReference: currentReference,
        ),
      ),
    );
  }


}

