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
import '../services/spiritual_foundations_service.dart';
import '../models/spiritual_foundation.dart';
import '../services/bible_context_service.dart';
import '../services/thomson_service.dart';
import '../services/semantic_passage_boundary_service_v2.dart';
import '../services/biblical_timeline_service.dart';
import '../services/thomson_characters_service.dart';
import '../services/bsb_topical_service.dart';
import '../services/mirror_verse_service.dart';
import '../services/daily_display_service.dart';
import '../services/treasury_crossref_service.dart';
import '../services/bsb_book_outlines_service.dart';
// Services supprimés (packs incomplets)
import '../services/foundations_progress_service.dart';
import '../services/reading_memory_service.dart';
import '../services/meditation_journal_service.dart';
import '../services/intelligent_quiz_service.dart';
import '../models/meditation_journal_entry.dart';
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
  bool _isFavorite = false;
  bool _isBookmarked = false;
  bool _hasNote = false;
  bool _isMarkedAsRead = false;
  bool _hasMarkedAsReadToday = false;
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
    
    // Vérifier si déjà marqué comme lu aujourd'hui
    _hasMarkedAsReadToday = DailyDisplayService.hasMarkedAsReadToday();
    
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

  /// Retourne un padding adaptatif basé sur la largeur de l'écran
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.all(12); // Petits écrans
    } else if (width < 600) {
      return const EdgeInsets.all(16); // Écrans moyens
    } else {
      return const EdgeInsets.all(20); // Grands écrans/tablettes
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Sauvegarder la version actuelle AVANT de recharger
        final previousVersion = _selectedVersion;
        
        await _loadUserBibleVersion();
        
        // Ne recharger que si la version a VRAIMENT changé
        if (_selectedVersion != previousVersion && _selectedVersion != _lastAppliedVersion) {
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
          
          // 🧠 UTILISER LE SERVICE SÉMANTIQUE pour ajuster le passage
          final adjustedPassage = await _adjustPassageWithSemanticService(passage.reference);
          
          print('📖 Récupération du texte pour: $adjustedPassage');
          final text = await BibleTextService.getPassageText(adjustedPassage, version: _selectedVersion);
          print('📖 Texte récupéré: ${text?.length ?? 0} caractères');
          final resolved = text ?? await _getFallbackText(adjustedPassage);
          
          // 🔄 Mettre à jour la référence du passage avec la version ajustée
          updated[index] = passage.copyWith(
            reference: adjustedPassage, // ← Utiliser la référence ajustée
            text: resolved, 
            isLoaded: true, 
            isLoading: false, 
            error: text == null ? 'Texte non trouvé' : null
          );
      
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
      
      // 🧠 UTILISER LE SERVICE SÉMANTIQUE pour ajuster le passage
      final adjustedPassage = await _adjustPassageWithSemanticService(passage.reference);
      
      // ✅ Utiliser le passage ajusté avec le service sémantique
      final text = await BibleTextService.getPassageText(
        adjustedPassage, 
        version: _selectedVersion,
      );

      // Résoudre le fallback AVANT setState
      final resolvedText = text ?? await _getFallbackText(adjustedPassage);

      if (!mounted || _readingSession == null) return;
        setState(() {
        _readingSession = _readingSession!.updatePassage(
            index,
            passage.copyWith(
            reference: adjustedPassage, // ← Utiliser la référence ajustée
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
      
      // 🧠 UTILISER LE SERVICE SÉMANTIQUE pour ajuster le passage
      final adjustedRef = await _adjustPassageWithSemanticService(currentRef);
      
      // Récupérer le texte
      final text = await BibleTextService.getPassageText(
        adjustedRef,
        version: _selectedVersion,
      );

      if (text != null && text.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _passageText = text;
          _isLoadingText = false;
          // 🔄 Mettre à jour la référence dans la session avec la version ajustée
          if (adjustedRef != currentRef) {
            final currentIndex = _readingSession!.currentPassageIndex;
            final currentPassage = _readingSession!.currentPassage;
            if (currentPassage != null) {
              _readingSession = _readingSession!.updatePassage(
                currentIndex,
                currentPassage.copyWith(reference: adjustedRef),
              );
            }
          }
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
        
        // 🧠 UTILISER LE SERVICE SÉMANTIQUE pour ajuster le passage
        final adjustedReference = await _adjustPassageWithSemanticService(currentReference);
        
        final text = await BibleTextService.getPassageText(
          adjustedReference,
          version: _selectedVersion,
        );

        if (text != null && text.trim().isNotEmpty) {
          if (!mounted) return;
        setState(() {
            _passageText = text;
          _isLoadingText = false;
            // 🔄 Mettre à jour la référence dans la session avec la version ajustée
            if (_readingSession != null && adjustedReference != currentReference) {
              final currentIndex = _readingSession!.currentPassageIndex;
              final currentPassage = _readingSession!.currentPassage;
              if (currentPassage != null) {
                _readingSession = _readingSession!.updatePassage(
                  currentIndex,
                  currentPassage.copyWith(reference: adjustedReference),
                );
              }
            }
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

  /// Ajuste un passage avec le service sémantique pour respecter les unités littéraires
  Future<String> _adjustPassageWithSemanticService(String reference) async {
    try {
      print('🧠 Ajustement sémantique du passage: $reference');
      
      // Parser la référence (ex: "Colossiens 2:1-18")
      final parts = reference.split(' ');
      if (parts.length < 2) return reference;
      
      final book = parts[0];
      final chapterVerse = parts[1];
      final cvParts = chapterVerse.split(':');
      
      if (cvParts.length < 2) return reference;
      
      final chapter = int.tryParse(cvParts[0]) ?? 1;
      final verseRange = cvParts[1];
      final verseParts = verseRange.split('-');
      final startVerse = int.tryParse(verseParts[0]) ?? 1;
      final endVerse = verseParts.length > 1 ? int.tryParse(verseParts[1]) ?? startVerse : startVerse;
      
      // Utiliser le service sémantique pour ajuster le passage
      final adjusted = await SemanticPassageBoundaryService.adjustPassageVerses(
        book: book,
        startChapter: chapter,
        startVerse: startVerse,
        endChapter: chapter,
        endVerse: endVerse,
      );
      
      // Construire la nouvelle référence
      final newReference = '${adjusted.book} ${adjusted.startChapter}:${adjusted.startVerse}-${adjusted.endVerse}';
      
      print('🧠 Service sémantique:');
      print('   - Passage original: $reference');
      print('   - Passage ajusté: $newReference');
      print('   - Ajusté: ${adjusted.adjusted}');
      print('   - Raison: ${adjusted.reason}');
      print('   - Unité incluse: ${adjusted.includedUnit?.name ?? "Aucune"}');
      
      return newReference;
    } catch (e) {
      print('⚠️ Erreur ajustement sémantique: $e');
      return reference; // Retourner la référence originale en cas d'erreur
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
    // Si déjà marqué comme lu aujourd'hui, ne rien faire
    if (_hasMarkedAsReadToday) {
      _showSnackBar(
        'Passage déjà marqué comme lu aujourd\'hui',
        Icons.info,
        Colors.orange,
      );
      return;
    }
    
    setState(() {
      _isMarkedAsRead = true;
      _hasMarkedAsReadToday = true;
    });
    HapticFeedback.mediumImpact();
    
    // Marquer comme lu aujourd'hui dans le service
    await DailyDisplayService.markPassageAsReadToday();
    
    // ✅ Marquer côté PlanService si contexte connu
    final planId = widget.planId;
    final day = widget.dayNumber;
    if (planId != null && day != null) {
      try {
        await bootstrap.planService.markDayCompleted(planId, day, true);
        
        // 🧠 ACTIVATION DE TOUS LES SERVICES D'ANALYSE ET DE PROGRESSION
        await _activateAllAnalysisServices();
        
        _showSnackBar(
          'Jour marqué comme lu',
          Icons.check_circle,
          Colors.green,
        );
      } catch (e) {
        // rollback UI si erreur critique
        setState(() {
          _isMarkedAsRead = false;
          _hasMarkedAsReadToday = false;
        });
        _showSnackBar('Impossible de mettre à jour l\'état du jour', Icons.error_outline, Colors.red);
        print('❌ markDayCompleted: $e');
      }
    } else {
      // Pas de contexte de plan (lecture libre)
      await _activateAllAnalysisServices();
      
      _showSnackBar(
        'Lu (mode libre)',
        Icons.check_circle,
        Colors.green,
      );
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
        backgroundColor: const Color(0xFF49C98D),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Ajouté aux signets' : 'Retiré des signets'),
        backgroundColor: const Color(0xFF2B1E75),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleNote() {
    setState(() {
      _hasNote = !_hasNote;
    });
    
    HapticFeedback.lightImpact();
    
    if (_hasNote) {
      // _showModernNoteDialog(); // Méthode supprimée
    }
  }

  /// 🧠 Active tous les services d'analyse, de progression et de quiz
  Future<void> _activateAllAnalysisServices() async {
    try {
      final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
      final verseId = _extractVerseIdFromReference(reference);
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      print('🧠 Activation des services d\'analyse pour: $reference');
      
      // 1. 🧠 FOUNDATIONS PROGRESS SERVICE - Enregistrer la pratique
      try {
        await FoundationsProgressService.markAsPracticed(
          'daily_reading_${widget.planId ?? 'free'}',
          note: 'Lecture: $reference',
        );
        print('✅ FoundationsProgressService activé');
      } catch (e) {
        print('⚠️ Erreur FoundationsProgressService: $e');
      }
      
      // 2. 🧠 READING MEMORY SERVICE - Analyser la lecture
      try {
        await ReadingMemoryService.init();
        await ReadingMemoryService.saveRetention(
          id: verseId,
          retained: 'Lecture complétée: $reference',
          date: DateTime.now(),
        );
        print('✅ ReadingMemoryService activé');
      } catch (e) {
        print('⚠️ Erreur ReadingMemoryService: $e');
      }
      
      // 3. 🧠 MEDITATION JOURNAL SERVICE - Préparer l'analyse émotionnelle
      try {
        await MeditationJournalService.init();
        // Créer une entrée de base pour l'analyse
        final entry = MeditationJournalEntry(
          id: 'reading_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          passageRef: reference,
          passageText: _readingSession?.currentPassage?.text ?? '',
          memoryVerse: '',
          memoryVerseRef: '',
          prayerSubjects: [],
          prayerNotes: [],
          gradientIndex: 0,
          meditationType: 'free',
          meditationData: {'note': 'Lecture marquée comme terminée'},
        );
        await MeditationJournalService.saveEntry(entry);
        print('✅ MeditationJournalService activé');
      } catch (e) {
        print('⚠️ Erreur MeditationJournalService: $e');
      }
      
      // 4. 🧠 INTELLIGENT QUIZ SERVICE - Préparer les quiz
      try {
        await IntelligentQuizService.init();
        // Le service sera activé automatiquement lors de la génération de quiz
        print('✅ IntelligentQuizService activé');
      } catch (e) {
        print('⚠️ Erreur IntelligentQuizService: $e');
      }
      
      // 5. 🧠 SPIRITUAL FOUNDATIONS SERVICE - Mettre à jour les fondations
      try {
        await SpiritualFoundationsService.reload();
        // Le service sera activé automatiquement lors de l'utilisation des fondations
        print('✅ SpiritualFoundationsService activé');
      } catch (e) {
        print('⚠️ Erreur SpiritualFoundationsService: $e');
      }
      
      // 6. 🧠 JOURNAL SERVICE - Enregistrer l'activité
      try {
        await JournalService.saveJournalEntry(
          date: today,
          bullets: ['Lecture terminée', 'Passage $reference marqué comme lu'],
          passageRef: reference,
          notes: 'Lecture complétée avec succès',
        );
        print('✅ JournalService activé');
      } catch (e) {
        print('⚠️ Erreur JournalService: $e');
      }
      
      // 7. 🧠 INTENTIONS SERVICE - Mettre à jour les intentions
      try {
        await IntentionsService.saveTodayIntention('Lecture: $reference');
        print('✅ IntentionsService activé');
      } catch (e) {
        print('⚠️ Erreur IntentionsService: $e');
      }
      
      print('🎉 Tous les services d\'analyse ont été activés avec succès!');
      
    } catch (e) {
      print('❌ Erreur lors de l\'activation des services: $e');
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
                  'Répondez à l\'une ou plusieurs de ces questions pour approfondir votre méditation',
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
    // Le bouton méditation est accessible si le passage a été marqué comme lu aujourd'hui
    // OU s'il a été marqué comme lu avant (état persistant)
    if (!_isMarkedAsRead && !_hasMarkedAsReadToday) {
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
                icon: Icons.edit_note,
                title: 'Méditation guidée',
                subtitle: 'Réflexion structurée avec questions',
                onTap: () {
                  Navigator.pop(context);
    context.go('/meditation/bible-warning', extra: {
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
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          final responsivePadding = _getResponsivePadding(context);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: responsivePadding.left,
                    right: responsivePadding.right,
                    top: responsivePadding.top,
                    bottom: MediaQuery.of(context).viewInsets.bottom + responsivePadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Recopiez simplement le texte qui vous a touché. Il sera utilisé pour créer votre poster.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
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
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Écrivez le verset qui vous a marqué...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                            filled: true,
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
                                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                                foregroundColor: isDark ? Colors.white : Colors.black87,
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
        },
      ),
    );
  }

  /// Affiche le bottom sheet de contexte enrichi
  void _showEnrichedContextBottomSheet() {
    final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    final verseId = _extractVerseIdFromReference(reference);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  'Contexte - $reference',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Contenu enrichi
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _loadEnrichedContextData(reference, verseId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur de chargement: ${snapshot.error}',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        );
                      }
                      
                      final data = snapshot.data ?? {};
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Période historique
                            if (data['period'] != null) ...[
                              _buildContextSection(
                                '📅 Période historique',
                                data['period']['name'] ?? 'Inconnue',
                                data['period']['description'] ?? '',
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Empire dominant
                            if (data['empire'] != null) ...[
                              _buildContextSection(
                                '🏛️ Empire dominant',
                                data['empire']['name'] ?? 'Aucun',
                                data['empire']['description'] ?? '',
                                Colors.orange,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Contexte littéraire
                            if (data['literaryContext'] != null) ...[
                              _buildContextSection(
                                '📖 Contexte littéraire',
                                data['literaryContext']['name'] ?? 'Inconnu',
                                data['literaryContext']['description'] ?? '',
                                Colors.purple,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Contexte historique Thomson
                            if (data['historicalContext'] != null) ...[
                              _buildContextSection(
                                '🌍 Contexte historique',
                                'Contexte Thomson',
                                data['historicalContext'],
                                Colors.green,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Contexte culturel
                            if (data['culturalContext'] != null) ...[
                              _buildContextSection(
                                '📚 Contexte culturel',
                                'Contexte culturel',
                                data['culturalContext'],
                                Colors.teal,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Message si aucune donnée
                            if (data.isEmpty) ...[
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun contexte disponible pour ce passage',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Charge les données de contexte enrichi
  Future<Map<String, dynamic>> _loadEnrichedContextData(String reference, String verseId) async {
    final data = <String, dynamic>{};
    
    try {
      // Initialiser les services
      await Future.wait([
        BiblicalTimelineService.init(),
        ThomsonService.init(),
        BibleContextService.init(),
        SemanticPassageBoundaryService.init(),
      ]);
      
      // 1. Période historique via BiblicalTimelineService
      final bookName = _extractBookFromReference(reference);
      if (bookName.isNotEmpty) {
        final period = await BiblicalTimelineService.getPeriodForBook(bookName);
        if (period != null) {
          data['period'] = period;
          
          // Récupérer l'empire dominant pour cette période
          final startYear = period['startYear'] as int? ?? 0;
          final empire = await BiblicalTimelineService.getEmpireForYear(startYear);
          if (empire != null) {
            data['empire'] = empire;
          }
        }
      }
      
      // 2. Contexte littéraire via SemanticPassageBoundaryService
      if (bookName.isNotEmpty) {
        final units = SemanticPassageBoundaryService.getUnitsForBook(bookName);
        if (units.isNotEmpty) {
          final unit = units.first;
          data['literaryContext'] = {
            'name': unit.name,
            'description': unit.description ?? '',
          };
        }
      }
      
      // 3. Contexte historique via ThomsonService
      final thomsonContext = await ThomsonService.getContext(verseId);
      if (thomsonContext.isNotEmpty) {
        data['historicalContext'] = thomsonContext;
      }
      
      // 4. Contexte culturel via BibleContextService
      final culturalContext = await BibleContextService.cultural(verseId);
      if (culturalContext != null && culturalContext.isNotEmpty) {
        data['culturalContext'] = culturalContext;
      }
      
    } catch (e) {
      print('⚠️ Erreur chargement contexte enrichi: $e');
    }
    
    return data;
  }

  /// Construit une section de contexte
  Widget _buildContextSection(String title, String subtitle, String content, Color color) {
    return Container(
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
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_dayTitle} • ${_readingSession?.currentPassage?.reference ?? 'Jean 14:1-19'}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Icônes essentielles seulement
          Row(
            children: [
              // Icône moderne pour la prise de notes
              GestureDetector(
                onTap: _showReflectionPrompts,
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
                    Icons.edit_note_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.go('/reader_settings', extra: {
                  'passageRef': _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19',
                  'passageText': _passageText,
                  'dayTitle': _dayTitle,
                  'planId': widget.planId,
                  'dayNumber': widget.dayNumber,
                }),
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
                    Icons.settings,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
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
        return Opacity(
          opacity: settings.brightness,
          child: SingleChildScrollView(
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
                      fontSize: settings.fontSize,
                      height: 1.6,
                    ),
                  textAlign: settings.getTextAlign(),
                ),
                ),
              
            ],
          ),
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
              Icons.book,
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
        
        // Déterminer si le bouton est désactivé
        final isDisabled = _hasMarkedAsReadToday;
        
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isDisabled ? null : _markAsRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDisabled 
                        ? Colors.grey.withOpacity(0.3)
                        : (_isMarkedAsRead ? const Color(0xFF49C98D) : const Color(0xFF1553FF)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDisabled ? null : [
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
                          isDisabled 
                              ? 'Déjà lu aujourd\'hui'
                              : (_isMarkedAsRead ? 'Marqué comme lu' : 'Marquer comme lu'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: isDisabled ? Colors.grey.shade600 : Colors.white,
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
                    color: (_isMarkedAsRead || _hasMarkedAsReadToday)
                        ? const Color(0xFF1553FF) 
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                    border: (_isMarkedAsRead || _hasMarkedAsReadToday)
                        ? null 
                        : Border.all(
                            color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                          ),
                    boxShadow: (_isMarkedAsRead || _hasMarkedAsReadToday) ? [
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
                            color: (_isMarkedAsRead || _hasMarkedAsReadToday)
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
              
              // Actions d'étude
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
      child: Row(
        children: [
                    _buildStudyAction(
                      Icons.help_outline,
                      'Contexte',
                      'Contexte historique et culturel',
                      isDark ? const Color(0xFF6B8AFF) : const Color(0xFF5B7FE5),
                      () => _showContextBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.link_outlined,
                      'Références',
                      'Références croisées',
                      isDark ? const Color(0xFF7FE5CC) : const Color(0xFF6BD5BC),
                      () => _showCrossReferencesBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.label_outline,
                      'Thèmes',
                      'Thèmes bibliques et doctrines',
                      isDark ? const Color(0xFFB4A3FF) : const Color(0xFF9B88E5),
                      () => _showThemesBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.person_outline,
                      'Personnages',
                      'Personnages bibliques',
                      isDark ? const Color(0xFF7FD89E) : const Color(0xFF6BC98D),
                      () => _showCharactersBottomSheet(),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildStudyAction(
                      Icons.sync_alt,
                      'Miroir',
                      'Verset miroir typologique',
                      isDark ? const Color(0xFFFFB86C) : const Color(0xFFFF9F5C),
                      () => _showMirrorBottomSheet(),
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

  
  
  /// Extrait le nom du livre d'une référence biblique
  String _extractBookFromReference(String reference) {
    final parts = reference.split(' ');
    if (parts.isEmpty) return '';
    
    // Si le premier élément est un chiffre (livres comme "1 Pierre", "2 Corinthiens")
    if (parts.length >= 2 && RegExp(r'^\d+$').hasMatch(parts[0])) {
      return '${parts[0]} ${parts[1]}';
    }
    
    // Sinon, prendre le premier élément
    return parts[0];
  }

  Widget _buildStudyAction(IconData icon, String title, String subtitle, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D3A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec fond circulaire
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Titre centré
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDark ? Colors.white : const Color(0xFF1C1E26),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Description centrée
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF1C1E26).withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    // Utiliser la référence complète du passage
    final passageRef = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    final verseId = _extractVerseIdFromReference(passageRef);
    
    HapticFeedback.mediumImpact();
    context.push('/advanced_bible_study', extra: {
      'verseId': verseId,
      'passageRef': passageRef, // Référence complète pour l'affichage
    });
  }

  /// Extrait un ID de verset depuis une référence biblique
  String _extractVerseIdFromReference(String reference) {
    try {
      print('🔍 Extraction verseId depuis: "$reference"');
      
      // Nettoyer la référence
      final cleanRef = reference.trim();
      
      // Utiliser une regex pour extraire le livre, chapitre et verset
      // Format attendu: "1 Pierre 3:1-18" ou "Jean 3:16"
      final regex = RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$');
      final match = regex.firstMatch(cleanRef);
      
      if (match == null) {
        print('⚠️ Format de référence non reconnu: $cleanRef');
        return 'Jean.3.16'; // Fallback
      }
      
      final book = match.group(1)!.trim();
      final chapter = match.group(2)!;
      final verse = match.group(3)!;
      
      final result = '$book.$chapter.$verse';
      print('🔍 VerseId extrait: "$result" (livre: $book, chapitre: $chapter, verset: $verse)');
      
      return result;
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
              const Icon(
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
    final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          final responsivePadding = _getResponsivePadding(context);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    // Header (non-scrollable)
                    Padding(
                      padding: responsivePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.label_outline, color: isDark ? const Color(0xFFB4A3FF) : const Color(0xFF9B88E5), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Thèmes bibliques',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1C1E26),
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
                                  color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1E26).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content (scrollable)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
                        children: [
                          FutureBuilder<Map<String, List<String>>>(
                          future: _loadEnrichedThemesData(reference),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            final data = snapshot.data ?? {};
                            final thomsonThemes = data['thomson'] ?? [];
                            final bsbThemes = data['bsb'] ?? [];
                            
                            if (thomsonThemes.isEmpty && bsbThemes.isEmpty) {
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
                              children: [
                                // Tous les thèmes dans une seule liste
                                ...thomsonThemes.map((theme) => _buildThemeItem(theme, isDark, 'thomson')),
                                ...bsbThemes.map((theme) => _buildThemeItem(theme, isDark, 'bsb')),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  /// Affiche les personnages du passage dans un bottom sheet
  void _showCharactersBottomSheet() {
    final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          final responsivePadding = _getResponsivePadding(context);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    // Header (non-scrollable)
                    Padding(
                      padding: responsivePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline, color: isDark ? const Color(0xFF7FD89E) : const Color(0xFF6BC98D), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Personnages bibliques',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1C1E26),
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
                                  color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1E26).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content (scrollable)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
                        children: [
                          FutureBuilder<List<Map<String, dynamic>>>(
                          future: _loadEnrichedCharactersData(reference),
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
                              children: [
                                ...characters.map((character) => _buildEnrichedCharacterItem(character, isDark)),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  

  /// Charge les données de thèmes enrichies
  Future<Map<String, List<String>>> _loadEnrichedThemesData(String reference) async {
    final data = <String, List<String>>{};
    
    try {
      print('🔍 === DÉBUT CHARGEMENT THÈMES POUR: $reference ===');
      
      // Initialiser les services
      await Future.wait([
        ThomsonService.init(),
        BSBTopicalService.init(),
      ]);
      
      // 1. Thèmes Thomson - extraire l'ID du verset depuis la référence
      final verseId = _extractVerseIdFromReference(reference);
      print('🔍 VerseId extrait: $verseId');
      
      final thomsonThemes = await ThomsonService.getThemes(verseId);
      data['thomson'] = thomsonThemes;
      print('🔍 Thomson thèmes pour $reference ($verseId): ${thomsonThemes.length}');
      
      // 2. Thèmes BSB - utiliser la référence complète
      final bsbThemes = await BSBTopicalService.getThemesForPassage(reference);
      data['bsb'] = bsbThemes;
      print('🔍 BSB thèmes pour $reference: ${bsbThemes.length}');
      
      // 3. Essayer avec des références alternatives
      if (thomsonThemes.isEmpty && bsbThemes.isEmpty) {
        print('🔍 Aucun thème trouvé, essai avec des références alternatives...');
        
        // Essayer avec juste le livre
        final bookName = _extractBookFromReference(reference);
        print('🔍 Essai avec le livre: $bookName');
        
        // Essayer avec un verset spécifique
        final singleVerseRef = reference.split('-')[0]; // Prendre juste le premier verset
        print('🔍 Essai avec verset simple: $singleVerseRef');
        
        final singleVerseId = _extractVerseIdFromReference(singleVerseRef);
        final singleVerseThemes = await ThomsonService.getThemes(singleVerseId);
        print('🔍 Thèmes verset simple ($singleVerseId): ${singleVerseThemes.length}');
        
        if (singleVerseThemes.isNotEmpty) {
          data['thomson'] = singleVerseThemes;
        }
      }
      
      print('🔍 === FIN CHARGEMENT THÈMES ===');
      
    } catch (e) {
      print('⚠️ Erreur chargement thèmes enrichis: $e');
    }
    
    return data;
  }

  /// Construit l'en-tête d'une section de thèmes
  Widget _buildThemeSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  /// Traduit un thème anglais en français
  String _translateTheme(String theme) {
    final translations = {
      'Faith': 'Foi',
      'Love': 'Amour',
      'Hope': 'Espérance',
      'Grace': 'Grâce',
      'Salvation': 'Salut',
      'Redemption': 'Rédemption',
      'Forgiveness': 'Pardon',
      'Peace': 'Paix',
      'Joy': 'Joie',
      'Wisdom': 'Sagesse',
      'Truth': 'Vérité',
      'Light': 'Lumière',
      'Life': 'Vie',
      'Death': 'Mort',
      'Sin': 'Péché',
      'Righteousness': 'Justice',
      'Holiness': 'Sainteté',
      'Mercy': 'Miséricorde',
      'Compassion': 'Compassion',
      'Patience': 'Patience',
      'Humility': 'Humilité',
      'Courage': 'Courage',
      'Strength': 'Force',
      'Victory': 'Victoire',
      'Triumph': 'Triomphe',
      'Glory': 'Gloire',
      'Praise': 'Louange',
      'Worship': 'Adoration',
      'Prayer': 'Prière',
      'Obedience': 'Obéissance',
      'Discipleship': 'Discipulat',
      'Service': 'Service',
      'Sacrifice': 'Sacrifice',
      'Cross': 'Croix',
      'Resurrection': 'Résurrection',
      'Eternal': 'Éternel',
      'Heaven': 'Ciel',
      'Hell': 'Enfer',
      'Judgment': 'Jugement',
      'Repentance': 'Repentance',
      'Conversion': 'Conversion',
      'Baptism': 'Baptême',
      'Communion': 'Communion',
      'Church': 'Église',
      'Fellowship': 'Communion fraternelle',
      'Unity': 'Unité',
      'Brotherhood': 'Fraternité',
      'Sisterhood': 'Sororité',
      'Family': 'Famille',
      'Marriage': 'Mariage',
      'Children': 'Enfants',
      'Parents': 'Parents',
      'Elders': 'Anciens',
      'Leaders': 'Dirigeants',
      'Ministry': 'Ministère',
      'Mission': 'Mission',
      'Evangelism': 'Évangélisation',
      'Witness': 'Témoignage',
      'Testimony': 'Témoignage',
      'Gospel': 'Évangile',
      'Kingdom': 'Royaume',
      'Covenant': 'Alliance',
      'Promise': 'Promesse',
      'Blessing': 'Bénédiction',
      'Curse': 'Malédiction',
      'Law': 'Loi',
      'Commandment': 'Commandement',
      'Freedom': 'Liberté',
      'Bondage': 'Esclavage',
      'Slavery': 'Esclavage',
      'Liberty': 'Liberté',
      'Justice': 'Justice',
    };
    
    return translations[theme] ?? theme;
  }

  /// Construit un élément de thème avec type
  Widget _buildThemeItem(String theme, bool isDark, String type) {
    final color = type == 'thomson' ? Colors.purple : Colors.blue;
    final icon = type == 'thomson' ? Icons.label : Icons.bookmark;
    final translatedTheme = _translateTheme(theme);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              translatedTheme,
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
  

  /// Charge les données de personnages enrichies
  Future<List<Map<String, dynamic>>> _loadEnrichedCharactersData(String reference) async {
    final characters = <Map<String, dynamic>>[];
    
    try {
      print('🔍 === DÉBUT CHARGEMENT PERSONNAGES POUR: $reference ===');
      
      // Initialiser les services
      await Future.wait([
        ThomsonService.init(),
        ThomsonCharactersService.init(),
      ]);
      
      // 1. Récupérer les noms des personnages via ThomsonService
      final verseId = _extractVerseIdFromReference(reference);
      print('🔍 VerseId extrait: $verseId');
      
      final characterNames = await ThomsonService.getCharacters(verseId);
      print('🔍 Thomson personnages pour $reference ($verseId): ${characterNames.length}');
      
      // 2. Enrichir avec les descriptions via ThomsonCharactersService
      for (final name in characterNames) {
        final characterData = await ThomsonCharactersService.getCharacterByName(name);
        if (characterData != null) {
          characters.add(characterData);
        } else {
          // Fallback avec descriptions spécifiques pour les groupes
          String description = 'Personnage biblique mentionné dans ce passage';
          String shortDescription = 'Personnage biblique';
          
          if (name.toLowerCase().contains('femmes') || name.toLowerCase().contains('chrétiennes')) {
            description = 'Les femmes chrétiennes mentionnées dans ce passage, qui sont encouragées à vivre selon les principes bibliques de soumission et de témoignage.';
            shortDescription = 'Femmes chrétiennes encouragées à vivre selon les principes bibliques';
          } else if (name.toLowerCase().contains('maris') || name.toLowerCase().contains('non-croyants')) {
            description = 'Les maris non-croyants mentionnés dans ce passage, qui peuvent être gagnés à la foi par le témoignage de leurs épouses.';
            shortDescription = 'Maris non-croyants qui peuvent être gagnés par le témoignage';
          } else if (name.toLowerCase().contains('sara')) {
            description = 'Sara, l\'épouse d\'Abraham, mentionnée comme exemple de soumission et de beauté intérieure dans ce passage.';
            shortDescription = 'Sara, épouse d\'Abraham, exemple de soumission et de beauté';
          }
          
          characters.add({
            'name': name,
            'description': description,
            'shortDescription': shortDescription,
            'keyPassages': [],
            'themes': [],
            'period': 'Période biblique',
            'books': [],
          });
        }
      }
      
      // 3. Si aucun personnage trouvé, essayer avec des références alternatives
      if (characters.isEmpty) {
        print('🔍 Aucun personnage trouvé, essai avec des références alternatives...');
        
        // Essayer avec un verset spécifique
        final singleVerseRef = reference.split('-')[0];
        final singleVerseId = _extractVerseIdFromReference(singleVerseRef);
        final singleVerseCharacters = await ThomsonService.getCharacters(singleVerseId);
        print('🔍 Personnages verset simple ($singleVerseId): ${singleVerseCharacters.length}');
        
        for (final name in singleVerseCharacters) {
          characters.add({
            'name': name,
            'description': 'Personnage biblique mentionné dans ce passage',
            'shortDescription': 'Personnage biblique',
            'keyPassages': [],
            'themes': [],
            'period': 'Période inconnue',
            'books': [],
          });
        }
      }
      
      print('🔍 === FIN CHARGEMENT PERSONNAGES ===');
      
    } catch (e) {
      print('⚠️ Erreur chargement personnages enrichis: $e');
    }
    
    return characters;
  }

  /// Construit un élément de personnage enrichi
  Widget _buildEnrichedCharacterItem(Map<String, dynamic> character, bool isDark) {
    final name = character['name'] as String? ?? 'Inconnu';
    final shortDescription = character['shortDescription'] as String? ?? 'Personnage biblique';
    final keyPassages = character['keyPassages'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
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
          const SizedBox(height: 8),
          Text(
            '→ $shortDescription',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
            maxLines: null, // Permet l'affichage sur plusieurs lignes
            overflow: TextOverflow.visible,
          ),
          if (keyPassages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: keyPassages.take(3).map((passage) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  passage.toString(),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Affiche le bottom sheet des versets miroirs
  void _showMirrorBottomSheet() {
    final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    final verseId = _extractVerseIdFromReference(reference);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          final responsivePadding = _getResponsivePadding(context);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    // Header (non-scrollable)
                    Padding(
                      padding: responsivePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sync_alt, color: isDark ? const Color(0xFFFFB86C) : const Color(0xFFFF9F5C), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Verset miroir typologique',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connexion typologique entre l\'AT et le NT',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content (scrollable)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
                        children: [
                          FutureBuilder<MirrorVerse?>(
                          future: _loadMirrorData(reference, verseId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'Erreur de chargement: ${snapshot.error}',
                                    style: GoogleFonts.inter(color: Colors.red),
                                  ),
                                ),
                              );
                            }
                            
                            final mirror = snapshot.data;
                            
                            if (mirror == null) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 64,
                                      color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun verset miroir trouvé',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ce passage n\'a pas de connexion typologique identifiée dans notre base de données (896 connexions).',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Les versets miroirs sont des passages de l\'Ancien Testament qui préfigurent le Nouveau Testament (typologie biblique).',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: [
                                _buildMirrorItem(mirror),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Charge les données du verset miroir
  Future<MirrorVerse?> _loadMirrorData(String reference, String verseId) async {
    try {
      print('🔍 === DÉBUT CHARGEMENT MIROIR POUR: $reference ===');
      
      // Initialiser le service
      await MirrorVerseService.init();
      
      // Récupérer le verset miroir enrichi
      final mirror = await MirrorVerseService.enrichedMirror(
        verseId,
        getVerseText: (id) async {
          // Convertir l'ID en référence pour récupérer le texte
          final parts = id.split('.');
          if (parts.length >= 3) {
            final book = parts[0];
            final chapter = parts[1];
            final verse = parts[2];
            final ref = '$book $chapter:$verse';
            return await BibleTextService.getPassageText(ref, version: _selectedVersion);
          }
          return null;
        },
      );
      
      print('🔍 Miroir pour $reference ($verseId): ${mirror != null ? "Trouvé" : "Non trouvé"}');
      
      print('🔍 === FIN CHARGEMENT MIROIR ===');
      
      return mirror;
      
    } catch (e) {
      print('⚠️ Erreur chargement miroir: $e');
      return null;
    }
  }

  /// Construit un élément de verset miroir
  Widget _buildMirrorItem(MirrorVerse mirror) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et type de connexion
          Row(
            children: [
              const Icon(
                Icons.sync_alt,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                mirror.connectionTitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              const Spacer(),
              Text(
                mirror.connectionIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Verset original
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verset original',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mirror.originalId,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (mirror.originalText != null && mirror.originalText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    mirror.originalText!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Flèche de connexion
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_downward,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Connexion typologique',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Verset miroir
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verset miroir',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mirror.mirrorId,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (mirror.mirrorText != null && mirror.mirrorText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    mirror.mirrorText!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Explication
          if (mirror.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explication',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mirror.explanation,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Affiche les références croisées dans un bottom sheet
  void _showCrossReferencesBottomSheet() {
    final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          final responsivePadding = _getResponsivePadding(context);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    // Header (non-scrollable)
                    Padding(
                      padding: responsivePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link_outlined, color: isDark ? const Color(0xFF7FE5CC) : const Color(0xFF6BD5BC), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Références croisées',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Passages liés à ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                                  ),
                                ),
                                TextSpan(
                                  text: reference,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content (scrollable)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
                        children: [
                          FutureBuilder<List<Map<String, dynamic>>>(
                          future: _loadCrossReferencesData(reference),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'Erreur de chargement: ${snapshot.error}',
                                    style: GoogleFonts.inter(color: Colors.red),
                                  ),
                                ),
                              );
                            }
                            
                            final references = snapshot.data ?? [];
                            
                            if (references.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: isDark ? Colors.white54 : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucune référence croisée trouvée pour ce passage',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: isDark ? Colors.white70 : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: [
                                ...references.map((ref) => _buildCrossReferenceItem(ref)),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Charge les données des références croisées
  Future<List<Map<String, dynamic>>> _loadCrossReferencesData(String reference) async {
    final references = <Map<String, dynamic>>[];
    
    try {
      print('🔍 === DÉBUT CHARGEMENT RÉFÉRENCES CROISÉES POUR: $reference ===');
      
      // Utiliser TreasuryCrossRefService
      final crossRefs = await TreasuryCrossRefService.getCrossReferences(reference);
      print('🔍 Références croisées trouvées: ${crossRefs.length}');
      
      // Récupérer le texte complet de chaque référence
      for (final crossRef in crossRefs) {
        final refString = crossRef['reference'] as String? ?? '';
        final numericRef = crossRef['numericRef'] as String? ?? '';
        
        // Vérifier que la référence est valide
        if (refString.isEmpty || refString.contains('-')) {
          print('⚠️ Référence invalide ignorée: $refString');
          continue;
        }
        
        // Récupérer le texte du verset via BibleTextService
        String verseText = '';
        try {
          verseText = await BibleTextService.getPassageText(refString) ?? '';
          print('📖 Texte récupéré pour $refString: ${verseText.length} caractères');
        } catch (e) {
          print('⚠️ Erreur récupération texte pour $refString: $e');
        }
        
        references.add({
          'reference': refString,
          'text': verseText,
          'bookNumber': crossRef['bookNumber'] as int? ?? 0,
          'chapter': crossRef['chapter'] as int? ?? 0,
          'verse': crossRef['verse'] as int? ?? 0,
          'relevance': crossRef['relevanceScore'] != null ? (crossRef['relevanceScore'] as int) / 100.0 : 0.0,
        });
      }
      
      print('🔍 === FIN CHARGEMENT RÉFÉRENCES CROISÉES (${references.length} avec textes) ===');
      
    } catch (e) {
      print('⚠️ Erreur chargement références croisées: $e');
    }
    
    return references;
  }

  /// Construit un élément de référence croisée
  Widget _buildCrossReferenceItem(Map<String, dynamic> reference) {
    final ref = reference['reference'] as String? ?? '';
    final text = reference['text'] as String? ?? '';
    final relevance = reference['relevance'] as double? ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Référence
          Row(
            children: [
              const Icon(
                Icons.link,
                color: Colors.teal,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                ref,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal[700],
                ),
              ),
              const Spacer(),
              if (relevance > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(relevance * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Texte
          if (text.isNotEmpty) ...[
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Affiche le contexte enrichi dans un bottom sheet
  void _showContextBottomSheet() {
    final reference = _readingSession?.currentPassage?.reference ?? 'Jean 14:1-19';
    final verseId = _extractVerseIdFromReference(reference);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          final isDark = settings.effectiveTheme == 'dark';
          final theme = Theme.of(context);
          final responsivePadding = _getResponsivePadding(context);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    // Header (non-scrollable)
                    Padding(
                      padding: responsivePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: isDark ? const Color(0xFF6B8AFF) : const Color(0xFF5B7FE5), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Contexte',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contexte historique, culturel, auteur, sémantique',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content (scrollable)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
                        children: [
                          FutureBuilder<Map<String, dynamic>>(
                            future: _loadContextData(reference, verseId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(
                                      'Erreur de chargement: ${snapshot.error}',
                                      style: GoogleFonts.inter(color: Colors.red),
                                    ),
                                  ),
                                );
                              }
                              
                              final contextData = snapshot.data ?? {};
                              
                              if (contextData.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 48,
                                        color: isDark ? Colors.white54 : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun contexte disponible pour ce passage',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: isDark ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return Column(
                                children: [
                                  // Contexte historique
                                  if (contextData['historical'] != null)
                                    _buildContextCard(
                                      'Contexte Historique',
                                      Icons.history,
                                      contextData['historical'],
                                      Colors.blue,
                                      isDark,
                                    ),
                                  
                                  // Contexte culturel
                                  if (contextData['cultural'] != null)
                                    _buildContextCard(
                                      'Contexte Culturel',
                                      Icons.public,
                                      contextData['cultural'],
                                      Colors.green,
                                      isDark,
                                    ),
                                  
                                  // Période historique
                                  if (contextData['period'] != null)
                                    _buildPeriodCard(contextData['period'], isDark),
                                  
                                  // Contexte littéraire
                                  if (contextData['literary'] != null)
                                    _buildLiteraryContextCard(contextData['literary'], isDark),
                                  
                                  // Plan du livre
                                  if (contextData['bookOutline'] != null)
                                    _buildBookOutlineCard(contextData['bookOutline'], isDark),
                                  
                                  const SizedBox(height: 20),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Charge les données de contexte enrichi
  Future<Map<String, dynamic>> _loadContextData(String reference, String verseId) async {
    final contextData = <String, dynamic>{};
    
    try {
      print('🔍 === DÉBUT CHARGEMENT CONTEXTE POUR: $reference ===');
      
      // Initialiser tous les services
      await Future.wait([
        BibleContextService.init(),
        ThomsonService.init(),
        BiblicalTimelineService.init(),
        SemanticPassageBoundaryService.init(),
        BSBBookOutlinesService.init(),
      ]);
      
      // 1. Charger le contexte historique via ThomsonService
      final thomsonContext = await ThomsonService.getContext(verseId);
      if (thomsonContext.isNotEmpty) {
        contextData['historical'] = thomsonContext;
      }
      
      // 2. Charger le contexte culturel via BibleContextService
      final culturalContext = await BibleContextService.cultural(verseId);
      if (culturalContext != null && culturalContext.isNotEmpty) {
        contextData['cultural'] = culturalContext;
      }
      
      // 3. Charger la période historique via BiblicalTimelineService
      final bookName = _extractBookFromReference(reference);
      print('🔍 Nom du livre extrait: "$bookName"');
      if (bookName.isNotEmpty) {
        print('🔍 Recherche période pour: $bookName');
        final period = await BiblicalTimelineService.getPeriodForBook(bookName);
        print('🔍 Période trouvée: ${period != null ? "OUI" : "NON"}');
        if (period != null) {
          contextData['period'] = period;
          print('🔍 Période ajoutée: ${period.keys.join(', ')}');
        }
      }
      
      // 4. Charger le contexte littéraire via SemanticPassageBoundaryService
      if (bookName.isNotEmpty) {
        print('🔍 Recherche unités littéraires pour: $bookName');
        final units = SemanticPassageBoundaryService.getUnitsForBook(bookName);
        print('🔍 Unités trouvées: ${units.length}');
        if (units.isNotEmpty) {
          contextData['literary'] = {
            'name': units.first.name,
            'description': units.first.description ?? '',
          };
          print('🔍 Contexte littéraire ajouté: ${units.first.name}');
        }
      }
      
      // 5. Charger le plan du livre via BSBBookOutlinesService
      if (bookName.isNotEmpty) {
        print('🔍 Recherche plan du livre pour: $bookName');
        final bookOutline = await BSBBookOutlinesService.getBookOutline(bookName);
        print('🔍 Plan trouvé: ${bookOutline != null ? "OUI" : "NON"}');
        if (bookOutline != null) {
          contextData['bookOutline'] = bookOutline;
          print('🔍 Plan du livre ajouté: ${bookOutline.keys.join(', ')}');
        }
      }
      
      print('🔍 Contexte chargé: ${contextData.keys.join(', ')}');
      print('🔍 === FIN CHARGEMENT CONTEXTE ===');
      
    } catch (e) {
      print('⚠️ Erreur chargement contexte: $e');
    }
    
    return contextData;
  }

  /// Construit une carte de contexte
  Widget _buildContextCard(String title, IconData icon, String content, Color color, bool isDark) {
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
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de période historique
  Widget _buildPeriodCard(Map<String, dynamic> period, bool isDark) {
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
                  color: isDark ? Colors.white : Colors.black87,
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
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (period['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              period['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit une carte de contexte littéraire
  Widget _buildLiteraryContextCard(Map<String, dynamic> literary, bool isDark) {
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
                  color: isDark ? Colors.white : Colors.black87,
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
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (literary['description'] != null && literary['description'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              literary['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit une carte de plan du livre
  Widget _buildBookOutlineCard(Map<String, dynamic> bookOutline, bool isDark) {
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
                  color: isDark ? Colors.white : Colors.black87,
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
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (bookOutline['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              bookOutline['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
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
                  color: Colors.indigo[700],
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
                color: isDark ? Colors.white70 : Colors.black54,
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (sectionData['chapters'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chapitres: ${sectionData['chapters']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.indigo[600],
                        ),
                      ),
                    ],
                    if (sectionData['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sectionData['description'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.3,
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
                      const Icon(
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
                      prefixIcon: const Icon(
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
                        borderSide: const BorderSide(
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
                      const Icon(
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
                      prefixIcon: const Icon(
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
                        borderSide: const BorderSide(
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
                  const Icon(
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

