import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plan_preset.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  // Palette de couleurs de Selah
  static const Color _darkBackground = Color(0xFF1C1C1E);
  static const Color _goldAccent = Color(0xFF8B7355);
  static const Color _softWhite = Color(0xFFF5F5F5);
  static const Color _mediumGrey = Color(0xFF8E8E93);
  static const Color _cardBackground = Color(0xFF2C2C2E);

  late Future<List<PlanPreset>> _presetsFuture;
  final _controller = SwipableStackController();

  @override
  void initState() {
    super.initState();
    _presetsFuture = _fetchPresets();
  }

  Future<List<PlanPreset>> _fetchPresets() async {
    // Simulation de données pour les tests
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const PlanPreset(
        id: 'new_testament',
        title: 'Nouveau Testament',
        subtitle: '90 jours · ~10 min/jour',
        badge: 'Populaire',
        icon: Icons.menu_book_rounded,
        color: Color(0xFFF9A66C),
      ),
      const PlanPreset(
        id: 'psalms',
        title: 'Psaumes',
        subtitle: '150 jours · ~5 min/jour',
        badge: 'Méditation',
        icon: Icons.music_note_rounded,
        color: Color(0xFF6C5CE7),
      ),
    ];
  }

  Future<void> _createPlanFromPreset(PlanPreset preset) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LoadingDialog(),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté.");

      final response = await Supabase.instance.client.functions.invoke(
        'create-custom-plan',
        body: {
          'userId': user.id,
          'planName': preset.title,
          'startDate': DateTime.now().toIso8601String().split('T')[0],
          'totalDays': 90, // Valeur par défaut
          'readingOrder': 'traditional',
          'selectedBooks': ['NT'],
          'selectedDays': [1, 2, 3, 4, 5, 6, 7],
          'overlapOtNt': false,
          'reverseOrder': false,
          'showStats': true,
        },
      );

      if (response.data != null) {
        if (mounted) {
          Navigator.of(context).pop(); // Fermer le loader
          context.pushReplacement('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Choisis ton plan',
          style: GoogleFonts.playfairDisplay(color: _softWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _goldAccent),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<PlanPreset>>(
        future: _presetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _goldAccent));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Aucun plan trouvé.',
                style: GoogleFonts.lato(color: _mediumGrey),
              ),
            );
          }

          final presets = snapshot.data!;
          return SafeArea(
            child: Stack(
              children: [
                // Le fond avec les cartes "fantômes"
                ...List.generate(presets.length, (index) {
                  if (index == 0) return const SizedBox.shrink();
                  final topOffset = (presets.length - index - 1) * 10.0;
                  final leftOffset = (presets.length - index - 1) * 5.0;
                  return Positioned(
                    top: topOffset,
                    left: leftOffset,
                    child: _buildGhostCard(presets[index]),
                  );
                }),
                // Le SwipableStack avec les vraies cartes
                SwipableStack(
                  controller: _controller,
                  stackClipBehaviour: Clip.none,
                  onSwipeCompleted: (index, direction) {
                    if (direction == SwipeDirection.right) {
                      _createPlanFromPreset(presets[index]);
                    }
                  },
                  onWillMoveNext: (index, direction) => true,
                  builder: (context, properties) {
                    final preset = presets[properties.index];
                    return _buildPresetCard(preset, properties.swipeProgress);
                  },
                  itemCount: presets.length,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widgets pour les cartes ---

  // Carte "fantôme" pour l'effet de pile
  Widget _buildGhostCard(PlanPreset preset) {
    return Opacity(
      opacity: 0.4,
      child: Transform.scale(
        scale: 0.95,
        child: _buildPresetCardLayout(preset),
      ),
    );
  }

  // La carte principale, animée
  Widget _buildPresetCard(PlanPreset preset, double progress) {
    return Transform.scale(
      scale: 0.9 + (0.1 * progress),
      child: _buildPresetCardLayout(preset),
    );
  }

  Widget _buildPresetCardLayout(PlanPreset preset) {
    return Container(
      height: 550, // Hauteur fixe pour la carte
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image de fond (placeholder pour l'instant)
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_goldAccent.withOpacity(0.7), _goldAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(Icons.auto_stories, size: 80, color: _darkBackground.withOpacity(0.7)),
            ),
          ),
          // Contenu de la carte
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 320,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _softWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preset.subtitle ?? '',
                    style: GoogleFonts.lato(
                      color: _mediumGrey,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '90 jours', // Valeur par défaut
                    style: GoogleFonts.lato(
                      color: _goldAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {}, // Swipe left action
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _mediumGrey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Voir les détails', style: GoogleFonts.lato(color: _mediumGrey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _createPlanFromPreset(preset),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _goldAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Créer mon plan', style: GoogleFonts.lato(color: _darkBackground, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF8B7355)),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Création de votre plan en cours...',
                style: GoogleFonts.lato(color: const Color(0xFFF5F5F5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}