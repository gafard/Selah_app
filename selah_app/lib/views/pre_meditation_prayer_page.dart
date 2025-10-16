import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../bootstrap.dart';

class PreMeditationPrayerPage extends StatefulWidget {
  const PreMeditationPrayerPage({super.key});

  @override
  State<PreMeditationPrayerPage> createState() => _PreMeditationPrayerPageState();
}

class _PreMeditationPrayerPageState extends State<PreMeditationPrayerPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de fade pour le texte
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animation de scale pour le cercle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animation de pulse pour l'icône
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Vérifier si le widget est encore monté avant chaque opération
    if (!mounted) return;
    
    // Délai avant de commencer les animations
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // Démarrer l'animation de fade
    _fadeController.forward();
    
    // Démarrer l'animation de scale après un délai
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _scaleController.forward();
    
    // Démarrer l'animation de pulse en boucle
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A148C), // Purple foncé
              Color(0xFF6A1B9A), // Purple plus clair
              Color(0xFF8E24AA), // Purple encore plus clair
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              
              // Texte principal
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Préparons',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'notre cœur...',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE1BEE7), // Light purple
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Cercle avec icône
              ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE1BEE7),
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Texte de prière
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Seigneur, ouvre mon cœur à Ta Parole\net guide-moi dans cette méditation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Bouton de validation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _navigateToReader();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A148C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black26,
                      ),
                      child: Text(
                        'Je suis prêt(e)',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Texte en bas
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Basé sur Psaume 119:18',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
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

  /// ✅ Navigation vers ReaderPageModern avec le passage du jour actuel
  Future<void> _navigateToReader() async {
    try {
      print('🔍 DEBUG: Début navigation vers ReaderPageModern');
      // Utiliser le PlanServiceHttp configuré globalement
      final activePlan = await planService.getActiveLocalPlan();
      print('🔍 DEBUG: Plan actif récupéré: ${activePlan?.id}');
      
      if (activePlan != null) {
        // Récupérer les jours du plan
        print('🔍 DEBUG: Récupération des jours du plan...');
        final planDays = await planService.getPlanDays(activePlan.id);
        print('🔍 DEBUG: Jours récupérés: ${planDays.length}');
        
        if (planDays.isNotEmpty) {
          // Calculer le jour actuel basé sur la date de début
          final today = DateTime.now();
          final startDate = activePlan.startDate;
          final daysSinceStart = today.difference(startDate).inDays;
          
          // Récupérer le passage du jour actuel
          if (daysSinceStart >= 0 && daysSinceStart < planDays.length) {
            final todayPassage = planDays[daysSinceStart];
            
            // Construire la référence du passage (maintenant sécurisé par ReadingRef.fromJson)
            String passageRef;
            if (todayPassage.readings.isNotEmpty) {
              final r = todayPassage.readings.first; // range est GARANTI String maintenant
              passageRef = '${r.book} ${r.range}'.trim(); // ex: "Jean 3:16-4:10"
            } else {
              passageRef = _generatePassageRef(todayPassage.dayIndex);
            }
            
            // Navigation avec les données du passage et un casting explicite
            if (mounted) {
              final extraData = <String, dynamic>{
                'passageRef': passageRef,
                'passageText': null, // Sera récupéré depuis la base de données
                'dayTitle': 'Jour ${todayPassage.dayIndex}',
                'planId': activePlan.id,
                'dayNumber': todayPassage.dayIndex,
                // ✅ Ne pas passer l'objet PlanDay complet (non sérialisable)
                // Les données nécessaires sont déjà passées individuellement
              };
              print('🔍 DEBUG: Données extraData: $extraData');
              context.go('/reader', extra: extraData);
            }
            
            print('✅ Navigation vers ReaderPageModern avec passage: $passageRef (Jour ${todayPassage.dayIndex})');
          } else {
            // Plan terminé ou pas encore commencé
            if (mounted) {
              _showPlanStatusMessage(activePlan, daysSinceStart, planDays.length);
            }
          }
        } else {
          // Pas de jours de plan trouvés - utiliser le fallback
          print('⚠️ Aucun jour de plan trouvé pour le plan: ${activePlan.id}');
          print('⚠️ Utilisation du fallback avec passage intelligent');
          
          // Fallback avec passage intelligent basé sur le plan
          final fallbackPassage = _generateIntelligentFallback(activePlan);
          
          if (mounted) {
            final fallbackData = <String, dynamic>{
              'passageRef': fallbackPassage,
              'passageText': null,
              'dayTitle': 'Lecture du jour',
              'planId': activePlan.id,
              'dayNumber': 1,
            };
            print('🔍 DEBUG: Données fallback: $fallbackData');
            context.go('/reader', extra: fallbackData);
          }
        }
      } else {
        // Aucun plan actif - navigation par défaut avec fallback
        print('⚠️ Aucun plan actif trouvé, navigation par défaut');
        if (mounted) {
          final defaultData = <String, dynamic>{
            'passageRef': _generatePassageRef(1), // Jour 1 par défaut
            'passageText': null,
            'dayTitle': 'Lecture du jour',
          };
          print('🔍 DEBUG: Données par défaut: $defaultData');
          context.go('/reader', extra: defaultData);
        }
      }
    } catch (e) {
      print('❌ Erreur navigation vers ReaderPageModern: $e');
      // Fallback en cas d'erreur avec passage intelligent
      if (mounted) {
        final errorData = <String, dynamic>{
          'passageRef': _generatePassageRef(1), // Jour 1 par défaut
          'passageText': null,
          'dayTitle': 'Lecture du jour',
        };
        print('🔍 DEBUG: Données d\'erreur: $errorData');
        context.go('/reader', extra: errorData);
      }
    }
  }

  /// Affiche un message selon le statut du plan
  void _showPlanStatusMessage(activePlan, int daysSinceStart, int totalDays) {
    String message;
    if (daysSinceStart < 0) {
      message = 'Votre plan commence le ${activePlan.startDate.day}/${activePlan.startDate.month}/${activePlan.startDate.year}';
    } else {
      message = 'Félicitations ! Vous avez terminé votre plan de $totalDays jours !';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ Génère un passage intelligent basé sur le plan actif
  String _generateIntelligentFallback(activePlan) {
    // Utiliser les livres du plan pour générer un passage intelligent
    final books = activePlan.books ?? [];
    if (books.isNotEmpty) {
      // Prendre le premier livre du plan
      final firstBook = books.first;
      return _generatePassageForBook(firstBook, 1);
    }
    
    // Fallback par défaut
    return _generatePassageRef(1);
  }
  
  /// ✅ Génère un passage pour un livre spécifique
  String _generatePassageForBook(String book, int dayNumber) {
    // Passages populaires par livre
    final bookPassages = {
      'Jean': ['Jean 14:1-19', 'Jean 3:16-21', 'Jean 15:1-17', 'Jean 8:12-20'],
      'Matthieu': ['Matthieu 6:9-13', 'Matthieu 5:3-12', 'Matthieu 11:28-30', 'Matthieu 28:18-20'],
      'Psaumes': ['Psaume 23:1-6', 'Psaume 91:1-16', 'Psaume 46:1-11', 'Psaume 139:1-18'],
      'Romains': ['Romains 8:28-39', 'Romains 12:1-2', 'Romains 5:1-11', 'Romains 10:9-13'],
      'Éphésiens': ['Éphésiens 2:8-10', 'Éphésiens 6:10-18', 'Éphésiens 4:1-6', 'Éphésiens 3:14-21'],
      'Philippiens': ['Philippiens 4:4-9', 'Philippiens 2:5-11', 'Philippiens 1:6', 'Philippiens 3:13-14'],
      '1 Corinthiens': ['1 Corinthiens 13:4-8', '1 Corinthiens 15:55-57', '1 Corinthiens 10:13', '1 Corinthiens 12:4-11'],
      'Galates': ['Galates 5:22-23', 'Galates 2:20', 'Galates 6:9-10', 'Galates 3:26-29'],
      'Colossiens': ['Colossiens 3:12-17', 'Colossiens 1:15-20', 'Colossiens 2:6-7', 'Colossiens 4:2-6'],
      'Hébreux': ['Hébreux 11:1-6', 'Hébreux 4:12', 'Hébreux 12:1-3', 'Hébreux 13:8'],
      'Jacques': ['Jacques 1:2-8', 'Jacques 4:7-10', 'Jacques 2:14-17', 'Jacques 5:13-16'],
      '1 Pierre': ['1 Pierre 5:6-11', '1 Pierre 2:9-10', '1 Pierre 3:15', '1 Pierre 4:8-11'],
      '2 Pierre': ['2 Pierre 1:3-8', '2 Pierre 3:9', '2 Pierre 1:20-21', '2 Pierre 2:9'],
      '1 Jean': ['1 Jean 4:7-12', '1 Jean 1:9', '1 Jean 3:16', '1 Jean 5:11-13'],
      'Apocalypse': ['Apocalypse 21:1-7', 'Apocalypse 3:20', 'Apocalypse 22:17', 'Apocalypse 1:8'],
    };
    
    final passages = bookPassages[book] ?? ['Jean 14:1-19'];
    final index = (dayNumber - 1) % passages.length;
    return passages[index];
  }

  /// ✅ Génère une référence de passage basée sur le jour du plan (FALLBACK INTELLIGENT)
  String _generatePassageRef(int dayNumber) {
    // Liste de passages bibliques populaires pour la méditation
    final passages = [
      'Jean 14:1-19',    // Jour 1 - "Je suis le chemin, la vérité et la vie"
      'Psaume 23:1-6',   // Jour 2 - "L'Éternel est mon berger"
      'Matthieu 6:9-13', // Jour 3 - Notre Père
      'Romains 8:28-39', // Jour 4 - "Toutes choses concourent au bien"
      'Éphésiens 2:8-10', // Jour 5 - "C'est par la grâce que vous êtes sauvés"
      'Philippiens 4:4-9', // Jour 6 - "Réjouissez-vous toujours"
      '1 Corinthiens 13:4-8', // Jour 7 - L'amour
      'Galates 5:22-23', // Jour 8 - Le fruit de l'Esprit
      'Colossiens 3:12-17', // Jour 9 - "Revêtez-vous de compassion"
      'Hébreux 11:1-6', // Jour 10 - La foi
      'Jacques 1:2-8', // Jour 11 - "Considérez comme un sujet de joie"
      '1 Pierre 5:6-11', // Jour 12 - "Humiliez-vous sous la main puissante"
      '2 Pierre 1:3-8', // Jour 13 - "Sa divine puissance nous a donné tout"
      '1 Jean 4:7-12', // Jour 14 - "Dieu est amour"
      'Apocalypse 21:1-7', // Jour 15 - "Voici, je fais toutes choses nouvelles"
    ];
    
    // Utiliser le passage correspondant au jour, ou revenir au début si on dépasse
    final index = (dayNumber - 1) % passages.length;
    return passages[index];
  }
}
