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
import '../services/intelligent_local_preset_generator.dart';
import '../widgets/uniform_back_button.dart';

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
      height: 280, // Hauteur du carousel encore plus réduite
      child: FancyStackCarousel(
        items: _carouselItems,
        options: FancyStackCarouselOptions(
          size: const Size(260, 320), // Hauteur des cartes encore plus réduite
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
            height: 260, // Hauteur réduite pour s'adapter au carousel
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
                            child: Text(
                      preset.name,
                              style: GoogleFonts.roboto(
                        color: Colors.white,
                                fontSize: 20, // Taille de police réduite
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
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        
                        // Détails en bas (jours et temps)
                    Text(
                      '${preset.durationDays} jours • ${_getEstimatedTime(preset)} min/jour',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                          textAlign: TextAlign.center,
                    ),
                        
                        const SizedBox(height: 6),
                        
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
                            textAlign: TextAlign.center,
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
                            textAlign: TextAlign.center,
                      ),
                    ],
                        
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

      // ⚡ super-intelligente côté serveur : preset + profil
      await planService.createFromPreset(
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

        Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        // Gestion d'erreur améliorée pour le mode offline-first
        String errorMessage = 'Impossible de créer le plan pour le moment.';
        
        if (e.toString().contains('Failed to fetch')) {
          errorMessage = 'Mode hors ligne : Le plan sera créé localement.';
        } else if (e.toString().contains('ClientException')) {
          errorMessage = 'Connexion requise pour synchroniser le plan.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Continuer',
              textColor: Colors.white,
              onPressed: () {
                // Navigation vers l'onboarding même en cas d'erreur
                Navigator.pushReplacementNamed(context, '/onboarding');
              },
            ),
          ),
        );
        
        // Navigation automatique après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        });
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