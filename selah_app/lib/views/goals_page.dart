import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:fancy_stack_carousel/fancy_stack_carousel.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plan_preset.dart';
import '../services/plan_presets_repo.dart';
import '../services/user_prefs_hive.dart';
import '../services/user_prefs.dart';
import '../services/user_prefs_sync.dart'; // ✅ UserPrefs ESSENTIEL
import 'package:provider/provider.dart';
import '../services/dynamic_preset_generator.dart';
import '../services/intelligent_local_preset_generator.dart';
import '../services/semantic_passage_boundary_service.dart'; // 🚀 FALCON X
// 🧠 IntelligentDurationCalculator
import '../services/preset_theology_gate_v2.dart' as Theology; // 🕊️ TheologyGate V2
import '../services/preset_theology_adapter_v2.dart'; // 🔄 Adaptateur V2
import '../services/doctrine/doctrine_pipeline.dart'; // 🕊️ Pipeline doctrinal multi-modules
import '../services/doctrine/anchored_doctrine_base.dart'; // 🕊️ DoctrineContext
import '../widgets/uniform_back_button.dart';
import '../bootstrap.dart' as bootstrap;

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
    _loadUserProfile(); // _fetchPresets() sera appelé dans _loadUserProfile()
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
      // Synchroniser d'abord les deux systèmes
      await UserPrefsSync.syncBidirectional();
      
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
    print('🔍 _userProfile dans _fetchPresets: $_userProfile');
    
    try {
      // Utiliser le générateur enrichi avec apprentissage et adaptation émotionnelle
      final enrichedPresets = await IntelligentLocalPresetGenerator.generateEnrichedPresets(_userProfile ?? {});
      
      if (enrichedPresets.isNotEmpty) {
        print('✅ ${enrichedPresets.length} presets enrichis générés avec adaptation émotionnelle');
        
        // 🧠 ENRICHIR CHAQUE PRESET AVEC DURÉE INTELLIGENTE
        final intelligentPresets = enrichedPresets.map((preset) {
          // ✅ CORRECTION : Utiliser la durée déjà calculée dans le preset au lieu de recalculer
          final presetDuration = preset.durationDays;
          print('🔍 Preset ${preset.name}: durée originale = $presetDuration jours');
          
          // Créer un nouveau preset avec durée préservée
          return PlanPreset(
            slug: preset.slug,
            name: preset.name,
            durationDays: presetDuration,  // ✅ Utiliser la durée déjà calculée
            order: preset.order,
            books: preset.books,
            description: preset.description,
            minutesPerDay: preset.minutesPerDay,
            recommended: preset.recommended,
            // Ajouter les métadonnées de calcul
            parameters: {
              ...preset.parameters ?? {},
              'duration_calculation': {
                'optimal_days': presetDuration,
                'reasoning': 'Durée préservée du générateur intelligent',
                'confidence': 0.9,
                'warnings': [],
                'intensity': 'challenging',
                'behavioral_type': 'habit_formation',
              },
            },
          );
        }).toList();
        
        // Générer les explications pour chaque preset
        final explanations = IntelligentLocalPresetGenerator.explainPresets(intelligentPresets, _userProfile);
        _printPresetExplanations(explanations);
        
        // Afficher les recommandations spirituelles
        final recommendations = IntelligentLocalPresetGenerator.getSpiritualRecommendations();
        _printSpiritualRecommendations(recommendations);
        
        print('🧠 ${intelligentPresets.length} presets enrichis avec durées intelligentes');
        
        // 🕊️ CONVERSION VERS LE FORMAT THEOLOGY GATE V2
        final theologyPresets = PresetTheologyAdapterV2.convertList(intelligentPresets);
        print('🔄 ${theologyPresets.length} presets convertis vers le format TheologyGate V2');
        
        // 🕊️ FILTRAGE DOCTRINAL avec TheologyGate V2 (sans dépendance du profil)
        final doctrinallyFilteredPresets = Theology.TheologyGateV2.select(
          candidates: theologyPresets,
          userProfile: _userProfile, // Optionnel, peut être null
          topN: 12,
          debug: (log) => print('THEO ▶ $log'),
        );
        
        print('🕊️ ${doctrinallyFilteredPresets.length} presets filtrés selon les critères doctrinaux');
        
        // 🔄 CONVERSION RETOUR vers le format original pour l'affichage
        final finalPresets = doctrinallyFilteredPresets.map((theologyPreset) {
          // Trouver le preset original correspondant
          final originalPreset = intelligentPresets.firstWhere(
            (p) => p.slug == theologyPreset.id,
            orElse: () => intelligentPresets.first,
          );
          
          // Enrichir avec les données théologiques
          return originalPreset.copyWith(
            parameters: {
              ...originalPreset.parameters ?? {},
              'theology_gate_v2': {
                'doctrine_score': theologyPreset.focusDoctrineOfChrist ?? 0.0,
                'authority_score': theologyPreset.focusAuthorityOfBible ?? 0.0,
                'gospel_score': theologyPreset.focusGospelOfJesus ?? 0.0,
                'tags': theologyPreset.tags,
                'verse_anchors': theologyPreset.verseAnchors,
              },
            },
          );
        }).toList();
        
        return finalPresets.cast<PlanPreset>();
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
  
  // Les systèmes intelligents travaillent en arrière-plan sans être visibles
  
  /// 🎨 Couleur basée sur le niveau de confiance
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  /// 🕊️ Couleur basée sur le score combiné (Sagesse + Biblique)
  Color _getCombinedScoreColor(double confidence, double biblicalScore) {
    final combinedScore = (confidence + biblicalScore) / 2;
    if (combinedScore >= 0.8) return Colors.green;
    if (combinedScore >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  // Les systèmes intelligents travaillent en arrière-plan sans interface visible
  Future<void> _showIntelligenceDetails(PlanPreset preset) async {
    final durationInfo = preset.parameters?['duration_calculation'] as Map<String, dynamic>?;
    final theologyInfo = preset.parameters?['theology_gate_v2'] as Map<String, dynamic>?;
    
    if (durationInfo == null && theologyInfo == null) return;
    
    final confidence = durationInfo?['confidence'] as double? ?? 0.0;
    final reasoning = durationInfo?['reasoning'] as String? ?? '';
    final warnings = durationInfo?['warnings'] as List<dynamic>? ?? [];
    final intensity = durationInfo?['intensity'] as String? ?? '';
    final behavioralType = durationInfo?['behavioral_type'] as String? ?? '';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            Text(
              'Analyse Spirituelle & Théologique',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🕊️ Scores théologiques
              if (theologyInfo != null) ...[
                _buildTheologyScoreCard('Doctrine de Christ', theologyInfo['doctrine_score'] as double? ?? 0.0, '1Jn 4:1-3'),
                const SizedBox(height: 8),
                _buildTheologyScoreCard('Autorité de la Bible', theologyInfo['authority_score'] as double? ?? 0.0, '2Tm 3:16'),
                const SizedBox(height: 8),
                _buildTheologyScoreCard('Évangile de Jésus', theologyInfo['gospel_score'] as double? ?? 0.0, 'Ga 1:6-9'),
                const SizedBox(height: 12),
              ],
              
              // Niveau de confiance spirituelle
              if (durationInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getConfidenceColor(confidence).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: _getConfidenceColor(confidence), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Confiance Spirituelle: ${(confidence * 100).round()}%',
                        style: GoogleFonts.inter(
                          color: _getConfidenceColor(confidence),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              const SizedBox(height: 16),
              
              // Type comportemental
              if (behavioralType.isNotEmpty) ...[
                Text(
                  'Type comportemental: $behavioralType',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Intensité
              if (intensity.isNotEmpty) ...[
                Text(
                  'Intensité: $intensity',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // 🕊️ Tags et références théologiques
              if (theologyInfo != null) ...[
                ...() {
                  final tags = theologyInfo['tags'] as List<dynamic>? ?? [];
                  final verseAnchors = theologyInfo['verse_anchors'] as List<dynamic>? ?? [];
                  
                  return <Widget>[
                    if (tags.isNotEmpty) ...[
                  Text(
                    'Tags théologiques:',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tags.take(8).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.toString(),
                        style: GoogleFonts.inter(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (verseAnchors.isNotEmpty) ...[
                  Text(
                    'Références bibliques:',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...verseAnchors.take(5).map((verse) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      verse.toString(),
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                  ];
                }(),
              ],
              
              // Raisonnement spirituel
              if (reasoning.isNotEmpty) ...[
                Text(
                  'Raisonnement Spirituel:',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reasoning,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Avertissements
              if (warnings.isNotEmpty) ...[
                Text(
                  'Avertissements:',
                  style: GoogleFonts.inter(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...warnings.map((warning) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 🕊️ Widget pour afficher un score théologique
  Widget _buildTheologyScoreCard(String title, double score, String reference) {
    final percent = (score * 100).round();
    final color = _getConfidenceColor(score);
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  reference,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percent%',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 🧠 Détermine l'objectif basé sur le preset pour le calcul intelligent
  String _getGoalFromPreset(PlanPreset preset) {
    final name = preset.name.toLowerCase();
    
    if (name.contains('nouveau testament') || name.contains('évangiles')) {
      return 'Approfondir la Parole';
    } else if (name.contains('psaumes') || name.contains('prière')) {
      return 'Mieux prier';
    } else if (name.contains('proverbes') || name.contains('sagesse')) {
      return 'Grandir dans la foi';
    } else if (name.contains('toute la bible') || name.contains('bible complète')) {
      return 'Approfondir la Parole';
    } else {
      return 'Discipline quotidienne';
    }
  }




  

  /// Charge le profil utilisateur et applique la logique de personnalisation
  Future<void> _loadUserProfile() async {
    print('🔍 _loadUserProfile() appelé');
    try {
      final profile = context.read<UserPrefsHive>().profile;
      print('🔍 Profile récupéré: $profile');
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
            return const Center(
              child: Text(
                'Aucun plan trouvé.',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: Colors.white70,
                ),
              ),
            );
          }

              final allPresets = snapshot.data!;
              final personalizedPresets = allPresets; // déjà triés par le générateur
              
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
    
    // 🩺 NOUVEAU ! Afficher les raisons de besoin
    final needScores = IntelligentLocalPresetGenerator.getLastNeedScores();
    if (needScores.isNotEmpty) {
      print('🩺 === RAISONS BESOIN (Need Engine) ===');
      needScores.forEach((slug, data) {
        print('- $slug : score=${data['score']}');
        for (final r in (data['reasons'] as List<String>)) {
          print('   • $r');
        }
      });
      print('=====================================\n');
    }
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
          height: 370, // Hauteur du carousel agrandie
          child: FancyStackCarousel(
            items: _carouselItems,
            options: FancyStackCarouselOptions(
              size: const Size(300, 350), // Taille des cartes agrandie
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
        const SizedBox(height: 40), // ✅ Plus d'espace pour décoller des cartes
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
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(PlanPreset preset) {
    final weeks = (preset.durationDays / 7).ceil(); // Convertir en semaines
    print('🔍 _buildPlanCard: ${preset.name} - ${preset.durationDays} jours → $weeks semaines');
    
    // ✅ Couleur intelligente du texte selon la luminosité du fond
    final cardColor = _getCardColorForPreset(preset);
    final textColor = _getIntelligentTextColor(cardColor);
    
    return Hero(
      tag: 'preset_${preset.slug}',
      child: Semantics(
        label: 'Choisir ce plan : ${preset.name}',
        button: true,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween(begin: 1.0, end: 1.0),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                // Juste un feedback visuel, pas d'action
              },
              child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 350, // Hauteur agrandie pour plus d'espace
            // Gradient border effect
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  _getCardColorForPreset(preset).withOpacity(0.8),
                  _getCardColorForPreset(preset).withOpacity(0.6),
                ],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                // Effet Glassmorphism avec gradient
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCardColorForPreset(preset).withOpacity(0.8),
                    _getCardColorForPreset(preset).withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                // Gradient border effect
                border: Border.all(
                  width: 1.5,
                  color: Colors.white.withOpacity(0.2),
                ),
                // ✅ Design épuré sans ombres
              ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Stack(
                  children: [
                // ✅ GRANDE ILLUSTRATION "OBJECTIF SPIRITUEL" derrière le nom (impact visuel)
                Positioned(
                  top: 60, // Position ajustée
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      _getSpiritualGoalIconForPreset(preset), // ✅ Icône de l'objectif spirituel
                      size: 200, // Taille réduite pour éviter le débordement
                      color: textColor.withOpacity(0.08), // ✅ Couleur intelligente avec opacité légèrement plus forte
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
                          color: textColor.withOpacity(0.1), // ✅ Fond adaptatif
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: textColor.withOpacity(0.2), // ✅ Bordure adaptative
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getModernIconForPreset(preset),
                          size: 32, // ✅ Petite icône
                          color: textColor.withOpacity(0.6), // ✅ Couleur intelligente
                        ),
                      ),
                      // ✅ "Recommandé" sous l'icône avec GoalBadge moderne
                      if (_isRecommendedPresetNew(preset)) ...[
                        const SizedBox(height: 6),
                        const GoalBadge(
                          label: 'Recommandé',
                          color: Color(0xFF1553FF),
                          icon: Icons.star_rounded,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final reasons = IntelligentLocalPresetGenerator.explainWhyRecommended(preset.slug, take: 3);
                            if (reasons.isEmpty) return;
                            _showSnackBar(
                              'Pourquoi recommandé :\n• ${reasons.join('\n• ')}',
                              Icons.info_outline,
                              const Color(0xFF1553FF),
                            );
                          },
                          child: Icon(Icons.info_outline, size: 16, color: textColor.withOpacity(0.7)),
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
                      // ✅ Nombre avec largeur contrainte pour ne pas dépasser "semaines"
                      SizedBox(
                        width: 70, // Largeur réduite
                        child: Text(
                          '$weeks',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900, // Heavy
                            fontSize: 48, // ✅ Taille réduite pour éviter l'overflow
                            height: 0.85,
                            color: textColor, // ✅ Couleur intelligente
                            letterSpacing: -2,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center, // ✅ Centré
                          maxLines: 1,
                          overflow: TextOverflow.visible, // ✅ Permet l'overflow si nécessaire
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weeks == 1 ? 'semaine' : 'semaines',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: textColor.withOpacity(0.7), // ✅ Couleur intelligente
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center, // ✅ Centré
                      ),
                    ],
                  ),
                ),
                
                
                // Titre GILROY HEAVY ITALIC + Livres en bas
                Positioned(
                  top: 100, // Position ajustée
                  left: 0, // ✅ Centré
                  right: 0, // ✅ Centré
                  bottom: 70, // Espace réduit pour le bouton
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32), // ✅ Plus de padding pour éviter les bords
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Titre avec gradient text et drop shadow moderne
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                textColor,
                                textColor.withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              _toTitleCase(_getShortNameForPreset(preset)), // ✅ Title Case
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800, // Heavy
                                fontStyle: FontStyle.italic, // ✅ Italic
                                fontSize: 20, // Taille réduite
                                height: 1.1, // ✅ Compact
                                color: Colors.white, // ✅ Blanc pour le shader
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 6,
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ✅ Minutes/jour avec Google Fonts
                          Text(
                            '${_userProfile?['durationMin'] as int? ?? preset.minutesPerDay ?? 15} min/jour',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: textColor, // ✅ Couleur intelligente
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // ✅ BÉNÉFICE PSYCHOLOGIQUE - Ce que l'utilisateur va gagner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              // Fond adaptatif selon la couleur de la carte
                              color: _getIntelligentBenefitBackground(cardColor),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getIntelligentBenefitBorder(cardColor),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getBenefitForPreset(preset),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: _getIntelligentBenefitTextColor(cardColor), // ✅ Couleur adaptée au fond
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ],
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
                
                // Les systèmes intelligents travaillent en arrière-plan
                
                // Bouton "Choisir ce plan" en bas
                Positioned(
                  bottom: 20,
                  left: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await _onPlanSelected(preset);
                    },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: textColor, // ✅ Fond = couleur du texte (inversé)
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.3), // ✅ Ombre adaptative
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Choisir ce plan',
                        style: GoogleFonts.inter(
                          color: cardColor, // ✅ Texte = couleur du fond (inversé)
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                          ),
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
              ),
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_pin_circle,
                    size: 16,
                    color: Color(0xFF49C98D),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Plans personnalisés pour toi',
                    style: TextStyle(
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
          label: const Text(
            'Clique ici si tu veux créer ton propre plan',
            style: TextStyle(
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
        goal.contains('pardon') || goal.contains('guérison') || name.contains('luc') ||
        name.contains('priere') || name.contains('rythme') || name.contains('jesus')) {
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
        goal.contains('partager') || goal.contains('mission') || name.contains('quotidien') ||
        name.contains('temoigner') || name.contains('audace')) {
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
        name.contains('jean') || name.contains('marc') || name.contains('luc') ||
        name.contains('centre') || name.contains('plein')) {
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
  
  /// 🧠 COULEUR INTELLIGENTE DU TEXTE selon la luminosité du fond
  /// Utilise la formule de luminosité relative W3C WCAG 2.0
  /// Retourne BLANC pour fonds foncés, NOIR pour fonds clairs
  /// Amélioré pour glassmorphism avec meilleur contraste
  Color _getIntelligentTextColor(Color backgroundColor) {
    // Calculer la luminosité relative (0.0 = noir, 1.0 = blanc)
    final luminance = backgroundColor.computeLuminance();
    
    // Pour l'effet glassmorphism, utiliser des couleurs avec plus de contraste
    if (luminance > 0.5) {
      // Fond clair → texte très sombre pour meilleur contraste
      return const Color(0xFF1A1A1A);  // Noir profond
    } else {
      // Fond foncé → blanc pur pour maximum de contraste
      return const Color(0xFFFFFFFF);  // Blanc pur
    }
  }

  /// 🎨 FOND INTELLIGENT pour l'encadré du bénéfice selon la couleur de la carte
  Color _getIntelligentBenefitBackground(Color cardColor) {
    final luminance = cardColor.computeLuminance();
    
    if (luminance > 0.5) {
      // Carte claire → fond sombre pour contraste
      return Colors.black.withOpacity(0.8);
    } else {
      // Carte foncée → fond clair pour contraste
      return Colors.white.withOpacity(0.9);
    }
  }

  /// 🎨 BORDURE INTELLIGENTE pour l'encadré du bénéfice
  Color _getIntelligentBenefitBorder(Color cardColor) {
    final luminance = cardColor.computeLuminance();
    
    if (luminance > 0.5) {
      // Carte claire → bordure claire
      return Colors.white.withOpacity(0.3);
    } else {
      // Carte foncée → bordure foncée
      return Colors.black.withOpacity(0.2);
    }
  }

  /// 🎨 TEXTE INTELLIGENT pour l'encadré du bénéfice
  Color _getIntelligentBenefitTextColor(Color cardColor) {
    final luminance = cardColor.computeLuminance();
    
    if (luminance > 0.5) {
      // Carte claire → texte blanc sur fond sombre
      return Colors.white;
    } else {
      // Carte foncée → texte noir sur fond clair
      return Colors.black;
    }
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

  /// Helper pour afficher des SnackBars avec icône et couleur
  void _showSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
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

  /// 🎯 ICÔNE CARTE - Grande illustration derrière le nom basée sur le contenu de la carte
  /// Choisit des icônes qui correspondent au contenu et au thème de la carte elle-même
  IconData _getSpiritualGoalIconForPreset(PlanPreset preset) {
    final name = preset.name.toLowerCase();
    final books = preset.books.toLowerCase();
    
    // 🎯 THÈMES BIBLIQUES SPÉCIFIQUES (basés sur le contenu de la carte)
    if (name.contains('psaumes') || name.contains('psalm') || books.contains('psaumes')) {
      return Icons.music_note_rounded; // 🎵 Louange/Psaumes
    } else if (name.contains('proverbes') || name.contains('proverbs') || books.contains('proverbes')) {
      return Icons.lightbulb_rounded; // 💡 Sagesse/Proverbes
    } else if (name.contains('évangile') || name.contains('gospel') || books.contains('matthieu') || books.contains('marc') || books.contains('luc') || books.contains('jean')) {
      return Icons.menu_book_rounded; // 📖 Évangiles
    } else if (name.contains('actes') || books.contains('actes')) {
      return Icons.rocket_launch_rounded; // 🚀 Mission/Actes
    } else if (name.contains('romains') || books.contains('romains')) {
      return Icons.auto_stories_rounded; // 📚 Doctrine/Romains
    } else if (name.contains('galates') || books.contains('galates')) {
      return Icons.diamond_rounded; // 💎 Liberté/Galates
    } else if (name.contains('éphésiens') || books.contains('éphésiens')) {
      return Icons.star_rounded; // ⭐ Richesse/Éphésiens
    } else if (name.contains('philippiens') || books.contains('philippiens')) {
      return Icons.trending_up_rounded; // 📈 Joie/Philippiens
    } else if (name.contains('colossiens') || books.contains('colossiens')) {
      return Icons.auto_awesome_rounded; // ✨ Christ/Colossiens
    } else if (name.contains('hébreux') || books.contains('hébreux')) {
      return Icons.church_rounded; // 🏛️ Foi/Hébreux
    } else if (name.contains('genèse') || books.contains('genèse')) {
      return Icons.park_rounded; // 🌳 Création/Genèse
    } else if (name.contains('exode') || books.contains('exode')) {
      return Icons.local_fire_department_rounded; // 🔥 Libération/Exode
    } else if (name.contains('ésaïe') || books.contains('ésaïe')) {
      return Icons.visibility_rounded; // 👁️ Prophétie/Ésaïe
    }
    
    // 🎯 THÈMES SPIRITUELS (basés sur le nom de la carte)
    else if (name.contains('prière') || name.contains('prayer') || name.contains('méditation')) {
      return Icons.self_improvement_rounded; // 🧘 Prière/Méditation
    } else if (name.contains('foi') || name.contains('faith')) {
      return Icons.star_rounded; // ⭐ Foi
    } else if (name.contains('sagesse') || name.contains('wisdom')) {
      return Icons.lightbulb_rounded; // 💡 Sagesse
    } else if (name.contains('croissance') || name.contains('growth') || name.contains('grandit')) {
      return Icons.eco_rounded; // 🌱 Croissance
    } else if (name.contains('caractère') || name.contains('character')) {
      return Icons.diamond_rounded; // 💎 Caractère
    } else if (name.contains('amour') || name.contains('love') || name.contains('intimité')) {
      return Icons.favorite_rounded; // ❤️ Amour/Intimité
    } else if (name.contains('pardon') || name.contains('forgiveness')) {
      return Icons.healing_rounded; // 🩹 Pardon/Guérison
    } else if (name.contains('espoir') || name.contains('hope') || name.contains('espérance')) {
      return Icons.wb_sunny_rounded; // ☀️ Espoir
    } else if (name.contains('paix') || name.contains('peace') || name.contains('sérénité')) {
      return Icons.spa_rounded; // 🧘 Paix/Sérénité
    } else if (name.contains('joie') || name.contains('joy') || name.contains('bonheur')) {
      return Icons.emoji_emotions_rounded; // 😊 Joie
    } else if (name.contains('force') || name.contains('strength') || name.contains('puissance')) {
      return Icons.fitness_center_rounded; // 💪 Force
    } else if (name.contains('mission') || name.contains('service') || name.contains('appel')) {
      return Icons.rocket_launch_rounded; // 🚀 Mission/Service
    } else if (name.contains('louange') || name.contains('praise') || name.contains('adoration')) {
      return Icons.music_note_rounded; // 🎵 Louange/Adoration
    } else if (name.contains('bénédiction') || name.contains('blessing') || name.contains('grâce')) {
      return Icons.volunteer_activism_rounded; // 🎁 Bénédiction/Grâce
    } else if (name.contains('nouveau') || name.contains('new') || name.contains('renouveau')) {
      return Icons.refresh_rounded; // 🔄 Nouveau/Renouveau
    } else if (name.contains('gloire') || name.contains('glory') || name.contains('honneur')) {
      return Icons.auto_awesome_rounded; // ✨ Gloire/Honneur
    } else if (name.contains('chemin') || name.contains('path') || name.contains('route')) {
      return Icons.route_rounded; // 🛤️ Chemin/Route
    } else if (name.contains('vie') || name.contains('life') || name.contains('vivant')) {
      return Icons.favorite_rounded; // ❤️ Vie
    } else if (name.contains('arbre') || name.contains('tree') || name.contains('planté')) {
      return Icons.park_rounded; // 🌳 Arbre/Planté
    } else if (name.contains('flamme') || name.contains('feu') || name.contains('zèle')) {
      return Icons.local_fire_department_rounded; // 🔥 Flamme/Feu
    } else if (name.contains('graine') || name.contains('seed') || name.contains('épi')) {
      return Icons.eco_rounded; // 🌱 Graine/Épi
    } else if (name.contains('constance') || name.contains('fidèle') || name.contains('régulier')) {
      return Icons.schedule_rounded; // ⏰ Constance/Fidélité
    } else if (name.contains('contemplation') || name.contains('réflexion')) {
      return Icons.spa_rounded; // 🧘 Contemplation/Réflexion
    }
    
    // 🎯 FALLBACK INTELLIGENT selon la durée et le contenu
    final weeks = (preset.durationDays / 7).ceil();
    if (weeks <= 5) {
      return Icons.bolt_rounded; // ⚡ Court terme
    } else if (weeks <= 10) {
      return Icons.trending_up_rounded; // 📈 Moyen terme
    } else {
      return Icons.emoji_events_rounded; // 🏆 Long terme
    }
  }
  
  /// 📚 NOMS DES LIVRES - Affiche les livres du preset
  String _getBenefitForPreset(PlanPreset preset) {
    // ✅ NOUVEAU : Retourner les noms des livres formatés
    final books = preset.books.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    if (books.isEmpty) {
      return 'Étude biblique';
    }
    
    // Formatage intelligent des noms de livres
    if (books.length == 1) {
      return books.first;
    } else if (books.length == 2) {
      return '${books[0]} & ${books[1]}';
    } else if (books.length == 3) {
      return '${books[0]}, ${books[1]} & ${books[2]}';
    } else {
      // Plus de 3 livres : afficher les 2 premiers + "& autres"
      return '${books[0]}, ${books[1]} & ${books.length - 2} autres';
    }
  }
  
  /// ⭐ Détermine si un preset est "recommandé" (score élevé)
  /// Utilise l'intelligence du générateur pour identifier les meilleurs presets
  bool _isRecommendedPreset(PlanPreset preset) {
    final goal = _userProfile?['goal'] as String? ?? '';
    final level = _userProfile?['level'] as String? ?? '';
    final heartPosture = _userProfile?['heartPosture'] as String? ?? '';
    final name = preset.name.toLowerCase();
    
    // 🎯 SCORE BASÉ SUR L'OBJECTIF SPIRITUEL (nouveau système Christ-centré)
    int score = 0;
    
    // Objectifs Christ-centrés (Jean 5:40) - Score élevé
    if (goal.contains('Rencontrer Jésus') && (name.contains('chemin') || name.contains('arbre') || name.contains('vie'))) {
      score += 3;
    } else if (goal.contains('Voir Jésus') && (name.contains('évangile') || name.contains('gloire'))) {
      score += 3;
    } else if (goal.contains('transformé') && (name.contains('nouveau') || name.contains('gloire') || name.contains('force'))) {
      score += 3;
    } else if (goal.contains('intimité') && (name.contains('arbre') || name.contains('chemin') || name.contains('méditation'))) {
      score += 3;
    } else if (goal.contains('prier') && (name.contains('méditation') || name.contains('psaumes'))) {
      score += 3;
    } else if (goal.contains('voix de Dieu') && (name.contains('méditation') || name.contains('chemin'))) {
      score += 3;
    } else if (goal.contains('fruit de l\'Esprit') && (name.contains('graine') || name.contains('arbre') || name.contains('croître'))) {
      score += 3;
    } else if (goal.contains('Renouveler') && (name.contains('nouveau') || name.contains('force'))) {
      score += 3;
    } else if (goal.contains('Esprit') && (name.contains('force') || name.contains('flamme'))) {
      score += 3;
    }
    
    // Objectifs classiques - Score moyen
    else if (goal.contains('discipline') && (name.contains('croître') || name.contains('grâce'))) {
      score += 2;
    } else if (goal.contains('Approfondir') && name.contains('méditation')) {
      score += 2;
    } else if (goal.contains('foi') && (name.contains('romains') || name.contains('galates'))) {
      score += 2;
    } else if (goal.contains('caractère') && (name.contains('proverbes') || name.contains('galates'))) {
      score += 2;
    }
    
    // 🎯 NOUVEAUX OBJECTIFS DE TÉMOIGNAGE - Score élevé
    else if (goal.contains('Partager ma foi') && (name.contains('témoignage') || name.contains('audace') || name.contains('mission'))) {
      score += 3;
    } else if (goal.contains('Témoigner avec audace') && (name.contains('audace') || name.contains('témoignage') || name.contains('formation'))) {
      score += 3;
    } else if (goal.contains('Évangéliser en ligne') && (name.contains('numérique') || name.contains('en ligne') || name.contains('médias'))) {
      score += 3;
    }
    
    // 💎 POSTURE DU CŒUR - Bonus
    if (heartPosture.contains('Rencontrer Jésus') && (name.contains('chemin') || name.contains('vie'))) {
      score += 2;
    } else if (heartPosture.contains('transformé') && name.contains('gloire')) {
      score += 2;
    } else if (heartPosture.contains('Écouter') && name.contains('méditation')) {
      score += 2;
    } else if (heartPosture.contains('intimité') && name.contains('arbre')) {
      score += 2;
    }
    
    // 📊 NIVEAU SPIRITUEL - Ajustements
    if (level == 'Nouveau converti' && preset.durationDays <= 42) {
      score += 2; // Plans courts pour débutants
    } else if (level == 'Rétrograde' && (name.contains('flamme') || name.contains('nouveau'))) {
      score += 2; // Restauration
    } else if (level == 'Serviteur/leader' && preset.durationDays >= 56) {
      score += 1; // Plans longs pour leaders
    }
    
    // ✅ Un preset est recommandé si score >= 3
    return score >= 3;
  }
  
  /// ⭐ NOUVEAU ! Détermine si un preset est "recommandé" basé sur le besoin réel
  bool _isRecommendedPresetNew(PlanPreset preset) {
    final map = IntelligentLocalPresetGenerator.getLastNeedScores();
    final s = (map[preset.slug]?['score'] as double?) ?? 0;
    return s >= 1.5; // seuil simple: recommandé si besoin identifié
  }




  /// Gère la sélection d'un plan preset (100% OFFLINE avec options complètes)
  Future<void> _onPlanSelected(PlanPreset preset) async {
    HapticFeedback.selectionClick();

    // Note: La vérification "un seul plan actif" est gérée par le router guard
    // Si l'utilisateur arrive ici, c'est qu'il n'a pas de plan actif

    // Les systèmes intelligents travaillent en arrière-plan

    // 1) Options utilisateur (date + jours) via bottom sheet
    final opts = await _showPresetOptionsSheet(
      preset: preset,
      initialStart: DateTime.now(),
    );
    
    if (opts == null) return; // Annulé par l'utilisateur

    // 2) Récupérer minutes/jour depuis le profil utilisateur (UserPrefs)
    final minutesPerDay = _userProfile?['durationMin'] as int? ?? preset.minutesPerDay ?? 15;

    // 3) Génère les passages totalement offline
    var customPassages = _generateOfflinePassagesForPreset(
      preset: preset,
      startDate: opts.startDate,
      minutesPerDay: minutesPerDay, // ← Vient de CompleteProfilePage
      daysOfWeek: opts.daysOfWeek, // 1..7 (lun..dim)
    );

    // 🕊️ La doctrine "Crainte de Dieu" est maintenant intégrée directement dans le moteur de génération
    // Plus besoin de post-traitement - la doctrine structure le plan dès sa création

    // 3) Crée le plan local (100% offline) avec loading
    try {
      // Afficher loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Création de votre plan...'),
                ],
              ),
            ),
          ),
        ),
      );

      final planService = bootstrap.planService;
      
      // 1) Tenter la création
      print('🔒 Création du plan: ${preset.name}');
      final createdPlan = await planService.createLocalPlan(
        name: preset.name,
        totalDays: preset.durationDays,
        startDate: opts.startDate,
        books: preset.books,
        specificBooks: preset.specificBooks,
        minutesPerDay: minutesPerDay,
        customPassages: customPassages,
        daysOfWeek: opts.daysOfWeek,
        userProfile: _userProfile, // ✅ NOUVEAU - Passer le profil pour génération intelligente
      );
      
      print('🔒 Plan créé avec ID: ${createdPlan.id}');

      // 2) Read-back : vérifier existence (précondition dure)
      print('🔒 Vérification read-back...');
      final activePlan = await planService.getActiveLocalPlan();
      if (activePlan == null || activePlan.id != createdPlan.id) {
        print('❌ Read-back échoué: plan non confirmé localement');
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        
        _showSnackBar('Plan non confirmé localement. Réessaie.', Icons.error_outline, Colors.orange);
        return; // ⛔ pas de navigation
      }
      
      print('✅ Read-back réussi: plan confirmé localement');
      print('✅ UserRepository déjà mis à jour par createLocalPlan');

      // Fermer le loading
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // 4) Naviguer (maintenant que l'état est cohérent)
      final hasOnboarded = (_userProfile?['hasOnboarded'] as bool?) ?? false;
      print('🧭 Navigation: hasOnboarded=$hasOnboarded');
      if (!hasOnboarded) {
        print('🧭 Redirection vers /onboarding');
        context.go('/onboarding');
      } else {
        print('🧭 Redirection vers /home');
        context.go('/home');
      }
    } catch (e) {
      print('❌ Erreur création plan local: $e');
      if (!mounted) return;
      
      // Fermer le loading en cas d'erreur
      Navigator.of(context, rootNavigator: true).pop();
      
      _showSnackBar('Création du plan impossible: $e', Icons.error, Colors.red);
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
              const Text(
                'Personnalise ton plan',
                style: TextStyle(
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
                                const Text(
                                  'Date de début',
                                  style: TextStyle(
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
                  const Align(
                    alignment: Alignment.centerLeft,
                  child: Text(
                    'Jours de lecture',
                    style: TextStyle(
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
                          onPressed: () => context.pop(),
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
                            // Retourner les options sélectionnées
                            context.pop(_PresetOptions(
                                startDate: start,
                                daysOfWeek: dow.toList()..sort(),
                            ));
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
  
  /// 🧠 Génération INTELLIGENTE des passages pour un preset (avec frontières sémantiques)
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

    // 1) Récupérer un pool de livres/chapitres selon booksKey
    final chapters = _expandBooksPoolToChapters(booksSource);
    int cursor = 0;

    final result = <Map<String, dynamic>>[];
    DateTime cur = startDate;

    int produced = 0;
    while (produced < targetDays && cursor < chapters.length) {
      // Respect réel du calendrier : sauter les jours non cochés
      final dow = cur.weekday; // 1=Mon..7=Sun
      if (!daysOfWeek.contains(dow)) {
        cur = cur.add(const Duration(days: 1));
        continue; // Passer au jour suivant
      }

      // 🧠 Prend 1 "unité sémantique" par jour (chapitre ou groupe cohérent)
      final unit = _pickSemanticUnit(chapters, cursor);
      cursor = unit.nextCursor;

      result.add({
        'reference': unit.reference,
        'text': unit.annotation ?? 'Lecture de ${unit.reference}',
        'book': chapters[cursor - 1 < 0 ? 0 : cursor - 1].book,
        'theme': _themeForBook(chapters[cursor - 1 < 0 ? 0 : cursor - 1].book),
        'focus': _focusForBook(chapters[cursor - 1 < 0 ? 0 : cursor - 1].book),
        'duration': minutesPerDay,
        'wasAdjusted': unit.wasAdjusted,
        'annotation': unit.annotation,
        'date': cur.toIso8601String(),
      });

      produced++;
      cur = cur.add(const Duration(days: 1));
    }

    print('📖 ${result.length} passages générés offline (INTELLIGENTS) pour "${preset.name}"');
    print('📅 Jours sélectionnés: ${daysOfWeek.join(',')} → Plan respecte le calendrier réel');
    
    // 🕊️ INTÉGRATION DOCTRINALE - Application du pipeline doctrinal modulaire
    final ctx = DoctrineContext(userProfile: _userProfile, minutesPerDay: minutesPerDay);
    final pipeline = DoctrinePipeline.defaultModules();
    final withDoctrine = pipeline.apply(result, context: ctx);
    
    print('🕊️ Plan structuré par le pipeline doctrinal modulaire');
    return withDoctrine;
  }

  
  /// 🚀 FALCON X - Sélection ultra-intelligente d'unités sémantiques
  _SemanticPick _pickSemanticUnit(List<_ChapterRef> chapters, int cursor) {
    if (cursor >= chapters.length) {
      return _SemanticPick('Psaume 1', cursor + 1);
    }

    final c = chapters[cursor];
    
    // 🚀 ÉTAPE 1: Chercher une unité sémantique CRITICAL ou HIGH qui commence ici
    final unit = SemanticPassageBoundaryService.findUnitContaining(c.book, c.chapter);
    
    if (unit != null && 
        unit.startChapter == c.chapter &&
        (unit.priority == UnitPriority.critical || unit.priority == UnitPriority.high)) {
      
      // Vérifier qu'on a assez de chapitres restants pour l'unité complète
      final chaptersNeeded = unit.length;
      final chaptersAvailable = chapters.length - cursor;
      
      if (chaptersAvailable >= chaptersNeeded) {
        // Vérifier que tous les chapitres suivants font partie de cette unité
        bool allMatch = true;
        for (int i = 1; i < chaptersNeeded; i++) {
          if (cursor + i >= chapters.length) {
            allMatch = false;
            break;
          }
          final nextChap = chapters[cursor + i];
          if (nextChap.book != c.book || nextChap.chapter != c.chapter + i) {
            allMatch = false;
            break;
          }
        }
        
        if (allMatch) {
          // ✅ Utiliser l'unité sémantique complète
          return _SemanticPick(
            unit.reference,
            cursor + chaptersNeeded,
            wasAdjusted: true,
            annotation: unit.annotation ?? unit.name,
          );
        }
      }
    }
    
    // 🎨 ÉTAPE 2: Pas d'unité critique, mais peut-être une annotation utile
    if (unit != null && unit.priority == UnitPriority.medium) {
      // Donner l'annotation mais ne pas forcer le groupement
      return _SemanticPick(
        '${c.book} ${c.chapter}',
        cursor + 1,
        wasAdjusted: false,
        annotation: unit.annotation,
      );
    }

    // 📖 ÉTAPE 3: Défaut - 1 chapitre avec annotation si disponible
    final annotation = SemanticPassageBoundaryService.getAnnotationForChapter(c.book, c.chapter);
    return _SemanticPick(
      '${c.book} ${c.chapter}',
      cursor + 1,
      wasAdjusted: false,
      annotation: annotation,
    );
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
  
  /// 🧠 Expand books pool vers chapitres (pour génération intelligente)
  List<_ChapterRef> _expandBooksPoolToChapters(String booksSource) {
    if (booksSource.contains(',')) {
      final books = booksSource.split(',').map((b) => b.trim()).toList();
      final allChapters = <_ChapterRef>[];
      for (final book in books) {
        allChapters.addAll(_expandBooksPoolToChapters(book));
      }
      return allChapters;
    }
    
    // Expansion des catégories
    if (booksSource == 'NT') {
      return _ntChapters();
    } else if (booksSource == 'OT') {
      return _otChapters();
    } else if (booksSource == 'Gospels') {
      return _gospelsChapters();
    } else if (booksSource == 'Psaumes' || booksSource == 'Psalms') {
      return List.generate(150, (i) => _ChapterRef('Psaumes', i + 1));
    } else if (booksSource == 'Proverbes' || booksSource == 'Proverbs') {
      return List.generate(31, (i) => _ChapterRef('Proverbes', i + 1));
    } else if (booksSource == 'Matthieu') {
      return List.generate(28, (i) => _ChapterRef('Matthieu', i + 1));
    } else if (booksSource == 'Marc') {
      return List.generate(16, (i) => _ChapterRef('Marc', i + 1));
    } else if (booksSource == 'Luc') {
      return List.generate(24, (i) => _ChapterRef('Luc', i + 1));
    } else if (booksSource == 'Jean') {
      return List.generate(21, (i) => _ChapterRef('Jean', i + 1));
    } else if (booksSource == 'Romains') {
      return List.generate(16, (i) => _ChapterRef('Romains', i + 1));
    } else if (booksSource == 'Galates') {
      return List.generate(6, (i) => _ChapterRef('Galates', i + 1));
    } else if (booksSource == 'Éphésiens') {
      return List.generate(6, (i) => _ChapterRef('Éphésiens', i + 1));
    } else if (booksSource == 'Philippiens') {
      return List.generate(4, (i) => _ChapterRef('Philippiens', i + 1));
    }
    
    // Fallback: retourner 1 chapitre
    return [_ChapterRef(booksSource, 1)];
  }
  
  /// Chapitres des Évangiles
  List<_ChapterRef> _gospelsChapters() => [
    ...List.generate(28, (i) => _ChapterRef('Matthieu', i + 1)),
    ...List.generate(16, (i) => _ChapterRef('Marc', i + 1)),
    ...List.generate(24, (i) => _ChapterRef('Luc', i + 1)),
    ...List.generate(21, (i) => _ChapterRef('Jean', i + 1)),
  ];
  
  /// Chapitres du Nouveau Testament
  List<_ChapterRef> _ntChapters() => [
    ..._gospelsChapters(),
    ...List.generate(28, (i) => _ChapterRef('Actes', i + 1)),
    ...List.generate(16, (i) => _ChapterRef('Romains', i + 1)),
    ...List.generate(6, (i) => _ChapterRef('Galates', i + 1)),
    ...List.generate(6, (i) => _ChapterRef('Éphésiens', i + 1)),
    ...List.generate(4, (i) => _ChapterRef('Philippiens', i + 1)),
  ];
  
  /// Chapitres de l'Ancien Testament
  List<_ChapterRef> _otChapters() => [
    ...List.generate(50, (i) => _ChapterRef('Genèse', i + 1)),
    ...List.generate(40, (i) => _ChapterRef('Exode', i + 1)),
    ...List.generate(150, (i) => _ChapterRef('Psaumes', i + 1)),
    ...List.generate(31, (i) => _ChapterRef('Proverbes', i + 1)),
    ...List.generate(66, (i) => _ChapterRef('Ésaïe', i + 1)),
  ];
}

/// 📖 Classe helper pour référence de chapitre
class _ChapterRef {
  final String book;
  final int chapter;
  
  _ChapterRef(this.book, this.chapter);
}

/// 🧠 Classe helper pour unité sémantique
class _SemanticPick {
  final String reference;
  final int nextCursor;
  final bool wasAdjusted;
  final String? annotation;
  
  _SemanticPick(
    this.reference,
    this.nextCursor, {
    this.wasAdjusted = false,
    this.annotation,
  });
}

/// 🏷️ Composant GoalBadge modulaire pour badges modernes
class GoalBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const GoalBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}