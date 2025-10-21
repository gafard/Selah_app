import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:airplane_mode_checker/airplane_mode_checker.dart';
import '../bootstrap.dart'; // pour planService + _navigateToReader()
import '../services/daily_display_service.dart';

class PreMeditationPrayerPage extends StatefulWidget {
  const PreMeditationPrayerPage({super.key});

  @override
  State<PreMeditationPrayerPage> createState() => _PreMeditationPrayerPageState();
}

class _PreMeditationPrayerPageState extends State<PreMeditationPrayerPage>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _fadeIn;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<double> _pulseScale;

  // Airplane mode
  AirplaneModeStatus? _airplane;
  StreamSubscription<AirplaneModeStatus>? _airSub;

  @override
  void initState() {
    super.initState();

    // Vérifier si la page doit être affichée aujourd'hui
    if (!DailyDisplayService.shouldShowPreMeditationPrayer()) {
      // Déjà affichée aujourd'hui, naviguer directement vers le lecteur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToReader();
      });
      return;
    }

    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOutCubic);

    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseScale = Tween(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _fadeIn.forward();
    _pulse.repeat(reverse: true);

    _initAirplaneWatcher();
  }

  Future<void> _initAirplaneWatcher() async {
    try {
      final s = await AirplaneModeChecker.instance.checkAirplaneMode();
      if (mounted) setState(() => _airplane = s);
    } catch (_) {
      if (mounted) setState(() => _airplane = null);
    }
    _airSub = AirplaneModeChecker.instance.listenAirplaneMode().listen((s) {
      if (mounted) setState(() => _airplane = s);
    });
  }

  @override
  void dispose() {
    _airSub?.cancel();
    _fadeIn.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ───────────────────────────────── UI ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1025),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            print('🔙 AppBar bouton retour tapé');
            HapticFeedback.selectionClick();
            context.go('/home');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1025), 
              Color(0xFF1C1740), 
              Color(0xFF2D1B69),
              Color(0xFF1A0B3D),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              _buildBackgroundElements(),

              // Main content with improved layout
              FadeTransition(
                opacity: _fade,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero section with improved spacing
                        _buildHeroSection(),
                        
                        const SizedBox(height: 32),
                        
                        // Main card with enhanced design
                        _buildMainCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Scripture reference with better styling
                        _buildScriptureReference(),
                      ],
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

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Floating orbs for depth
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Enhanced icon with better animation
        ScaleTransition(
          scale: _pulseScale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Enhanced title
        Text(
          'Prépare ton cœur',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Enhanced subtitle
        Text(
          'Tu t\'apprêtes à entrer dans la présence de Dieu.\n'
          'Choisis le silence, écoute et reste disponible.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.85),
            height: 1.5,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return _GlassCard(
      child: Column(
        children: [
          // Tips section with improved design
          _buildEnhancedTipsList(),
          
          const SizedBox(height: 20),
          
          // Airplane mode indicator with better styling
          _buildEnhancedAirplanePill(),
          
          const SizedBox(height: 24),
          
          // Action buttons with improved spacing
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEnhancedTipsList() {
    final tips = [
      {
        'icon': Icons.favorite_rounded,
        'text': 'Prie pour que Dieu te parle à travers cette lecture',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.place_rounded,
        'text': 'Trouve un endroit calme',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.hearing_rounded,
        'text': 'Fais silence : « Parle Seigneur, ton serviteur écoute »',
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Column(
      children: tips.map((tip) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (tip['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (tip['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                tip['icon'] as IconData,
                color: tip['color'] as Color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip['text'] as String,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEnhancedAirplanePill() {
    final isOn = _airplane == AirplaneModeStatus.on;
    final bg = isOn ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final txt = isOn ? "Mode avion activé" : "Mode avion désactivé";
    final icon = isOn ? Icons.flight_takeoff_rounded : Icons.flight_land_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bg.withOpacity(0.2),
            bg.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bg, size: 18),
          const SizedBox(width: 10),
          Text(
            txt,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary button with enhanced design
        _EnhancedPrimaryButton(
          text: 'Je suis prêt(e)',
          onTap: _onReadyPressed,
        ),
        
        const SizedBox(height: 12),
        
        // Secondary button with improved styling
        _EnhancedGhostButton(
          text: 'Passer pour l\'instant',
          onTap: () => context.go('/home'),
        ),
      ],
    );
  }

  Widget _buildScriptureReference() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        'Psaume 119:18',
        style: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ───────────────────────────── Actions ─────────────────────────────

  Future<void> _onReadyPressed() async {
    HapticFeedback.mediumImpact();
    
    // Marquer la page comme affichée aujourd'hui
    await DailyDisplayService.markPreMeditationPrayerAsShown();
    
    await _navigateToReader();
  }


  // ✅ Navigation vers ReaderPageModern avec le passage du jour actuel
  Future<void> _navigateToReader() async {
    try {
      print('🔍 DEBUG: Début navigation vers ReaderPageModern');
      // Utiliser le PlanServiceHttp configuré globalement
      final activePlan = await planService.getActiveLocalPlan();
      print('🔍 DEBUG: Plan actif récupéré: ${activePlan?.id}');
      
      if (activePlan != null) {
        // 🐛 DEBUG: Vérifier l'état du plan avant régénération
        print('🔍 DEBUG: Vérification de l\'état du plan...');
        await planService.debugPlanStatus();
        
        // 🔧 S'assurer que les jours du plan existent (auto-régénération si nécessaire)
        print('🔍 DEBUG: Vérification et régénération des jours du plan...');
        await planService.regenerateCurrentPlanDays();
        
        // Récupérer les jours du plan
        print('🔍 DEBUG: Récupération des jours du plan...');
        final planDays = await planService.getPlanDays(activePlan.id);
        print('🔍 DEBUG: Jours récupérés: ${planDays.length}');
        
        if (planDays.isNotEmpty) {
          // ✅ Calculer la différence en jours calendaires (change à minuit)
          final today = DateTime.now();
          final startDate = activePlan.startDate;
          
          // Normaliser les dates à minuit pour comparer les jours calendaires
          final todayNormalized = DateTime(today.year, today.month, today.day);
          final startNormalized = DateTime(startDate.year, startDate.month, startDate.day);
          
          final dayIndex = todayNormalized.difference(startNormalized).inDays + 1;
          
          print('🔍 DEBUG: Calcul du jour actuel (calendaire):');
          print('   - Aujourd\'hui: ${today.day}/${today.month}/${today.year}');
          print('   - Date début: ${startDate.day}/${startDate.month}/${startDate.year}');
          print('   - Jour calculé: $dayIndex');
          
          if (dayIndex >= 1 && dayIndex <= planDays.length) {
            final todayPassage = planDays.firstWhere((day) => day.dayIndex == dayIndex);
            
            // Construire la référence du passage (maintenant sécurisé par ReadingRef.fromJson)
            String passageRef;
            if (todayPassage.readings.isNotEmpty) {
              final r = todayPassage.readings.first; // range est GARANTI String maintenant
              passageRef = '${r.book} ${r.range}'.trim(); // ex: "Jean 3:16-4:10"
              print('🔍 DEBUG: Passage du jour ${todayPassage.dayIndex}: ${r.book} ${r.range}');
            } else {
              passageRef = _generatePassageRef(todayPassage.dayIndex);
              print('🔍 DEBUG: Passage généré pour le jour ${todayPassage.dayIndex}: $passageRef');
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
              _showPlanStatusMessage(activePlan, dayIndex - 1, planDays.length);
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

// ────────────────────────────── UI bits ──────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔙 _GlassIconButton tapé');
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _EnhancedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _EnhancedPrimaryButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1553FF),
              Color(0xFF0D47A1),
              Color(0xFF1E40AF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1553FF).withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _EnhancedGhostButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _EnhancedGhostButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
