import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:fancy_stack_carousel/fancy_stack_carousel.dart';
import '../models/plan_preset.dart';
import '../services/plan_presets_repo.dart';
import '../services/user_prefs_hive.dart';
import '../services/user_prefs.dart'; // ✅ UserPrefs ESSENTIEL
import '../services/plan_service.dart';
import 'package:provider/provider.dart';
import '../services/dynamic_preset_generator.dart';
import '../services/intelligent_local_preset_generator.dart';
import '../widgets/uniform_back_button.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

/// Classe pour contenir le contenu dynamique
class _DynamicContent {
  final String title;
  final String subtitle;

  _DynamicContent({required this.title, required this.subtitle});
}

/// Options de plan preset (date + jours semaine)
class _PresetOptions {
  final DateTime startDate;
  final List<int> daysOfWeek; // 1..7 (lun..dim)
  
  _PresetOptions({
    required this.startDate,
    required this.daysOfWeek,
  });
}

class _GoalsPageState extends State<GoalsPage> {
  late Future<List<PlanPreset>> _presetsFuture;
  int _currentSlide = 0;
  late FancyStackCarouselController _carouselController;
  List<FancyStackItem> _carouselItems = [];
  
  // Profil utilisateur
  Map<String, dynamic>? _userProfile;
  bool _showBeginnerTracks = false;
  String _userGoal = '';

  @override
  void initState() {
    super.initState();
    _carouselController = FancyStackCarouselController();
    _loadUserProfile();
    // Générer des presets dynamiques basés sur le profil utilisateur
    _presetsFuture = _fetchPresets();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Régénérer les presets quand la page est revisitée
    _reloadPresetsIfNeeded();
  }
  
  /// ✅ Recharger les presets si le profil a changé
  Future<void> _reloadPresetsIfNeeded() async {
    try {
      // ✅ Utiliser UserPrefs (service principal, offline-first)
      final currentProfile = await UserPrefs.loadProfile();
      
      // Vérifier si le profil a changé
      if (_hasProfileChanged(currentProfile)) {
        print('🔄 Profil modifié détecté - Régénération des presets...');
        
        setState(() {
          _userProfile = currentProfile;
          _presetsFuture = _fetchPresets(); // ✅ Régénérer les presets
        });
        
        print('✅ Presets régénérés avec le nouveau profil');
      }
    } catch (e) {
      print('⚠️ Erreur rechargement presets: $e');
    }
  }
  
  /// Vérifier si le profil a changé (comparer les clés importantes)
  bool _hasProfileChanged(Map<String, dynamic> newProfile) {
    if (_userProfile == null) return true;
    
    // Comparer les clés importantes qui impactent la génération
    final importantKeys = [
      'level',
      'goal',
      'durationMin',
      'heartPosture',
      'motivation',
      'preferredTime',
    ];
    
    for (final key in importantKeys) {
      if (_userProfile![key] != newProfile[key]) {
        print('🔍 Changement détecté sur "$key": ${_userProfile![key]} → ${newProfile[key]}');
        return true;
      }
    }
    
    return false;
  }

  Future<List<PlanPreset>> _fetchPresets() async {
    print('🧠 Génération intelligente de presets locaux...');
    
    try {
      // Utiliser le générateur enrichi avec apprentissage et adaptation émotionnelle
      final enrichedPresets = IntelligentLocalPresetGenerator.generateEnrichedPresets(_userProfile ?? {});
      
      if (enrichedPresets.isNotEmpty) {
        print('✅ ${enrichedPresets.length} presets enrichis générés avec adaptation émotionnelle');
        
        // Générer les explications pour chaque preset
        final explanations = IntelligentLocalPresetGenerator.explainPresets(enrichedPresets, _userProfile);
        _printPresetExplanations(explanations);
        
        // Afficher les recommandations spirituelles
        final recommendations = IntelligentLocalPresetGenerator.getSpiritualRecommendations();
        _printSpiritualRecommendations(recommendations);
        
        return enrichedPresets;
      }
      
      // Fallback: générer des presets dynamiques si pas de profil
      print('📝 Fallback vers presets dynamiques...');
      final dynamicPresets = DynamicPresetGenerator.generateDynamicPresets(_userProfile);
      return dynamicPresets;
    } catch (e) {
      print('❌ Erreur génération intelligente: $e');
      // Fallback final vers les presets statiques
      print('📚 Fallback final vers presets statiques...');
      final allPresets = await PlanPresetsRepo.loadFromAsset();
      return allPresets;
    }
  }
  




  

