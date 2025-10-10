import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../services/plan_service.dart';
import '../services/onboarding_actions.dart';
import '../services/user_prefs_hive.dart';
import '../services/sync_queue_hive.dart';
import '../services/telemetry_console.dart';
import '../features/onboarding/onboarding_vm.dart';
import '../repositories/user_repository.dart';
import '../bootstrap.dart' as bootstrap;

class OnboardingDynamicPage extends StatelessWidget {
  const OnboardingDynamicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeOnboardingVM(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final vm = snapshot.data!;
        return ChangeNotifierProvider.value(
          value: vm,
          child: const _OnboardingView(),
        );
      },
    );
  }
  
  Future<OnboardingVM> _initializeOnboardingVM(BuildContext context) async {
    try {
      // 🔒 PRÉCONDITION : Vérifier qu'un plan actif existe
      print('🔒 OnboardingDynamicPage: Vérification précondition plan...');
      final plans = bootstrap.planService;
      final activePlan = await plans.getActiveLocalPlan();
      
      if (activePlan == null) {
        print('❌ OnboardingDynamicPage: Aucun plan actif trouvé - redirection vers /goals');
        // Sécurité de ceinture et bretelles
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucun plan actif. Reprends la sélection.'),
                backgroundColor: Colors.orange,
              ),
            );
            context.go('/goals');
          }
        });
        throw 'Plan manquant'; // pour interrompre le FutureBuilder
      }
      
      print('✅ OnboardingDynamicPage: Plan actif confirmé: ${activePlan.id}');

      // Essayer d'obtenir les providers, sinon créer des instances par défaut
      UserPrefsHive prefs;
      
      try {
        prefs = Provider.of<UserPrefsHive>(context, listen: false);
      } catch (e) {
        print('🎯 OnboardingDynamicPage: UserPrefsHive non disponible, création d\'instance par défaut');
        // Créer des instances par défaut
        final prefsBox = await Hive.openBox('prefs');
        prefs = UserPrefsHive(prefsBox);
      }
      
      final vm = OnboardingVM(prefs: prefs, plans: plans);
      await vm.load();
      return vm;
    } catch (e) {
      print('🎯 OnboardingDynamicPage: Erreur initialisation: $e');
      rethrow;
    }
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _page = PageController();
  int _index = 0;
  OnboardingVM? _vm;

  @override
  void initState() {
    super.initState();
    _initializeVM();
  }

  Future<void> _initializeVM() async {
    try {
      final prefs = bootstrap.userPrefs;
      final planService = bootstrap.planService;
      _vm = OnboardingVM(prefs: prefs, plans: planService);
      await _vm!.load();
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Erreur initialisation OnboardingVM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    print('🎯 OnboardingDynamicPage: loading=${_vm!.loading}, error=${_vm!.error}, cards=${_vm!.cards.length}');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0B1025), Color(0xFF1C1740), Color(0xFF2D1B69)],
            stops: [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: _vm!.loading
              ? _Loader(onRetry: () => _vm!.load())
              : _vm!.error != null
                  ? _ErrorState(
                      message: 'Impossible de charger les infos.',
                      onRetry: () => _vm!.load(),
                    )
                  : Column(
                      children: [
                        _MeditationBanner(), // bandeau "appli de méditation"
                        Expanded(
                          child: PageView.builder(
                            controller: _page,
                            itemCount: _vm!.cards.length,
                            onPageChanged: (i) => setState(() => _index = i),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (_, i) => _SlideCard(card: _vm!.cards[i], index: i),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Dots(count: _vm!.cards.length, index: _index),
                        const SizedBox(height: 16),
                        _BottomCTA(
                          isLast: _index == _vm!.cards.length - 1,
                          onNext: () {
                            if (_index == _vm!.cards.length - 1) {
                              _finishOnboarding();
                            } else {
                              _page.nextPage(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    try {
      print('🎯 _finishOnboarding: Début');
      
      // Utiliser bootstrap au lieu des providers
      final prefs = bootstrap.userPrefs;
      final queue = bootstrap.syncQueue;
      final telemetry = bootstrap.telemetry;

      print('🎯 _finishOnboarding: Services récupérés');

      // Mettre à jour LOCAL STORAGE directement (pour le router)
      final userRepo = UserRepository();
      await userRepo.markOnboardingComplete();
      print('🎯 _finishOnboarding: LocalStorage mis à jour');
      
      // Forcer le rafraîchissement du router
      if (mounted) {
        context.go('/congrats');
        return;
      }

      // Mettre à jour UserPrefsHive aussi (pour cohérence)
      await prefs.setHasOnboarded(true);
      telemetry.event('onboarding_completed');

      print('🎯 _finishOnboarding: hasOnboarded défini');

      // enqueue patch serveur (idempotent)
      await queue.enqueueUserPatch({'hasOnboarded': true});

      print('🎯 _finishOnboarding: Sync enqueue');

      // Actions legacy (alarmes, etc.)
      await OnboardingActions.complete(context);

      print('🎯 _finishOnboarding: Actions complétées');
    } catch (e, stackTrace) {
      print('❌ _finishOnboarding: Erreur: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }
}

// ——— Widgets —————————————————————————————————————————

class _MeditationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Text(
        'Selah est une app de méditation de la Bible (pas de lecture). '
        'Garde ta Bible physique à portée de main pour chaque séance.',
        style: const TextStyle(
          fontFamily: 'Gilroy',
          color: Colors.white70, 
          fontSize: 12, 
          height: 1.5,
        ),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.card, required this.index});
  final OnboardingCard card;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          // Effet Glassmorphism avec gradient de fond adouci
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.08),
              const Color(0xFF8B5CF6).withOpacity(0.05),
              Colors.white.withOpacity(0.03),
            ],
          ),
          // Bordure subtile pour l'effet de verre
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 25,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.04),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              child: Stack(
                children: [
                  // En-tête avec logo
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      'SELAH MEDITATION',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700, // Plus gras
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6), // Blanc adouci
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),


                  // Texte dynamique central (sans carte)
                  Positioned(
                    top: 260,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 26,
                            fontWeight: FontWeight.w900, // Très gras
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24), // Plus d'espacement
                        Text(
                          _getDynamicMessage(card, index),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500, // Moins gras pour le contraste
                            color: Colors.white.withOpacity(0.9), // Plus visible
                            height: 1.5, // Plus d'espacement entre les lignes
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Gradient blanc fumée amélioré de la base vers le haut
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white.withOpacity(0.08), // Base presque invisible
                            Colors.white.withOpacity(0.06), // 15% du haut
                            Colors.white.withOpacity(0.04), // 30% du haut
                            Colors.white.withOpacity(0.03), // 45% du haut
                            Colors.white.withOpacity(0.02), // 60% du haut
                            Colors.white.withOpacity(0.01), // 75% du haut
                            Colors.transparent,             // Complètement transparent
                          ],
                          stops: const [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 1.0],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
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
    );
  }

  Widget _buildStackedFolder(String label, Color color, {double size = 50, bool isMain = false}) {
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          // Ombre principale
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(1, 3),
          ),
          // Ombre interne pour l'effet de profondeur
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Onglet du dossier
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ),
          ),
          // Contenu du dossier
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.15,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// Couleur basée sur l'index de la carte - couleurs douces pour Glassmorphism
  Color _getCardColorForIndex(int index) {
    final colors = [
      const Color(0xFF6366F1).withOpacity(0.6), // Indigo doux
      const Color(0xFF8B5CF6).withOpacity(0.6), // Violet doux
      const Color(0xFF06B6D4).withOpacity(0.6), // Cyan doux
      const Color(0xFF10B981).withOpacity(0.6), // Émeraude doux
      const Color(0xFFF59E0B).withOpacity(0.6), // Ambre doux
      const Color(0xFFEF4444).withOpacity(0.6), // Rouge doux
    ];
    return colors[index % colors.length];
  }

  /// Couleur intelligente du texte selon la luminosité du fond
  Color _getIntelligentTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    if (luminance > 0.5) {
      return const Color(0xFF1A1A1A);
    } else {
      return const Color(0xFFFFFFFF);
    }
  }

  /// Fond intelligent pour l'encadré du contenu
  Color _getIntelligentBenefitBackground(Color cardColor) {
    final luminance = cardColor.computeLuminance();
    if (luminance > 0.5) {
      return Colors.black.withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.9);
    }
  }

  /// Bordure intelligente pour l'encadré du contenu
  Color _getIntelligentBenefitBorder(Color cardColor) {
    final luminance = cardColor.computeLuminance();
    if (luminance > 0.5) {
      return Colors.white.withOpacity(0.3);
    } else {
      return Colors.black.withOpacity(0.2);
    }
  }

  /// Texte intelligent pour l'encadré du contenu
  Color _getIntelligentBenefitTextColor(Color cardColor) {
    final luminance = cardColor.computeLuminance();
    if (luminance > 0.5) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  /// Icône pour la carte basée sur le contenu
  IconData _getIconForCard(OnboardingCard card, int index) {
    // Icônes spirituelles selon le contenu
    if (card.title.contains('Bienvenue')) {
      return Icons.wb_sunny_rounded; // Soleil/Accueil
    } else if (card.title.contains('régularité') || card.title.contains('discipline')) {
      return Icons.schedule_rounded; // Horloge/Discipline
    } else if (card.title.contains('méditation') || card.title.contains('contemplation')) {
      return Icons.spa_rounded; // Méditation
    } else if (card.title.contains('mémorisation') || card.title.contains('apprendre')) {
      return Icons.psychology_rounded; // Cerveau/Mémoire
    } else if (card.title.contains('partage') || card.title.contains('communauté')) {
      return Icons.people_rounded; // Communauté
    }
    
    // Fallback selon l'index
    final icons = [
      Icons.auto_stories_rounded, // Livre
      Icons.favorite_rounded, // Cœur
      Icons.star_rounded, // Étoile
    ];
    return icons[index % icons.length];
  }

  /// Génère un message dynamique selon la carte et l'index
  String _getDynamicMessage(OnboardingCard card, int index) {
    if (card.title.contains('Bienvenue')) {
      return 'Chaque jour sera une nouvelle rencontre avec Jésus dans Sa Parole. Prépare-toi à être transformé !';
    } else if (card.title.contains('régularité') || card.title.contains('discipline')) {
      return 'Le faire à une heure et à un endroit fixe. PRIEZ Dieu de vous aider à comprendre sa Parole.';
    } else if (card.title.contains('difficile') || card.title.contains('repose-toi')) {
      return 'Dans les moments difficiles, rappelle-toi : "Ma grâce te suffit". Tu n\'es jamais seul.';
    } else {
      // Messages génériques selon l'index
      final messages = [
        'Commence ton voyage spirituel avec confiance. Chaque pas compte.',
        'Le faire à une heure et à un endroit fixe. PRIEZ Dieu de vous aider à comprendre sa Parole.',
        'Dieu est avec toi dans chaque lecture. Laisse-toi transformer.',
      ];
      return messages[index % messages.length];
    }
  }

  /// Récupère les informations de lecture du plan actif
  Future<Map<String, dynamic>> _getPlanReadingInfo() async {
    try {
      final planService = bootstrap.planService;
      final activePlan = await planService.getActiveLocalPlan();
      
      if (activePlan == null) {
        return {
          'books': '0',
          'chapters': '0',
          'duration': '0 min',
        };
      }

      // Récupérer quelques jours du plan pour analyser les lectures
      final planDays = await planService.getPlanDays(activePlan.id, fromDay: 1, toDay: 7);
      
      if (planDays.isEmpty) {
        return {
          'books': '0',
          'chapters': '0',
          'duration': '${activePlan.minutesPerDay} min/jour',
        };
      }

      // Analyser les lectures pour extraire les livres et chapitres
      final Set<String> uniqueBooks = {};
      int totalChapters = 0;
      
      for (final day in planDays) {
        for (final reading in day.readings) {
          uniqueBooks.add(reading.book);
          
          // Extraire le nombre de chapitres de la range (ex: "3:16-4:10" = 2 chapitres)
          final range = reading.range;
          if (range.contains('-')) {
            final parts = range.split('-');
            if (parts.length == 2) {
              final startChapter = int.tryParse(parts[0].split(':')[0]) ?? 1;
              final endChapter = int.tryParse(parts[1].split(':')[0]) ?? startChapter;
              totalChapters += (endChapter - startChapter + 1);
            }
          } else {
            // Un seul chapitre
            totalChapters += 1;
          }
        }
      }

      // Calculer la durée totale estimée
      final totalDays = activePlan.totalDays;
      final minutesPerDay = activePlan.minutesPerDay;
      final totalMinutes = totalDays * minutesPerDay;
      final hours = totalMinutes ~/ 60;
      final remainingMinutes = totalMinutes % 60;
      
      String durationText;
      if (hours > 0) {
        durationText = remainingMinutes > 0 ? '${hours}h ${remainingMinutes}min' : '${hours}h';
      } else {
        durationText = '${minutesPerDay} min/jour';
      }

      return {
        'books': uniqueBooks.length.toString(),
        'chapters': totalChapters.toString(),
        'duration': durationText,
      };
    } catch (e) {
      print('❌ Erreur récupération info plan: $e');
      return {
        'books': '?',
        'chapters': '?',
        'duration': '?',
      };
    }
  }
}

class _AccentBlob extends StatelessWidget {
  const _AccentBlob({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF7C3AED).withOpacity(.28),
      const Color(0xFF22D3EE).withOpacity(.28),
      const Color(0xFF49C98D).withOpacity(.28),
    ];
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: RadialGradient(
            colors: [colors[index % colors.length], Colors.transparent],
            radius: 0.85, center: Alignment.topRight,
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8, height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _BottomCTA extends StatelessWidget {
  const _BottomCTA({required this.isLast, required this.onNext});
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1553FF), Color(0xFF49C98D)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.white,
        ),
        child: Text(
          isLast ? 'Commencer' : 'Continuer',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16, 
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
        const SizedBox(height: 16),
        Text('Chargement…', style: const TextStyle(
          fontFamily: 'Gilroy',
          color: Colors.white70,
        )),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Réessayer', style: TextStyle(color: Colors.white))),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(message, style: const TextStyle(
          fontFamily: 'Gilroy',
          color: Colors.white70,
        )),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Réessayer', style: TextStyle(color: Colors.white))),
      ]),
    );
  }
}