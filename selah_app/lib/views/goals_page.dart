import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fancy_stack_carousel/fancy_stack_carousel.dart';
import '../models/plan_preset.dart';
import '../services/plan_presets_repo.dart';
import '../services/user_prefs_hive.dart';
import '../services/plan_service.dart';
import 'package:provider/provider.dart';
import '../services/dynamic_preset_generator.dart';
import '../services/intelligent_duration_calculator.dart';
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
  


  /// Obtient le texte CTA selon le niveau utilisateur
  String _getCtaTextForUserLevel() {
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    
    switch (level) {
      case 'Nouveau converti':
        return 'Commencer ici';
      case 'Serviteur/leader':
        return 'Déployer ce plan';
      default:
        return 'Choisir ce plan';
    }
  }


  

  /// Charge le profil utilisateur et applique la logique de personnalisation
  Future<void> _loadUserProfile() async {
    try {
      final profile = context.read<UserPrefsHive>().profile;
      final level = profile['level'] as String? ?? 'Nouveau converti';
      final goal = profile['goal'] as String? ?? 'Discipline quotidienne';

      setState(() {
        _userProfile = profile;
        _showBeginnerTracks = level == 'Nouveau converti';
        _userGoal = goal;
      });
      
      // Recharger les presets avec la personnalisation
      _presetsFuture = _fetchPresets();
    } catch (e) {
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
        const SizedBox(height: 20),
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
      onBackPressed: () => Navigator.pushReplacementNamed(context, '/complete_profile'),
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
        print('  • ${r.label}: ${sign}${r.weight.toStringAsFixed(2)} — ${r.detail}');
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
    return SizedBox(
      height: 300, // Hauteur du carousel agrandie
      child: FancyStackCarousel(
        items: _carouselItems,
        options: FancyStackCarouselOptions(
          size: const Size(280, 340), // Taille des cartes agrandie
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
            height: 280, // Hauteur agrandie
      decoration: BoxDecoration(
              gradient: _getGradientForPreset(preset),
              borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
                  color: Colors.black.withOpacity(0.15), // Ombre réduite
                  blurRadius: 8, // Blur réduit
                  offset: const Offset(0, 4), // Offset réduit
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Contenu principal
              Padding(
                    padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                        // Icône moderne de swipe en haut
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(.25)),
                      ),
                      child: const Icon(
                        Icons.swipe_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                        ),
                        
                        const SizedBox(height: 12), // Espacement réduit
                        
                        // Nom du plan centré avec typographie améliorée
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                      preset.name,
                                style: GoogleFonts.roboto(
                        color: Colors.white,
                                  fontSize: 16, // Taille de police réduite pour Android
                        fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: 0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3), // Ombre réduite
                                      offset: const Offset(0, 1), // Offset réduit
                                      blurRadius: 2, // Blur réduit
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3, // Réduire à 3 lignes
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        
                        // Détails en bas (jours et temps calculés intelligemment)
                    Text(
                      _formatDurationDisplay(preset),
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                          textAlign: TextAlign.center,
                    ),
                        
                        const SizedBox(height: 6),
                        
                    // Livres spécifiques et généraux
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          // Livres spécifiques (priorité)
                    if (preset.specificBooks != null) ...[
                      Text(
                        'Livres: ${preset.specificBooks}',
                        style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                              textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                            if (preset.books.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Catégorie: ${_formatBooksForDisplay(preset.books)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(.65),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                    ] else ...[
                            // Fallback: seulement les livres généraux
                      Text(
                        'Livres: ${_formatBooksForDisplay(preset.books)}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(.75),
                                fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                        
                        const SizedBox(height: 10), // Espacement réduit
                        
                    // CTA adapté au niveau utilisateur
                    Container(
                      height: 36, // Hauteur du bouton réduite
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _getCtaTextForUserLevel(),
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
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    final goal = _userProfile?['goal'] as String? ?? 'Discipline quotidienne';
    
    final content = _getDynamicContentForLevel(level, goal);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            content.title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            content.subtitle,
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
                    'Plans personnalisés pour toi',
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
            Navigator.pushNamed(context, '/custom_plan');
          },
          icon: const Icon(Icons.tune_rounded, size: 24, color: Colors.white),
          label: Text(
            'Clique ici si tu veux créer ton propre plan',
            style: GoogleFonts.inter(
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



  LinearGradient _getGradientForPreset(PlanPreset preset) {
    // Utiliser le gradient personnalisé du preset s'il existe
    if (preset.gradient != null && preset.gradient!.length >= 2) {
      return LinearGradient(
        colors: preset.gradient!,
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    }
    
    // Générer des gradients basés sur le contenu du nom pour plus de variété
    final name = preset.name.toLowerCase();
    
    // Gradients inspirés des thèmes spirituels
    if (name.contains('prière') || name.contains('prayer')) {
      return const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('sagesse') || name.contains('wisdom') || name.contains('proverbes')) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('foi') || name.contains('faith') || name.contains('romains')) {
      return const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('croissance') || name.contains('growth') || name.contains('philippiens')) {
      return const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF6EE7B7)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('pardon') || name.contains('forgiveness') || name.contains('luc')) {
      return const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('espoir') || name.contains('hope') || name.contains('pierre')) {
      return const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('caractère') || name.contains('character') || name.contains('galates')) {
      return const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('mission') || name.contains('actes')) {
      return const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('psaumes') || name.contains('psalm')) {
      return const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFFB923C)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    } else if (name.contains('évangile') || name.contains('gospel') || name.contains('matthieu') || name.contains('jean')) {
      return const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF34D399)],
        begin: Alignment.topLeft, 
        end: Alignment.bottomRight,
      );
    }
    
    // Gradients par défaut basés sur le slug
    switch (preset.slug) {
      case 'nt_90':
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      case 'bible_180':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      case 'proverbs_31':
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      case 'psalms_40':
        return const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        );
      default:
        // Gradient aléatoire basé sur l'index pour plus de variété
        final gradients = [
          const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)]),
          const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF67E8F9)]),
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
          const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
          const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
          const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
          const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
        ];
        return gradients[preset.slug.hashCode % gradients.length];
    }
  }

  /// Formate l'affichage de la durée avec temps choisi et jours calculés
  String _formatDurationDisplay(PlanPreset preset) {
    final durationDays = preset.durationDays;
    final dailyMinutes = preset.minutesPerDay ?? _getEstimatedTime(preset);
    
    // Calculer le temps total
        final totalMinutes = durationDays * int.parse(dailyMinutes.toString());
    final totalHours = totalMinutes / 60;
    
    // Formater selon la durée totale
    String totalTimeDisplay;
    if (totalHours < 1) {
      totalTimeDisplay = '${totalMinutes}min total';
    } else if (totalHours < 24) {
      totalTimeDisplay = '${totalHours.toStringAsFixed(1)}h total';
    } else {
      final totalDays = totalHours / 24;
      totalTimeDisplay = '${totalDays.toStringAsFixed(1)}j total';
    }
    
    return '$durationDays jours • ${dailyMinutes}min/jour • $totalTimeDisplay';
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



  /// Gère la sélection d'un plan preset
  Future<void> _onPlanSelected(PlanPreset preset) async {
    try {
      final startDate = await _showDatePickerDialog(preset);
      if (startDate == null) return;

      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      final planService = context.read<PlanService>();
      final profile = context.read<UserPrefsHive>().profile;

      try {
        // ⚡ Tentative de création côté serveur
      await planService.createFromPreset(
        presetSlug: preset.slug,
        startDate: startDate,
        profile: profile,
      );
      } catch (e) {
        // Si échec en ligne, créer un plan local
        print('Création en ligne échouée: $e');
        print('Création d\'un plan local pour le preset: ${preset.name}');
        
        // Créer un plan local basé sur le preset
        await _createLocalPlanFromPreset(preset, startDate);
      }

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan "${preset.name}" créé avec succès.'),
          backgroundColor: Colors.green,
        ));
      }

        Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Crée un plan local basé sur un preset intelligent
  Future<void> _createLocalPlanFromPreset(PlanPreset preset, DateTime startDate) async {
    final planService = context.read<PlanService>();
    
    // Générer des passages personnalisés basés sur le preset intelligent
    final customPassages = _generateIntelligentPassages(preset);
    
    // Créer un plan local avec passages personnalisés
    await planService.createLocalPlan(
      name: preset.name,
      totalDays: preset.durationDays,
      startDate: startDate,
      books: preset.books,
      specificBooks: preset.specificBooks,
      minutesPerDay: preset.minutesPerDay ?? 15,
      customPassages: customPassages,
    );
    
    print('✅ Plan local intelligent créé: ${preset.name} (${preset.durationDays} jours)');
    print('📚 Passages générés: ${customPassages.length} passages personnalisés');
  }

  /// Génère des passages intelligents basés sur les informations du preset, la durée utilisateur et la science comportementale
  List<Map<String, dynamic>> _generateIntelligentPassages(PlanPreset preset) {
    final passages = <Map<String, dynamic>>[];
    
    // Récupérer la durée choisie par l'utilisateur
    final userDurationMin = _userProfile?['durationMin'] as int? ?? 15;
    
    // Calculer la durée optimale avec le calculateur intelligent pour validation
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    final goal = _userProfile?['goal'] as String? ?? 'Discipline quotidienne';
    final meditationType = _userProfile?['meditation'] as String? ?? 'Méditation biblique';
    
    final durationCalculation = IntelligentDurationCalculator.calculateOptimalDuration(
      goal: goal,
      level: level,
      dailyMinutes: userDurationMin,
      meditationType: meditationType,
    );
    
    print('🧠 Génération de passages avec science comportementale:');
    print('   📊 Durée optimale calculée: ${durationCalculation.optimalDays} jours');
    print('   🔬 Base scientifique: ${durationCalculation.behavioralType}');
    print('   💡 Raisonnement: ${durationCalculation.reasoning}');
    
    // Priorité 1: Utiliser les livres spécifiques du preset s'ils existent
    if (preset.specificBooks != null && preset.specificBooks!.isNotEmpty) {
      return _generatePassagesFromSpecificBooks(preset.specificBooks!, preset.durationDays, userDurationMin);
    }
    
    // Priorité 2: Analyser le nom du preset pour extraire les informations
    final name = preset.name.toLowerCase();
    
    // Générer des passages selon le thème du preset
    if (name.contains('philippiens')) {
      for (int i = 1; i <= preset.durationDays; i++) {
        final chapter = ((i - 1) % 4) + 1; // Philippiens a 4 chapitres
        passages.add({
          'reference': 'Philippiens $chapter:${((i - 1) % 10) + 1}-${((i - 1) % 10) + 5}',
          'text': 'Lecture de Philippiens - Chapitre $chapter - Jour $i',
          'book': 'Philippiens',
          'theme': 'Joie en Christ',
          'focus': 'Paix et contentement',
        });
      }
    } else if (name.contains('colossiens')) {
      for (int i = 1; i <= preset.durationDays; i++) {
        final chapter = ((i - 1) % 4) + 1; // Colossiens a 4 chapitres
        passages.add({
          'reference': 'Colossiens $chapter:${((i - 1) % 10) + 1}-${((i - 1) % 10) + 5}',
          'text': 'Lecture de Colossiens - Chapitre $chapter - Jour $i',
          'book': 'Colossiens',
          'theme': 'Plénitude en Christ',
          'focus': 'Supériorité de Christ',
        });
      }
    } else if (name.contains('éphésiens')) {
      for (int i = 1; i <= preset.durationDays; i++) {
        final chapter = ((i - 1) % 6) + 1; // Éphésiens a 6 chapitres
        passages.add({
          'reference': 'Éphésiens $chapter:${((i - 1) % 10) + 1}-${((i - 1) % 10) + 5}',
          'text': 'Lecture d\'Éphésiens - Chapitre $chapter - Jour $i',
          'book': 'Éphésiens',
          'theme': 'Église corps de Christ',
          'focus': 'Unité et amour',
        });
      }
    } else if (name.contains('romains')) {
      for (int i = 1; i <= preset.durationDays; i++) {
        final chapter = ((i - 1) % 16) + 1; // Romains a 16 chapitres
        passages.add({
          'reference': 'Romains $chapter:${((i - 1) % 10) + 1}-${((i - 1) % 10) + 5}',
          'text': 'Lecture de Romains - Chapitre $chapter - Jour $i',
          'book': 'Romains',
          'theme': 'Justification par la foi',
          'focus': 'Salut et grâce',
        });
      }
    } else if (name.contains('évangiles') || name.contains('matthieu') || name.contains('jean')) {
      final gospels = ['Matthieu', 'Marc', 'Luc', 'Jean'];
      for (int i = 1; i <= preset.durationDays; i++) {
        final gospel = gospels[((i - 1) % gospels.length)];
        final chapter = ((i - 1) % 28) + 1;
        passages.add({
          'reference': '$gospel $chapter:${((i - 1) % 10) + 1}-${((i - 1) % 10) + 5}',
          'text': 'Évangile selon $gospel - Chapitre $chapter - Jour $i',
          'book': gospel,
          'theme': 'Vie de Jésus',
          'focus': 'Paroles et miracles',
        });
      }
    } else {
      // Fallback: utiliser les livres spécifiés dans le preset
      final bookList = preset.specificBooks?.split(',') ?? preset.books.split(',');
      for (int i = 1; i <= preset.durationDays; i++) {
        final book = bookList[((i - 1) % bookList.length)].trim();
        passages.add({
          'reference': '$book ${((i - 1) % 30) + 1}:1-10',
          'text': 'Lecture de $book - Jour $i',
          'book': book,
          'theme': 'Méditation biblique',
          'focus': 'Croissance spirituelle',
        });
      }
    }
    
    return passages;
  }

  /// Génère des passages à partir des livres spécifiques du preset avec durée adaptative
  List<Map<String, dynamic>> _generatePassagesFromSpecificBooks(String specificBooks, int durationDays, int userDurationMin) {
    final passages = <Map<String, dynamic>>[];
    
    // Récupérer les informations du profil pour enrichir la génération
    final level = _userProfile?['level'] as String? ?? 'Fidèle régulier';
    final goal = _userProfile?['goal'] as String? ?? 'Discipline quotidienne';
    
    print('📚 Génération de passages spécifiques avec adaptation comportementale:');
    print('   📖 Livres: $specificBooks');
    print('   ⏱️ Durée: $durationDays jours, ${userDurationMin}min/jour');
    print('   🎯 Objectif: $goal');
    print('   👤 Niveau: $level');
    
    // Parser les livres spécifiques (ex: "Jean & Luc (Jean 3:16, Luc 19:10)")
    final bookPattern = RegExp(r'([^&(]+)(?:&([^&(]+))?');
    final versePattern = RegExp(r'\(([^)]+)\)');
    
    final bookMatch = bookPattern.firstMatch(specificBooks);
    final verseMatch = versePattern.firstMatch(specificBooks);
    
    if (bookMatch != null) {
      final book1 = bookMatch.group(1)?.trim() ?? '';
      final book2 = bookMatch.group(2)?.trim() ?? '';
      
      // Extraire les versets de référence
      final verseRefs = <String>[];
      if (verseMatch != null) {
        final verseText = verseMatch.group(1) ?? '';
        verseRefs.addAll(verseText.split(',').map((v) => v.trim()));
      }
      
      // Calculer la longueur de lecture selon la durée utilisateur
      final readingLength = _calculateAdaptiveReadingLength(userDurationMin, book1, book2);
      
      // Générer des passages pour chaque jour
      for (int i = 1; i <= durationDays; i++) {
        // Alterner entre les livres
        final currentBook = (i % 2 == 1) ? book1 : (book2.isNotEmpty ? book2 : book1);
        
        // Générer des références de chapitres et versets adaptatifs
        final chapter = ((i - 1) % 30) + 1;
        final startVerse = ((i - 1) % 10) + 1;
        final endVerse = startVerse + readingLength[currentBook.toLowerCase()]!;
        
        passages.add({
          'reference': '$currentBook $chapter:$startVerse-$endVerse',
          'text': 'Lecture de $currentBook - Chapitre $chapter - Jour $i (${userDurationMin} min)',
          'book': currentBook,
          'theme': _getThemeForBook(currentBook),
          'focus': _getFocusForBook(currentBook),
          'verseRefs': verseRefs.isNotEmpty ? verseRefs : null,
          'duration': userDurationMin,
          'estimatedVerses': readingLength[currentBook.toLowerCase()],
        });
      }
    }
    
    return passages;
  }

  /// Retourne le thème spirituel pour un livre biblique
  String _getThemeForBook(String book) {
    final bookLower = book.toLowerCase();
    if (bookLower.contains('philippiens')) return 'Joie en Christ';
    if (bookLower.contains('colossiens')) return 'Plénitude en Christ';
    if (bookLower.contains('éphésiens')) return 'Église corps de Christ';
    if (bookLower.contains('romains')) return 'Justification par la foi';
    if (bookLower.contains('jean')) return 'Amour de Dieu';
    if (bookLower.contains('matthieu')) return 'Royaume des cieux';
    if (bookLower.contains('luc')) return 'Salut universel';
    if (bookLower.contains('marc')) return 'Évangile du serviteur';
    if (bookLower.contains('psaumes')) return 'Louange et adoration';
    if (bookLower.contains('proverbes')) return 'Sagesse divine';
    return 'Méditation biblique';
  }

  /// Retourne le focus spirituel pour un livre biblique
  String _getFocusForBook(String book) {
    final bookLower = book.toLowerCase();
    if (bookLower.contains('philippiens')) return 'Paix et contentement';
    if (bookLower.contains('colossiens')) return 'Supériorité de Christ';
    if (bookLower.contains('éphésiens')) return 'Unité et amour';
    if (bookLower.contains('romains')) return 'Salut et grâce';
    if (bookLower.contains('jean')) return 'Vie éternelle';
    if (bookLower.contains('matthieu')) return 'Enseignements de Jésus';
    if (bookLower.contains('luc')) return 'Compassion divine';
    if (bookLower.contains('marc')) return 'Ministère de Jésus';
    if (bookLower.contains('psaumes')) return 'Relation avec Dieu';
    if (bookLower.contains('proverbes')) return 'Vie pratique';
    return 'Croissance spirituelle';
  }

  /// Calcule la longueur de lecture adaptative selon la durée et le type de livre
  Map<String, int> _calculateAdaptiveReadingLength(int durationMin, String book1, String book2) {
    // Estimation : 1 minute = 2-3 versets moyens selon le type de livre
    final versesPerMinute = 2.5;
    final baseVerses = (durationMin * versesPerMinute).round();
    
    // Ajustements selon le type de livre
    final book1Lower = book1.toLowerCase();
    final book2Lower = book2.toLowerCase();
    
    final result = <String, int>{};
    
    // Calcul pour le premier livre
    if (book1Lower.contains('philippiens') || book1Lower.contains('colossiens') || book1Lower.contains('éphésiens')) {
      result[book1Lower] = _clampVerses(baseVerses, 6, 25); // Épîtres courtes
    } else if (book1Lower.contains('romains')) {
      result[book1Lower] = _clampVerses(baseVerses, 8, 30); // Romains plus dense
    } else if (book1Lower.contains('psaumes')) {
      result[book1Lower] = _clampVerses(baseVerses, 4, 20); // Psaumes courts
    } else if (book1Lower.contains('proverbes')) {
      result[book1Lower] = _clampVerses(baseVerses, 5, 25); // Proverbes courts
    } else {
      result[book1Lower] = _clampVerses(baseVerses, 6, 30); // Défaut
    }
    
    // Calcul pour le deuxième livre (si différent)
    if (book2.isNotEmpty && book2Lower != book1Lower) {
      if (book2Lower.contains('philippiens') || book2Lower.contains('colossiens') || book2Lower.contains('éphésiens')) {
        result[book2Lower] = _clampVerses(baseVerses, 6, 25);
      } else if (book2Lower.contains('romains')) {
        result[book2Lower] = _clampVerses(baseVerses, 8, 30);
      } else if (book2Lower.contains('psaumes')) {
        result[book2Lower] = _clampVerses(baseVerses, 4, 20);
      } else if (book2Lower.contains('proverbes')) {
        result[book2Lower] = _clampVerses(baseVerses, 5, 25);
      } else {
        result[book2Lower] = _clampVerses(baseVerses, 6, 30);
      }
    }
    
    return result;
  }

  /// Limite le nombre de versets dans une plage raisonnable
  int _clampVerses(int verses, int min, int max) {
    return verses.clamp(min, max);
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
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sélectionner une date',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
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
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedDate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Créer le plan',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                  ),
                ),
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
            style: GoogleFonts.inter(
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