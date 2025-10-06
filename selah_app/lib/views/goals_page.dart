import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fancy_stack_carousel/fancy_stack_carousel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plan_preset.dart';
import '../services/plan_presets_repo.dart';
import '../services/user_prefs_hive.dart';
import '../services/plan_service.dart';
import 'package:provider/provider.dart';
import '../services/dynamic_preset_generator.dart';
import '../services/thompson_plan_service.dart';
import '../models/thompson_plan_models.dart';
import '../services/hybrid_plan_service.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late Future<List<PlanPreset>> _presetsFuture;
  int _currentSlide = 0;
  late FancyStackCarouselController _carouselController;
  List<FancyStackItem> _carouselItems = [];
  
  // Profil utilisateur
  Map<String, dynamic>? _userProfile;
  bool _showBeginnerTracks = false;
  bool _allowCustomPlan = true; // ⟵ toujours autoriser
  String _userGoal = '';

  @override
  void initState() {
    super.initState();
    _presetsFuture = _fetchPresets();
    _carouselController = FancyStackCarouselController();
    _loadUserProfile();
  }

  Future<List<PlanPreset>> _fetchPresets() async {
    print('🎯 Génération de 5+ presets hybrides Thompson + API...');
    
    try {
      // Générer plusieurs presets hybrides basés sur le profil utilisateur
      if (_userProfile != null) {
        final completeProfile = CompleteProfile.fromUserPrefs(_userProfile!);
        
        // Générer 5 presets avec différents thèmes Thompson
        final List<PlanPreset> presets = [];
        final thompsonThemes = [
          'spiritual_demand',
          'no_worry', 
          'companionhip',
          'prayer_life',
          'forgiveness',
          'faith_trials',
          'common_errors',
          'marriage_duties'
        ];
        
        // Prendre 5 thèmes différents
        final selectedThemes = thompsonThemes.take(5).toList();
        
        for (int i = 0; i < selectedThemes.length; i++) {
          final theme = selectedThemes[i];
          print('🎨 Génération preset ${i + 1}/5: $theme');
          
          try {
            // Créer un profil modifié pour ce thème
            final modifiedProfile = _createProfileForTheme(completeProfile, theme, i);
            
            // Générer le plan hybride
            final hybridResult = await HybridPlanService.generateHybridPlan(modifiedProfile);
            
            if (hybridResult.success && hybridResult.planPreset != null) {
              // Sauvegarder le plan hybride
              await HybridPlanService.saveHybridPlan(hybridResult);
              
              print('✅ Preset ${i + 1} généré: ${hybridResult.planPreset!.name}');
              print('📚 Livres: ${hybridResult.planPreset!.books}');
              
              presets.add(hybridResult.planPreset!);
            } else {
              print('❌ Échec preset ${i + 1}: ${hybridResult.error}');
              // Ajouter un preset de fallback
              presets.add(await _createFallbackPreset(theme, i));
            }
          } catch (e) {
            print('❌ Erreur preset ${i + 1}: $e');
            // Ajouter un preset de fallback
            presets.add(await _createFallbackPreset(theme, i));
          }
        }
        
        print('✅ ${presets.length} presets générés avec succès');
        return presets;
      }
      
      // Fallback: générer des presets dynamiques si pas de profil
      final dynamicPresets = DynamicPresetGenerator.generateDynamicPresets(_userProfile);
      return dynamicPresets;
    } catch (e) {
      print('❌ Erreur génération multiple presets: $e');
      // Fallback vers les presets statiques en cas d'erreur
      final allPresets = await PlanPresetsRepo.loadFromAsset();
      return allPresets;
    }
  }
  
  /// Crée un profil modifié pour un thème spécifique
  CompleteProfile _createProfileForTheme(CompleteProfile baseProfile, String theme, int index) {
    // Modifier les objectifs pour se concentrer sur ce thème
    final themeGoals = {
      'spiritual_demand': ['discipline', 'holiness', 'transformation'],
      'no_worry': ['anxiety', 'peace', 'trust'],
      'companionhip': ['community', 'fellowship', 'relationships'],
      'prayer_life': ['prayer', 'spiritual_life', 'communion'],
      'forgiveness': ['forgiveness', 'healing', 'reconciliation'],
      'faith_trials': ['trials', 'faith', 'perseverance'],
      'common_errors': ['wisdom', 'discernment', 'avoiding_sin'],
      'marriage_duties': ['marriage', 'relationships', 'covenant'],
    };
    
    // Varier la durée selon l'index pour diversifier
    final durations = [21, 30, 40, 45, 60];
    final minutes = [15, 20, 25, 30, 35];
    
    return CompleteProfile(
      language: baseProfile.language,
      minutesPerDay: minutes[index % minutes.length],
      daysPerWeek: baseProfile.daysPerWeek,
      goals: themeGoals[theme] ?? ['discipline'],
      experience: baseProfile.experience,
      prefersThemes: true,
      hasPhysicalBible: baseProfile.hasPhysicalBible,
      startDate: baseProfile.startDate.add(Duration(days: index)), // Décaler les dates
    );
  }
  
  /// Crée un preset de fallback en cas d'échec
  Future<PlanPreset> _createFallbackPreset(String theme, int index) async {
    final themeNames = {
      'spiritual_demand': 'Exigence spirituelle',
      'no_worry': 'Paix du cœur',
      'companionhip': 'Communion fraternelle',
      'prayer_life': 'Vie de prière',
      'forgiveness': 'Pardon & guérison',
      'faith_trials': 'Foi dans l\'épreuve',
      'common_errors': 'Sagesse pratique',
      'marriage_duties': 'Mariage selon Dieu',
    };
    
    final bookConfigs = {
      'spiritual_demand': 'NT',
      'no_worry': 'Gospels,Psalms',
      'companionhip': 'OT,NT',
      'prayer_life': 'Psalms',
      'forgiveness': 'NT',
      'faith_trials': 'OT,NT',
      'common_errors': 'Proverbs,James',
      'marriage_duties': 'Gospels,Psalms,Proverbs',
    };
    
    final specificBooks = {
      'spiritual_demand': 'Matthieu 5-7, Romains 12-14, Éphésiens 4-6',
      'no_worry': 'Matthieu 6, Psaumes 23, 27, 46, 91, 121',
      'companionhip': 'Genèse 2, Proverbes 18, Actes 2, 1 Corinthiens 13',
      'prayer_life': 'Psaumes 1-50, Matthieu 6, Luc 11, Éphésiens 6',
      'forgiveness': 'Matthieu 18, Luc 15, Éphésiens 4, Colossiens 3',
      'faith_trials': 'Jacques 1, Romains 5, 1 Pierre 1, Hébreux 11',
      'common_errors': 'Proverbes 1-10, Jacques 1-5, Galates 5',
      'marriage_duties': 'Genèse 2, Proverbes 31, Éphésiens 5, 1 Corinthiens 7',
    };
    
    final durations = [21, 30, 40, 45, 60];
    final minutes = [15, 20, 25, 30, 35];
    
    return PlanPreset(
      slug: 'fallback_${theme}_$index',
      name: '${themeNames[theme] ?? 'Plan spirituel'} — ${durations[index % durations.length]} jours',
      durationDays: durations[index % durations.length],
      order: 'thematic',
      books: bookConfigs[theme] ?? 'OT,NT',
      coverImage: null,
      minutesPerDay: minutes[index % minutes.length],
      recommended: [PresetLevel.regular],
      description: 'Plan de méditation basé sur le thème "${themeNames[theme]}" de la Bible d\'étude Thompson 21. '
                  'Parcours de ${durations[index % durations.length]} jours à travers ${bookConfigs[theme] ?? 'OT,NT'} '
                  'pour approfondir ce thème spirituel.',
      gradient: _getThompsonGradient([theme]),
      specificBooks: specificBooks[theme] ?? 'Ancien & Nouveau Testament',
    );
  }
  
  /// Fallback vers Thompson seul en cas d'échec de l'API
  Future<List<PlanPreset>> _fallbackToThompson(CompleteProfile profile) async {
    try {
      print('🔄 Fallback vers Thompson seul...');
      final thompsonPreset = await ThompsonPlanService.generateAndSave(profile);
      
      final planPreset = PlanPreset(
        slug: thompsonPreset.id,
        name: thompsonPreset.title,
        durationDays: thompsonPreset.durationDays,
        order: 'thematic',
        books: 'OT,NT',
        coverImage: thompsonPreset.meta['coverImage'] as String?,
        minutesPerDay: thompsonPreset.meta['minutesPerDay'] as int?,
        recommended: [PresetLevel.regular],
        description: thompsonPreset.description,
        gradient: _getThompsonGradient(thompsonPreset.meta['themeKeys'] as List<dynamic>?),
        specificBooks: _getSpecificBooksForTheme(thompsonPreset.meta['themeKeys'] as List<dynamic>?),
      );
      
      print('✅ Fallback Thompson réussi: ${planPreset.name}');
      return [planPreset];
    } catch (e) {
      print('❌ Échec fallback Thompson: $e');
      final dynamicPresets = DynamicPresetGenerator.generateDynamicPresets(_userProfile);
      return dynamicPresets;
    }
  }

  /// Charge le profil utilisateur et applique la logique de personnalisation
  Future<void> _loadUserProfile() async {
    try {
      final profile = context.read<UserPrefsHive>().profile;
      final level = profile['level'] as String? ?? 'Nouveau converti';
      final goal = profile['goal'] as String? ?? 'Discipline quotidienne';
      final allowCustom = profile['allowCustomPlan'] as bool? ?? false;

      setState(() {
        _userProfile = profile;
        _showBeginnerTracks = level == 'Nouveau converti';
        _allowCustomPlan = true; // ⟵ toujours autoriser
        _userGoal = goal;
      });
      
      // Recharger les presets avec la personnalisation
      _presetsFuture = _fetchPresets();
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
      setState(() {
        _showBeginnerTracks = true;
        _allowCustomPlan = true; // ⟵ toujours autoriser
        _userGoal = 'Discipline quotidienne';
      });
    }
  }

  /// Filtre et ordonne les presets selon le profil utilisateur
  List<PlanPreset> _getPersonalizedPresets(List<PlanPreset> allPresets) {
    List<PlanPreset> personalized = [];
    
    if (_showBeginnerTracks) {
      // Pour les nouveaux convertis, proposer des plans de base
      final beginnerPlans = allPresets.where((preset) => 
        preset.slug == 'light_15' || 
        preset.slug == 'genesis_1_25_14d' ||
        preset.slug == 'psalms_40'
      ).toList();
      personalized.addAll(beginnerPlans);
    }
    
    // Ajouter des plans selon l'objectif
    if (_userGoal == 'Discipline de prière') {
      final prayerPlans = allPresets.where((preset) => 
        preset.slug == 'proverbs_31' ||
        preset.slug == 'psalms_40'
      ).toList();
      personalized.addAll(prayerPlans);
    }
    
    // Ajouter les autres plans disponibles
    final remainingPlans = allPresets.where((preset) => 
      !personalized.any((p) => p.slug == preset.slug)
    ).toList();
    personalized.addAll(remainingPlans);
    
    return personalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1025), Color(0xFF1C1740), Color(0xFF2D1B69)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<PlanPreset>>(
        future: _presetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                return _PresetSkeletonGrid();
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Impossible de charger les plans.',
                  onRetry: () => setState(() => _presetsFuture = _fetchPresets()),
                );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Aucun plan trouvé.',
                    style: GoogleFonts.inter(color: Colors.white70),
              ),
            );
          }

              final allPresets = snapshot.data!;
              final personalizedPresets = _getPersonalizedPresets(allPresets);
              
              // Créer les FancyStackItem à partir des PlanPreset personnalisés
              _carouselItems = personalizedPresets.asMap().entries.map((entry) {
                final index = entry.key;
                final preset = entry.value;
                return FancyStackItem(
                  id: index + 1, // Utiliser l'index comme ID (commence à 1)
                  child: _buildPlanCard(preset),
                );
              }).toList();
              
              return _buildROIOnboardingPage(personalizedPresets);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildROIOnboardingPage(List<PlanPreset> presets) {
    return Column(
      children: [
        // Header avec bouton retour
        _buildHeader(),
        // Cards Section
        Expanded(
          flex: 3,
          child: _buildCardsSection(presets),
        ),
        // Text Content
        _buildTextContent(),
        // Pagination Dots
        _buildPaginationDots(presets.length),
        const SizedBox(height: 12),
        // Custom Generator Button (toujours affiché)
        _buildCustomGeneratorButton(),
        const SizedBox(height: 16),
        // Bottom Navigation
        _buildBottomNavigation(presets.length),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushReplacementNamed(context, '/complete_profile');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisis ton plan',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Des parcours personnalisés pour toi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(List<PlanPreset> presets) {
    return SizedBox(
      height: 380,
      child: FancyStackCarousel(
        items: _carouselItems,
        options: FancyStackCarouselOptions(
          size: const Size(300, 380),
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 6),
          autoplayDirection: AutoplayDirection.bothSide,
          onPageChanged: (index, reason, direction) {
            setState(() {
              _currentSlide = index;
            });
            debugPrint('Page changed to index: $index, Reason: $reason, Direction: $direction');
          },
          pauseAutoPlayOnTouch: true,
          pauseOnMouseHover: true,
        ),
        carouselController: _carouselController,
      ),
    );
  }

  Widget _buildPlanCard(PlanPreset preset) {
    return Hero(
      tag: 'preset_${preset.slug}',
      child: Semantics(
        label: 'Choisir ce plan : ${preset.name}',
        button: true,
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            await _onPlanSelected(preset);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 340,
      decoration: BoxDecoration(
              gradient: _getGradientForPreset(preset),
              borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond avec cache
                  if (preset.coverImage != null)
                    CachedNetworkImage(
                      imageUrl: preset.coverImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: _getGradientForPreset(preset),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: _getGradientForPreset(preset),
                        ),
                      ),
                    ),
                  // Voile frosted pour lisibilité
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(.55), Colors.black.withOpacity(0)],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge "Preset"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(.25)),
                      ),
                      child: Text(
                        'Preset',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Nom du plan
                    Text(
                      preset.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Détails
                    Text(
                      '${preset.durationDays} jours • ${_getEstimatedTime(preset)} min/jour',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Livres spécifiques à méditer
                    if (preset.specificBooks != null) ...[
                      Text(
                        'Livres: ${preset.specificBooks}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Text(
                        'Livres: ${_formatBooksForDisplay(preset.books)}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // CTA
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Choisir ce plan',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Icône discrète en haut à droite
              Positioned(
                right: 14, 
                top: 14,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.25)),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded, 
                    color: Colors.white, 
                    size: 18
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    String title = 'Choisis ton plan de lecture.';
    String subtitle = 'Découvre des parcours de lecture biblique adaptés à ton rythme et tes objectifs spirituels.';
    
    // Personnaliser le message selon le profil
    if (_showBeginnerTracks) {
      title = 'Commence par les fondations.';
      subtitle = 'Des plans spécialement conçus pour les nouveaux convertis. Découvre les bases de la foi chrétienne.';
    } else if (_userGoal == 'Discipline de prière') {
      title = 'Renforce ta discipline de prière.';
      subtitle = 'Des parcours pour développer une vie de prière régulière et profonde.';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          // Badge de personnalisation
          if (_userProfile != null) ...[
            const SizedBox(height: 12),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF49C98D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF49C98D).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_pin_circle,
                    size: 16,
                    color: Color(0xFF49C98D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Plan hybride Thompson + API',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF49C98D),
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

  Widget _buildPaginationDots(int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalItems, (index) {
        final isActive = index == _currentSlide;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNavigation(int totalItems) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1553FF), Color(0xFF49C98D)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Commencer',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
                      ),
                    ),
                  ],
                ),
    );
  }


  Widget _buildCustomGeneratorButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1553FF), Color(0xFF49C98D)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/custom_plan');
          },
          icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          label: Text(
            'Générer un plan personnalisé',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPlanInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les plans personnalisés seront disponibles après avoir terminé quelques plans guidés.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  LinearGradient _getGradientForPreset(PlanPreset preset) {
    // Utiliser le gradient personnalisé du preset s'il existe
    if (preset.gradient != null && preset.gradient!.length >= 2) {
      return LinearGradient(
        colors: preset.gradient!,
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    }
    
    // Fallback vers les gradients basés sur le slug du preset
    switch (preset.slug) {
      case 'nt_90':
        return const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      case 'bible_180':
        return const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFFC4B5FD)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      case 'proverbs_31':
        return const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF6EE7B7)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      case 'psalms_40':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
    }
  }

  String _getEstimatedTime(PlanPreset preset) {
    // Utiliser le temps de lecture du preset s'il est défini
    if (preset.minutesPerDay != null) {
      return preset.minutesPerDay.toString();
    }
    
    // Fallback vers les temps basés sur le slug du preset
    switch (preset.slug) {
      case 'nt_90':
        return '15';
      case 'bible_180':
        return '25';
      case 'proverbs_31':
        return '10';
      case 'psalms_40':
        return '12';
      case 'genesis_1_25_14d':
        return '18';
      case 'light_15':
        return '8';
      default:
        return '15';
    }
  }

  /// Formate les livres pour l'affichage sur les cartes
  String _formatBooksForDisplay(String books) {
    final bookNames = {
      'OT,NT': 'Ancien & Nouveau Testament',
      'NT': 'Nouveau Testament',
      'OT': 'Ancien Testament',
      'Gospels,Psalms': 'Évangiles & Psaumes',
      'Gospels': 'Évangiles',
      'Psalms,Proverbs': 'Psaumes & Proverbes',
      'Psalms': 'Psaumes',
      'Proverbs,James': 'Proverbes & Jacques',
      'Gospels,Psalms,Proverbs': 'Évangiles, Psaumes & Proverbes',
    };
    
    return bookNames[books] ?? books;
  }

  /// Génère un gradient pour les presets Thompson selon les thèmes
  List<Color>? _getThompsonGradient(List<dynamic>? themeKeys) {
    if (themeKeys == null || themeKeys.isEmpty) return null;
    
    final themes = themeKeys.cast<String>();
    
    // Gradients spécifiques aux thèmes Thompson
    if (themes.contains('no_worry')) {
      return [const Color(0xFF4FD1C5), const Color(0xFF06B6D4)]; // Teal pour la paix
    }
    if (themes.contains('spiritual_demand')) {
      return [const Color(0xFF7C8CFF), const Color(0xFF6366F1)]; // Indigo pour la discipline
    }
    if (themes.contains('marriage_duties')) {
      return [const Color(0xFFEC4899), const Color(0xFFF472B6)]; // Rose pour le mariage
    }
    if (themes.contains('companionship')) {
      return [const Color(0xFF34D399), const Color(0xFF10B981)]; // Vert pour la communauté
    }
    if (themes.contains('prayer_life')) {
      return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)]; // Violet pour la prière
    }
    if (themes.contains('forgiveness')) {
      return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]; // Orange pour le pardon
    }
    if (themes.contains('faith_trials')) {
      return [const Color(0xFFEF4444), const Color(0xFFF87171)]; // Rouge pour les épreuves
    }
    
    // Gradient par défaut pour Thompson
    return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
  }

  /// Génère les livres spécifiques pour un thème Thompson
  String? _getSpecificBooksForTheme(List<dynamic>? themeKeys) {
    if (themeKeys == null || themeKeys.isEmpty) return null;
    
    final themes = themeKeys.cast<String>();
    
    // Livres spécifiques aux thèmes Thompson
    if (themes.contains('no_worry')) {
      return 'Matthieu 6, Psaumes 23, 27, 46, 91, 121';
    }
    if (themes.contains('spiritual_demand')) {
      return 'Matthieu 5-7, Romains 12-14, Éphésiens 4-6';
    }
    if (themes.contains('marriage_duties')) {
      return 'Genèse 2, Proverbes 31, Éphésiens 5, 1 Corinthiens 7';
    }
    if (themes.contains('companionship')) {
      return 'Genèse 2, Proverbes 18, Actes 2, 1 Corinthiens 13';
    }
    if (themes.contains('prayer_life')) {
      return 'Psaumes 1-50, Matthieu 6, Luc 11, Éphésiens 6';
    }
    if (themes.contains('forgiveness')) {
      return 'Matthieu 18, Luc 15, Éphésiens 4, Colossiens 3';
    }
    if (themes.contains('faith_trials')) {
      return 'Jacques 1, Romains 5, 1 Pierre 1, Hébreux 11';
    }
    if (themes.contains('common_errors')) {
      return 'Proverbes 1-10, Jacques 1-5, Galates 5';
    }
    
    return null;
  }

  /// Gère la sélection d'un plan preset
  Future<void> _onPlanSelected(PlanPreset preset) async {
    try {
      final startDate = await _showDatePickerDialog(preset);
      if (startDate == null) return;

      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      final planService = context.read<PlanService>();
      final profile = context.read<UserPrefsHive>().profile;

      // ⚡ super-intelligente côté serveur : preset + profil
      final plan = await planService.createFromPreset(
        presetSlug: preset.slug,
        startDate: startDate,
        profile: profile,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan "${preset.name}" créé.'),
          backgroundColor: Colors.green,
        ));
      }

        Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Affiche un dialogue pour sélectionner la date de début
  Future<DateTime?> _showDatePickerDialog(PlanPreset preset) async {
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime selectedDate = DateTime.now();
        
    return AlertDialog(
          title: const Text('Choisir la date de début'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              Text(
                'Plan: ${preset.name}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Durée: ${preset.durationDays} jours',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
                child: Text(
                  'Sélectionner une date',
                  style: GoogleFonts.inter(),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Date sélectionnée: ${_formatDate(selectedDate)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: Text(
                'Créer le plan',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Formate une date pour l'affichage
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Skeleton grid pour le chargement
  Widget _PresetSkeletonGrid() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 380,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Skeleton pour les dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          )),
        ),
      ],
    );
  }

  /// État d'erreur avec bouton retry
  Widget _ErrorState({required String message, required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}