  /// Charge le profil utilisateur et applique la logique de personnalisation
  Future<void> _loadUserProfile() async {
    try {
      final profile = context.read<UserPrefsHive>().profile;
      final level = profile['level'] as String? ?? 'Nouveau converti';
      final goal = profile['goal'] as String? ?? 'Discipline quotidienne';

      // 🔍 DEBUG: Afficher les valeurs lues pour vérifier la transmission
      print('🔍 GoalsPage._loadUserProfile() - Valeurs lues:');
      print('   level: "$level"');
      print('   goal: "$goal"');
      print('   preferredTime: "${profile['preferredTime']}"');
      print('   dailyMinutes: "${profile['dailyMinutes']}"');
      print('   durationMin: "${profile['durationMin']}"');
      print('   heartPosture: "${profile['heartPosture']}"');
      print('   motivation: "${profile['motivation']}"');
      print('   profile complet: $profile');

      setState(() {
        _userProfile = profile;
        _showBeginnerTracks = level == 'Nouveau converti';
        _userGoal = goal;
      });
      
      // Recharger les presets avec la personnalisation
      _presetsFuture = _fetchPresets();
    } catch (e) {
      print('⚠️ Erreur _loadUserProfile: $e');
      // En cas d'erreur, utiliser les valeurs par défaut
      setState(() {
        _showBeginnerTracks = true;
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
    
    // ✅ Garantir minimum 4 cartes (psychologie du choix optimal)
    if (personalized.length < 4) {
      print('⚠️ Seulement ${personalized.length} presets, ajout de presets supplémentaires...');
      
      // Ajouter tous les presets disponibles jusqu'à avoir au moins 4
      final allAvailable = allPresets.where((preset) => 
        !personalized.any((p) => p.slug == preset.slug)
      ).toList();
      
      final needed = 4 - personalized.length;
      final toAdd = allAvailable.take(needed).toList();
      personalized.addAll(toAdd);
      
      print('✅ ${personalized.length} presets maintenant disponibles');
    }
    
    // Limiter à 7 cartes maximum (psychologie : trop de choix = paralysie)
    if (personalized.length > 7) {
      personalized = personalized.take(7).toList();
      print('📊 Limité à 7 presets (psychologie du choix optimal)');
    }
    
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
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: Colors.white70,
                ),
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
        const SizedBox(height: 20), // ✅ Espacement entre header et cartes
        // Cards Section
        Expanded(
          flex: 3,
          child: _buildCardsSection(presets),
        ),
        // Text Content
        _buildTextContent(),
        const SizedBox(height: 12), // ✅ Espacement réduit
        // Pagination Dots
        _buildPaginationDots(presets.length),
        const SizedBox(height: 16), // ✅ Espacement réduit
        // Custom Generator Button (toujours affiché)
        _buildCustomGeneratorButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader() {
    return UniformHeader(
      title: 'Choisis ton plan',
      subtitle: 'Des parcours personnalisés pour toi',
      onBackPressed: () => context.go('/complete_profile'),
      textColor: Colors.white,
      iconColor: Colors.white,
      titleAlignment: CrossAxisAlignment.start,
    );
  }

  /// Affiche les explications des presets dans la console (pour debug)
  void _printPresetExplanations(List<PresetExplanation> explanations) {
    print('\n🎯 === EXPLICATIONS DES PRESETS ===');
    for (final e in explanations) {
      print('\n--- ${e.name} (score: ${e.totalScore})');
      for (final r in e.reasons) {
        final sign = r.weight >= 0 ? '+' : '';
        print('  • ${r.label}: $sign${r.weight.toStringAsFixed(2)} — ${r.detail}');
      }
    }
    print('\n=====================================\n');
  }

  /// Affiche les recommandations spirituelles dans la console (pour debug)
  void _printSpiritualRecommendations(List<String> recommendations) {
    print('\n🙏 === RECOMMANDATIONS SPIRITUELLES ===');
    for (final recommendation in recommendations) {
      print('  • $recommendation');
    }
    print('==========================================\n');
  }

  Widget _buildCardsSection(List<PlanPreset> presets) {
    return Column(
      children: [
        SizedBox(
          height: 380, // Hauteur du carousel ajustée
          child: FancyStackCarousel(
            items: _carouselItems,
            options: FancyStackCarouselOptions(
              size: const Size(310, 380), // Taille des cartes ajustée
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
        ),
        const SizedBox(height: 24), // ✅ Plus d'espace avant l'icône swipe
        // ✅ Icône swipe moderne
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swipe,
              size: 20,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Glisse pour explorer',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(PlanPreset preset) {
    final t = Theme.of(context).textTheme;
    final weeks = (preset.durationDays / 7).ceil(); // Convertir en semaines
    
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
            height: 360, // Hauteur augmentée pour le bouton
            decoration: BoxDecoration(
              color: _getCardColorForPreset(preset),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _getCardColorForPreset(preset).withOpacity(0.15), // Halo réduit
                  blurRadius: 12, // Blur réduit
                  offset: const Offset(0, 6), // Offset réduit
                ),
              ],
            ),
            child: Stack(
              children: [
                // ✅ GRANDE ILLUSTRATION "BÉNÉFICE CLAIR" derrière le nom (impact visuel)
                Positioned(
                  top: 100, // ✅ Positionné derrière le nom
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      _getBenefitIconForPreset(preset), // ✅ Icône du bénéfice
                      size: 200, // ✅ Très grande
                      color: const Color(0xFF111111).withOpacity(0.06), // ✅ Opacité très faible
                    ),
                  ),
                ),
                
                // ✅ PETITE ICÔNE encadrée en HAUT À DROITE
                Positioned(
                  top: 15,
                  right: 15,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF111111).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getModernIconForPreset(preset),
                          size: 32, // ✅ Petite icône
                          color: const Color(0xFF111111).withOpacity(0.6),
                        ),
                      ),
                      // ✅ "Recommandé" sous l'icône
                      if (_isRecommendedPreset(preset)) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1553FF), Color(0xFF0D47A1)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Top',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                        
                // ✅ Nombre de SEMAINES simple et élégant (sans effet 3D)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // ✅ Centré
                    children: [
                      // ✅ Nombre GALLOS ARCHITYPE HEAVY (police spéciale pour impact)
                      Text(
                        '$weeks',
                        style: const TextStyle(
                          fontFamily: 'GallosArchitype', // ✅ Police Gallos Architype
                          fontWeight: FontWeight.w900, // Heavy
                          fontSize: 88,
                          height: 0.85,
                          color: Color(0xFF111111),
                          letterSpacing: -3,
                        ),
                        textAlign: TextAlign.center, // ✅ Centré
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weeks == 1 ? 'semaine' : 'semaines',
                        style: t.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: const Color(0xFF111111).withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center, // ✅ Centré
                      ),
                    ],
                  ),
                ),
                
                
                // Titre GILROY HEAVY ITALIC + Livres en bas
                Positioned(
                  top: 120, // ✅ Monté pour éviter l'illustration
                  left: 0, // ✅ Centré
                  right: 0, // ✅ Centré
                  bottom: 90, // Espace pour le bouton
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32), // ✅ Plus de padding pour éviter les bords
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Titre en GILROY HEAVY ITALIC (Capitalized pour psychologie positive)
                          Text(
                            _toTitleCase(_getShortNameForPreset(preset)), // ✅ Title Case
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800, // Heavy
                              fontStyle: FontStyle.italic, // ✅ Italic
                              fontSize: 24, // ✅ Plus grand pour impact
                              height: 1.1, // ✅ Compact
                              color: Color(0xFF111111),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // ✅ Minutes/jour
                          Text(
                            '${_userProfile?['durationMin'] as int? ?? preset.minutesPerDay ?? 15} min/jour',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF111111),
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // ✅ BÉNÉFICE PSYCHOLOGIQUE - Ce que l'utilisateur va gagner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getBenefitForPreset(preset),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: Color(0xFF111111),
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bouton "Choisir ce plan" en bas
                Positioned(
                  bottom: 20,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Choisir ce plan',
                        style: t.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  Widget _buildTextContent() {
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    final goal = _userProfile?['goal'] as String? ?? 'Discipline quotidienne';
    
    final content = _getDynamicContentForLevel(level, goal);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // ✅ Réduit vertical pour monter le texte
      child: Column(
        children: [
          Text(
            content.title,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            content.subtitle,
            style: const TextStyle(
              fontFamily: 'Gilroy',
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
                    'Plans personnalisés pour toi',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF49C98D),
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

  /// Contenu dynamique basé sur le niveau spirituel
  _DynamicContent _getDynamicContentForLevel(String level, String goal) {
    switch (level) {
      case 'Nouveau converti':
        return _DynamicContent(
          title: 'Commence par les fondations',
          subtitle: _getNewConvertContent(goal),
        );
      case 'Rétrograde':
        return _DynamicContent(
          title: 'Retrouve le chemin',
          subtitle: _getRetrogradeContent(goal),
        );
      case 'Fidèle pas si régulier':
        return _DynamicContent(
          title: 'Retrouve la constance',
          subtitle: _getIrregularContent(goal),
        );
      case 'Serviteur/leader':
        return _DynamicContent(
          title: 'Affermis ton leadership',
          subtitle: _getLeaderContent(goal),
        );
      default: // Fidèle régulier
        return _DynamicContent(
          title: 'Approfondis ta marche',
          subtitle: _getRegularContent(goal),
        );
    }
  }

  /// Contenu pour nouveaux convertis (très court)
  String _getNewConvertContent(String goal) {
    return '''Bienvenue dans cette merveilleuse aventure qu'est la vie chrétienne !''';
  }

  /// Contenu pour rétrogrades (très court)
  String _getRetrogradeContent(String goal) {
    return '''Cher ami, ton retour vers Dieu est un moment de grâce infinie.''';
  }

  /// Contenu pour fidèles irréguliers (très court)
  String _getIrregularContent(String goal) {
    return '''Cher ami fidèle, ton désir de retrouver la constance révèle un cœur qui aspire à plus de profondeur.''';
  }

  /// Contenu pour leaders (très court)
  String _getLeaderContent(String goal) {
    return '''Cher leader dans la foi, ton appel à servir Dieu est un privilège immense.''';
  }

  /// Contenu pour fidèles réguliers (très court)
  String _getRegularContent(String goal) {
    return '''Cher ami fidèle, ta constance dans la marche chrétienne est un témoignage précieux.''';
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



  Widget _buildCustomGeneratorButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1553FF),
              Color(0xFF0D47A1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1553FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: () {
            context.go('/custom_plan');
          },
          icon: const Icon(Icons.tune_rounded, size: 24, color: Colors.white),
          label: Text(
            'Clique ici si tu veux créer ton propre plan',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }



  /// Couleur psychologique basée sur l'état émotionnel et le thème spirituel
  Color _getCardColorForPreset(PlanPreset preset) {
    final name = preset.name.toLowerCase();
    final goal = _userGoal.toLowerCase();
    
    // 🎨 COULEURS PSYCHOLOGIQUES basées sur les recherches scientifiques
    
    // JAUNE (0xFFFFD54F) - Optimisme, Joie, Énergie positive
    // Recommandé pour: Nouveaux départs, espoir, croissance
    if (name.contains('espoir') || name.contains('hope') || name.contains('nouveau') ||
        goal.contains('encouragement') || goal.contains('guérison')) {
      return const Color(0xFFFFD54F); // Jaune doré
    }
    
    // BLANC CASSÉ (0xFFFFF8E1) - Pureté, Paix, Sérénité
    // Recommandé pour: Méditation, prière, contemplation
    if (name.contains('méditation') || name.contains('meditation') || name.contains('paix') ||
        goal.contains('prier') || goal.contains('prière')) {
      return const Color(0xFFFFF8E1); // Blanc cassé crème
    }
    
    // BLEU CLAIR (0xFF90CAF9) - Calme, Confiance, Spiritualité
    // Recommandé pour: Foi, confiance en Dieu, stabilité émotionnelle
    if (name.contains('foi') || name.contains('faith') || name.contains('confiance') ||
        goal.contains('foi') || name.contains('romains')) {
      return const Color(0xFF90CAF9); // Bleu ciel apaisant
    }
    
    // VERT MENTHE (0xFF81C784) - Croissance, Renouveau, Équilibre
    // Recommandé pour: Croissance spirituelle, transformation, caractère
    if (name.contains('croissance') || name.contains('growth') || name.contains('caractère') ||
        goal.contains('grandir') || goal.contains('développer') || name.contains('philippiens')) {
      return const Color(0xFF81C784); // Vert croissance
    }
    
    // LAVANDE (0xFFCE93D8) - Spiritualité profonde, Introspection, Sagesse
    // Recommandé pour: Sagesse, connaissance, approfondissement
    if (name.contains('sagesse') || name.contains('wisdom') || name.contains('proverbes') ||
        goal.contains('approfondir') || goal.contains('connaissance')) {
      return const Color(0xFFCE93D8); // Lavande spirituelle
    }
    
    // ROSE POUDRÉ (0xFFF48FB1) - Amour, Pardon, Compassion
    // Recommandé pour: Pardon, guérison émotionnelle, relations
    if (name.contains('pardon') || name.contains('forgiveness') || name.contains('amour') ||
        goal.contains('pardon') || goal.contains('guérison') || name.contains('luc')) {
      return const Color(0xFFF48FB1); // Rose tendre
    }
    
    // PÊCHE (0xFFFFAB91) - Chaleur, Réconfort, Encouragement
    // Recommandé pour: Encouragement, réconfort, soutien
    if (name.contains('réconfort') || name.contains('encouragement') || name.contains('soutien') ||
        goal.contains('encouragement')) {
      return const Color(0xFFFFAB91); // Pêche chaleureux
    }
    
    // ORANGE CORAIL (0xFFFFCC80) - Énergie, Enthousiasme, Mission
    // Recommandé pour: Mission, service, partage de la foi
    if (name.contains('mission') || name.contains('service') || name.contains('actes') ||
        goal.contains('partager') || goal.contains('mission')) {
      return const Color(0xFFFFCC80); // Orange mission
    }
    
    // TURQUOISE (0xFF80DEEA) - Communication, Expression, Louange
    // Recommandé pour: Psaumes, louange, adoration
    if (name.contains('psaumes') || name.contains('psalm') || name.contains('louange') ||
        name.contains('adoration')) {
      return const Color(0xFF80DEEA); // Turquoise louange
    }
    
    // VERT ÉMERAUDE (0xFFA5D6A7) - Vie, Évangile, Renouveau
    // Recommandé pour: Évangiles, vie en Christ
    if (name.contains('évangile') || name.contains('gospel') || name.contains('matthieu') || 
        name.contains('jean') || name.contains('marc') || name.contains('luc')) {
      return const Color(0xFFA5D6A7); // Vert émeraude vie
    }
    
    // COULEUR PAR DÉFAUT selon le niveau spirituel de l'utilisateur
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    
    if (level == 'Nouveau converti') {
      return const Color(0xFFFFD54F); // Jaune - optimisme pour débutants
    } else if (level == 'Rétrograde') {
      return const Color(0xFFF48FB1); // Rose - compassion et pardon
    } else if (level == 'Serviteur/leader') {
      return const Color(0xFF90CAF9); // Bleu - confiance et autorité
    }
    
    // Fallback: Palette variée selon le slug
    final colors = [
      const Color(0xFFFFD54F), // Jaune
      const Color(0xFF90CAF9), // Bleu
      const Color(0xFF81C784), // Vert
      const Color(0xFFCE93D8), // Lavande
      const Color(0xFFF48FB1), // Rose
      const Color(0xFFFFAB91), // Pêche
      const Color(0xFFFFCC80), // Orange
      const Color(0xFF80DEEA), // Turquoise
      const Color(0xFFA5D6A7), // Vert émeraude
      const Color(0xFFFFF8E1), // Blanc cassé
    ];
    return colors[preset.slug.hashCode % colors.length];
  }
  
  /// ✨ Icônes MODERNES vectorielles pour illustrations (Material Icons)
  IconData _getModernIconForPreset(PlanPreset preset) {
    final name = preset.name.toLowerCase();
    
    // Icônes thématiques modernes selon le contenu spirituel
    if (name.contains('prière') || name.contains('prayer')) {
      return Icons.self_improvement_rounded; // Méditation/Prière
    } else if (name.contains('sagesse') || name.contains('wisdom') || name.contains('proverbes')) {
      return Icons.lightbulb_rounded; // Sagesse
    } else if (name.contains('foi') || name.contains('faith') || name.contains('romains')) {
      return Icons.star_rounded; // Foi
    } else if (name.contains('croissance') || name.contains('growth') || name.contains('philippiens')) {
      return Icons.eco_rounded; // Croissance
    } else if (name.contains('pardon') || name.contains('forgiveness') || name.contains('luc')) {
      return Icons.favorite_rounded; // Pardon/Amour
    } else if (name.contains('espoir') || name.contains('hope') || name.contains('pierre')) {
      return Icons.wb_sunny_rounded; // Espoir
    } else if (name.contains('caractère') || name.contains('character') || name.contains('galates')) {
      return Icons.diamond_rounded; // Caractère
    } else if (name.contains('mission') || name.contains('actes')) {
      return Icons.rocket_launch_rounded; // Mission
    } else if (name.contains('psaumes') || name.contains('psalm')) {
      return Icons.music_note_rounded; // Louange
    } else if (name.contains('évangile') || name.contains('gospel') || name.contains('matthieu') || name.contains('jean')) {
      return Icons.menu_book_rounded; // Évangile
    } else if (name.contains('méditation') || name.contains('meditation')) {
      return Icons.spa_rounded; // Méditation
    } else if (name.contains('réconfort') || name.contains('consolation')) {
      return Icons.healing_rounded; // Réconfort
    } else if (name.contains('bénédiction') || name.contains('blessing')) {
      return Icons.auto_awesome_rounded; // Bénédiction
    } else if (name.contains('nouvelle') || name.contains('nouveau')) {
      return Icons.fiber_new_rounded; // Nouveau
    } else if (name.contains('force') || name.contains('strength')) {
      return Icons.fitness_center_rounded; // Force
    } else if (name.contains('gloire') || name.contains('glory')) {
      return Icons.military_tech_rounded; // Gloire/Couronne
    } else if (name.contains('arbre') || name.contains('tree') || name.contains('graine') || name.contains('épi')) {
      return Icons.park_rounded; // Arbre/Nature
    } else if (name.contains('chemin') || name.contains('path') || name.contains('vie')) {
      return Icons.route_rounded; // Chemin
    }
    
    // Icônes par défaut selon le niveau spirituel
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    
    if (level == 'Nouveau converti') return Icons.wb_twilight_rounded; // Lever de soleil
    if (level == 'Rétrograde') return Icons.restore_rounded; // Restauration
    if (level == 'Serviteur/leader') return Icons.local_fire_department_rounded; // Feu
    
    // Fallback par défaut
    return Icons.auto_stories_rounded; // Livre
  }

  /// 🎯 BASE DE DONNÉES PSYCHOLOGIQUE - Noms attractifs qui donnent envie de choisir
  String _getShortNameForPreset(PlanPreset preset) {
    // ✅ Nettoyer le nom d'abord
    String cleanedName = preset.name
        .replaceAll(RegExp(r'\.\d+'), '')
        .split('•')[0]
        .split(':')[0]
        .trim()
        .toLowerCase();
    
    // 🧠 BASE PSYCHOLOGIQUE : Noms optimisés pour maximiser l'attractivité
    // Basé sur les principes de persuasion de Cialdini et la psychologie positive
    
    // 💎 TRANSFORMATION & CROISSANCE (mots-clés : nouveau, grandit, mûrit, force)
    if (cleanedName.contains('nouveau') || cleanedName.contains('renouvelle')) {
      return 'Deviens\nla Meilleure Version';
    } else if (cleanedName.contains('grandit') || cleanedName.contains('graine')) {
      return 'Grandis\nChaque Jour';
    } else if (cleanedName.contains('mûrit') || cleanedName.contains('épi')) {
      return 'Progresse\nà Ton Rythme';
    } else if (cleanedName.contains('force') || cleanedName.contains('puissance')) {
      return 'Développe\nTa Force Intérieure';
    }
    
    // 🌟 SPIRITUALITÉ & CONNEXION (mots-clés : arbre, eaux, gloire, chemin)
    else if (cleanedName.contains('arbre') || cleanedName.contains('planté')) {
      return 'Enracine-toi\nProfondément';
    } else if (cleanedName.contains('gloire')) {
      return 'Rayonne\nde Gloire';
    } else if (cleanedName.contains('chemin') || cleanedName.contains('vie')) {
      return 'Découvre\nTon Chemin';
    } else if (cleanedName.contains('flamme') || cleanedName.contains('raviver')) {
      return 'Rallume\nTa Flamme';
    }
    
    // 🎯 PAIX & SÉRÉNITÉ (mots-clés : méditation, paix, consolation, réconfort)
    else if (cleanedName.contains('méditation') || cleanedName.contains('contemplation')) {
      return 'Trouve\nla Paix Intérieure';
    } else if (cleanedName.contains('consolation') || cleanedName.contains('réconfort')) {
      return 'Reçois\nLe Réconfort';
    } else if (cleanedName.contains('paix')) {
      return 'Cultive\nla Sérénité';
    }
    
    // ⚡ PASSION & ÉNERGIE (mots-clés : feu, zèle, mission)
    else if (cleanedName.contains('feu') || cleanedName.contains('zèle')) {
      return 'Enflamme\nTon Cœur';
    } else if (cleanedName.contains('mission') || cleanedName.contains('appel')) {
      return 'Accomplis\nTa Mission';
    }
    
    // 💪 DISCIPLINE & PERSÉVÉRANCE (mots-clés : discipline, fidèle, constant)
    else if (cleanedName.contains('discipline') || cleanedName.contains('régulier')) {
      return 'Bâtis\nDes Habitudes Solides';
    } else if (cleanedName.contains('fidèle') || cleanedName.contains('constant')) {
      return 'Reste\nFidèle';
    }
    
    // ❤️ AMOUR & INTIMITÉ (mots-clés : amour, intimité, cœur)
    else if (cleanedName.contains('amour') || cleanedName.contains('intimité')) {
      return 'Approfondis\nTon Amour';
    } else if (cleanedName.contains('cœur')) {
      return 'Écoute\nTon Cœur';
    }
    
    // 🌈 ESPOIR & JOIE (mots-clés : espoir, joie, bénédiction)
    else if (cleanedName.contains('espoir') || cleanedName.contains('espérance')) {
      return 'Redécouvre\nL\'Espoir';
    } else if (cleanedName.contains('joie') || cleanedName.contains('bonheur')) {
      return 'Choisis\nla Joie';
    } else if (cleanedName.contains('bénédiction') || cleanedName.contains('grâce')) {
      return 'Reçois\nLes Bénédictions';
    }
    
    // 🎓 SAGESSE & CONNAISSANCE (mots-clés : sagesse, connaissance, lumière)
    else if (cleanedName.contains('sagesse') || cleanedName.contains('sage')) {
      return 'Acquiers\nLa Sagesse';
    } else if (cleanedName.contains('lumière') || cleanedName.contains('éclaire')) {
      return 'Marche\nDans La Lumière';
    }
    
    // ✨ FALLBACK INTELLIGENT : Maximum 2 mots par ligne
    final words = cleanedName
        .split(' ')
        .where((word) => 
          word.isNotEmpty && 
          !RegExp(r'^\d+$').hasMatch(word) &&
          word.length > 1
        )
        .toList();
    
    // ✅ Format optimisé : MAX 2 mots par ligne
    if (words.length >= 6) {
      // 6+ mots : 2-2-2 sur 3 lignes
      return '${_capitalize(words[0])} ${_capitalize(words[1])}\n${_capitalize(words[2])} ${_capitalize(words[3])}\n${_capitalize(words[4])} ${_capitalize(words[5])}';
    } else if (words.length == 5) {
      // 5 mots : 2-2-1 sur 3 lignes
      return '${_capitalize(words[0])} ${_capitalize(words[1])}\n${_capitalize(words[2])} ${_capitalize(words[3])}\n${_capitalize(words[4])}';
    } else if (words.length == 4) {
      // 4 mots : 2-2 sur 2 lignes
      return '${_capitalize(words[0])} ${_capitalize(words[1])}\n${_capitalize(words[2])} ${_capitalize(words[3])}';
    } else if (words.length == 3) {
      // 3 mots : 2-1 sur 2 lignes
      return '${_capitalize(words[0])} ${_capitalize(words[1])}\n${_capitalize(words[2])}';
    } else if (words.length == 2) {
      // 2 mots : 2 sur 1 ligne OU 1-1 sur 2 lignes selon la longueur
      final totalLength = words[0].length + words[1].length;
      if (totalLength > 15) {
        return '${_capitalize(words[0])}\n${_capitalize(words[1])}';
      }
      return '${_capitalize(words[0])} ${_capitalize(words[1])}';
    } else if (words.isNotEmpty) {
      return _capitalize(words[0]);
    }
    
    return 'Commence\nTon Parcours';
  }
  
  /// Capitalise la première lettre d'un mot
  String _capitalize(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }
  
  /// Convertit en Title Case (première lettre de chaque mot en majuscule)
  /// Psychologiquement plus attractif que TOUT EN MAJUSCULES
  String _toTitleCase(String text) {
    return text.split('\n').map((line) {
      return line.split(' ').map((word) {
        if (word.isEmpty) return word;
        // Garder les petits mots en minuscule (de, la, le, etc.) sauf en début
        final smallWords = ['de', 'la', 'le', 'les', 'des', 'du', 'en', 'et', 'ou', 'à'];
        if (smallWords.contains(word.toLowerCase()) && line.split(' ').first != word) {
          return word.toLowerCase();
        }
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }).join('\n');
  }
  
  /// 🎨 ICÔNE DU BÉNÉFICE - Illustration grande derrière le nom
  /// Cette icône correspond EXACTEMENT à l'emoji dans le texte du bénéfice
  IconData _getBenefitIconForPreset(PlanPreset preset) {
    final name = preset.name.toLowerCase();
    
    // ✅ Icônes correspondant aux emojis du bénéfice
    if (name.contains('arbre') || name.contains('planté')) {
      return Icons.park_rounded; // ✨ Arbre
    } else if (name.contains('graine') || name.contains('grandit')) {
      return Icons.eco_rounded; // 🌱 Plante/Croissance
    } else if (name.contains('gloire')) {
      return Icons.auto_awesome_rounded; // ⭐ Étoiles/Gloire
    } else if (name.contains('flamme') || name.contains('raviver')) {
      return Icons.local_fire_department_rounded; // 🔥 Feu
    } else if (name.contains('méditation')) {
      return Icons.spa_rounded; // 🧘 Méditation/Spa
    } else if (name.contains('chemin') || name.contains('vie')) {
      return Icons.route_rounded; // 🛤️ Chemin
    } else if (name.contains('nouveau') || name.contains('renouvelle')) {
      return Icons.wb_sunny_rounded; // ✨ Soleil/Nouveau
    } else if (name.contains('force')) {
      return Icons.fitness_center_rounded; // 💪 Force
    } else if (name.contains('grâce') || name.contains('croître')) {
      return Icons.volunteer_activism_rounded; // 🎁 Don/Grâce
    }
    
    // Icône par défaut selon la durée (correspond aux emojis par défaut)
    final weeks = (preset.durationDays / 7).ceil();
    if (weeks <= 5) {
      return Icons.bolt_rounded; // ⚡ Éclair
    } else if (weeks <= 10) {
      return Icons.trending_up_rounded; // 📈 Progression
    } else {
      return Icons.emoji_events_rounded; // 🏆 Trophée
    }
  }
  
  /// 🎁 BÉNÉFICE PSYCHOLOGIQUE - Ce que l'utilisateur va gagner
  String _getBenefitForPreset(PlanPreset preset) {
    final name = preset.name.toLowerCase();
    final weeks = (preset.durationDays / 7).ceil();
    
    // Bénéfices basés sur la durée et le contenu
    if (name.contains('arbre') || name.contains('planté')) {
      return '✨ Enracine ta foi solidement';
    } else if (name.contains('graine') || name.contains('grandit')) {
      return '🌱 Croissance progressive garantie';
    } else if (name.contains('gloire')) {
      return '⭐ Transforme-toi de l\'intérieur';
    } else if (name.contains('flamme') || name.contains('raviver')) {
      return '🔥 Retrouve ta passion spirituelle';
    } else if (name.contains('méditation')) {
      return '🧘 Paix intérieure profonde';
    } else if (name.contains('chemin') || name.contains('vie')) {
      return '🛤️ Clarté et direction divine';
    } else if (name.contains('nouveau') || name.contains('renouvelle')) {
      return '✨ Nouveau départ, nouvelle vie';
    } else if (name.contains('force')) {
      return '💪 Force spirituelle croissante';
    } else if (name.contains('grâce') || name.contains('croître')) {
      return '🎁 Grâce abondante quotidienne';
    }
    
    // Bénéfice par défaut selon la durée
    if (weeks <= 5) {
      return '⚡ Résultats rapides et visibles';
    } else if (weeks <= 10) {
      return '📈 Progression équilibrée et durable';
    } else {
      return '🏆 Transformation profonde garantie';
    }
  }
  
  /// ⭐ Détermine si un preset est "recommandé" (score élevé)
  bool _isRecommendedPreset(PlanPreset preset) {
    // Un preset est recommandé s'il correspond bien au profil
    final goal = _userProfile?['goal'] as String? ?? '';
    final level = _userProfile?['level'] as String? ?? '';
    final name = preset.name.toLowerCase();
    
    // Correspondance avec l'objectif
    if (goal.contains('intimité') && (name.contains('arbre') || name.contains('chemin'))) {
      return true;
    } else if (goal.contains('transformation') && (name.contains('nouveau') || name.contains('gloire'))) {
      return true;
    } else if (goal.contains('discipline') && (name.contains('croître') || name.contains('grâce'))) {
      return true;
    }
    
    // Correspondance avec le niveau
    if (level == 'Nouveau converti' && preset.durationDays <= 35) {
      return true;
    } else if (level == 'Rétrograde' && name.contains('flamme')) {
      return true;
    }
    
    // Par défaut, le premier preset est toujours recommandé
    return false;
  }




  /// Gère la sélection d'un plan preset (100% OFFLINE avec options complètes)
  Future<void> _onPlanSelected(PlanPreset preset) async {
    HapticFeedback.selectionClick();

    // 1) Options utilisateur (date + jours) via bottom sheet
    final opts = await _showPresetOptionsSheet(
      preset: preset,
      initialStart: DateTime.now(),
    );
    
    if (opts == null) return; // Annulé par l'utilisateur

    // 2) Récupérer minutes/jour depuis le profil utilisateur (UserPrefs)
    final minutesPerDay = _userProfile?['durationMin'] as int? ?? preset.minutesPerDay ?? 15;

    // 3) Génère les passages totalement offline
    final customPassages = _generateOfflinePassagesForPreset(
      preset: preset,
      startDate: opts.startDate,
      minutesPerDay: minutesPerDay, // ← Vient de CompleteProfilePage
      daysOfWeek: opts.daysOfWeek, // 1..7 (lun..dim)
    );

    // 3) Crée le plan local (100% offline)
    try {
      final planService = context.read<PlanService>();
      
      await planService.createLocalPlan(
        name: preset.name,
        totalDays: preset.durationDays,
        startDate: opts.startDate,
        books: preset.books,
        specificBooks: preset.specificBooks,
        minutesPerDay: minutesPerDay, // ← Vient de UserPrefs (CompleteProfilePage)
        customPassages: customPassages, // ✅ Passages générés respectant calendrier
        daysOfWeek: opts.daysOfWeek, // ✅ NOUVEAU - Jours de lecture sélectionnés
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan "${preset.name}" créé (offline, ${opts.daysOfWeek.length} jours/semaine)'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/onboarding');
    } catch (e) {
      print('❌ Erreur création plan local: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création du plan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Bottom sheet d'options pour personnaliser le plan (date + jours)
  Future<_PresetOptions?> _showPresetOptionsSheet({
    required PlanPreset preset,
    required DateTime initialStart,
  }) async {
    DateTime start = initialStart;
    final dow = <int>{1, 2, 3, 4, 5, 6, 7}; // Tous les jours par défaut

    return showModalBottomSheet<_PresetOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1D29), Color(0xFF2D1B69)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
              Text(
                'Personnalise ton plan',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
                  const SizedBox(height: 20),

                  // Date de début (avec indicateur cliquable visible)
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => start = d);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1553FF).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1553FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF1553FF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de début',
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${start.day}/${start.month}/${start.year}',
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1553FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Jours de la semaine
                  Align(
                    alignment: Alignment.centerLeft,
                  child: Text(
                    'Jours de lecture',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      final dayIndex = i + 1; // 1..7
                      final selected = dow.contains(dayIndex);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              dow.remove(dayIndex);
                            } else {
                              dow.add(dayIndex);
                            }
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1553FF)
                                : Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1553FF)
                                  : Colors.white.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              dayNames[i],
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),
                  
                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (dow.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Sélectionnez au moins 1 jour'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(
                              ctx,
                              _PresetOptions(
                                startDate: start,
                                daysOfWeek: dow.toList()..sort(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1553FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Créer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  /// Génération offline des passages pour un preset (respecte jours sélectionnés)
  List<Map<String, dynamic>> _generateOfflinePassagesForPreset({
    required PlanPreset preset,
    required DateTime startDate,
    required int minutesPerDay,
    required List<int> daysOfWeek, // 1..7
  }) {
    final targetDays = preset.durationDays;
    final booksSource = (preset.specificBooks?.isNotEmpty ?? false)
        ? preset.specificBooks!
        : preset.books;

    // Pool de livres basé sur le preset
    final pool = _expandBooksPool(booksSource);
    int poolIdx = 0;

    // Rythme ≈ nb de versets/jour
    final versesPerMin = 2.5;
    final targetVerses = (minutesPerDay * versesPerMin).round().clamp(6, 30);

    final result = <Map<String, dynamic>>[];
    DateTime cur = startDate;

    int produced = 0;
    while (produced < targetDays) {
      // Respect réel du calendrier : sauter les jours non cochés
      final dow = cur.weekday; // 1=Mon..7=Sun
      if (!daysOfWeek.contains(dow)) {
        cur = cur.add(const Duration(days: 1));
        continue; // Passer au jour suivant
      }

      final book = pool[poolIdx % pool.length];
      poolIdx++;

      // Logique de progression chapitres/versets
      final chapter = (produced % 28) + 1;
      final startV = ((produced * 3) % 10) + 1;
      final endV = (startV + targetVerses).clamp(startV + 2, startV + 40);

      result.add({
        'reference': '$book $chapter:$startV-$endV',
        'text': 'Lecture de $book — ch.$chapter',
        'book': book,
        'theme': _themeForBook(book),
        'focus': _focusForBook(book),
        'duration': minutesPerDay,
        'estimatedVerses': endV - startV + 1,
        'date': cur.toIso8601String(),
      });

      produced++;
      cur = cur.add(const Duration(days: 1));
    }

    print('📖 ${result.length} passages générés offline pour "${preset.name}"');
    print('📅 Jours sélectionnés: ${daysOfWeek.join(',')} → Plan respecte le calendrier réel');
    
    return result;
  }
  
  /// Expand books pool depuis booksSource (ex: "Psaumes,Proverbes" ou "NT")
  List<String> _expandBooksPool(String booksSource) {
    if (booksSource.contains(',')) {
      return booksSource.split(',').map((b) => b.trim()).toList();
    }
    
    // Expansion des catégories
    if (booksSource == 'NT') {
      return ['Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains', 'Galates', 'Éphésiens'];
    } else if (booksSource == 'OT') {
      return ['Genèse', 'Exode', 'Psaumes', 'Proverbes', 'Ésaïe'];
    } else if (booksSource.contains('Psaumes')) {
      return ['Psaumes'];
    }
    
    return [booksSource];
  }
  
  /// Retourne le thème pour un livre
  String _themeForBook(String book) {
    const bookThemes = {
      'Jean': 'Vie en Christ',
      'Psaumes': 'Louange et prière',
      'Romains': 'Salut par la foi',
      'Galates': 'Liberté en Christ',
      'Éphésiens': 'Richesse en Christ',
      'Marc': 'Le Serviteur parfait',
      'Luc': 'Le Sauveur du monde',
      'Matthieu': 'Le Roi promis',
    };
    
    return bookThemes[book] ?? 'Étude biblique';
  }
  
  /// Retourne le focus pour un livre
  String _focusForBook(String book) {
    const bookFocus = {
      'Jean': 'Relation avec Jésus',
      'Psaumes': 'Adoration',
      'Romains': 'Doctrine',
      'Galates': 'Liberté',
      'Éphésiens': 'Identité en Christ',
      'Marc': 'Service',
      'Luc': 'Compassion',
      'Matthieu': 'Royaume',
    };
    
    return bookFocus[book] ?? 'Application pratique';
  }

  /// Skeleton grid pour le chargement
  Widget _PresetSkeletonGrid() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 320, // Hauteur du skeleton réduite
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
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1553FF),
                  Color(0xFF0D47A1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1553FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}