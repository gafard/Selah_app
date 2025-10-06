import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fancy_stack_carousel/fancy_stack_carousel.dart';
import '../models/plan_preset.dart';
import '../services/plan_service.dart';
import 'custom_plan_generator_page.dart';

class ChoosePlanPage extends StatefulWidget {
  const ChoosePlanPage({super.key});

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  late Future<List<PlanPreset>> _presetsFuture;
  int _currentSlide = 0;
  late FancyStackCarouselController _carouselController;
  List<FancyStackItem> _carouselItems = [];

  @override
  void initState() {
    super.initState();
    _presetsFuture = _fetchPresets();
    _carouselController = FancyStackCarouselController();
  }

  Future<List<PlanPreset>> _fetchPresets() async {
    return await PlanPresetsRepo.loadFromAsset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<PlanPreset>>(
            future: _presetsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
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

              final presets = snapshot.data!;

              // Créer les FancyStackItem à partir des PlanPreset
              _carouselItems = presets.asMap().entries.map((entry) {
                final index = entry.key;
                final preset = entry.value;
                return FancyStackItem(
                  id: index + 1,
                  child: _buildPlanCard(preset),
                );
              }).toList();

              return _buildChoosePlanPage(presets);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChoosePlanPage(List<PlanPreset> presets) {
    return Column(
      children: [
        // Header
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
        // Custom Generator Button
        _buildCustomGeneratorButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choisissez votre plan',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez un plan de lecture qui correspond à vos objectifs spirituels.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(List<PlanPreset> presets) {
    return SizedBox(
      height: 420,
      child: FancyStackCarousel(
        items: _carouselItems,
        options: FancyStackCarouselOptions(
          size: const Size(300, 420),
          autoPlay: false, // Désactivé pour que l'utilisateur contrôle manuellement
          onPageChanged: (index, reason, direction) {
            setState(() {
              _currentSlide = index;
            });
          },
        ),
        carouselController: _carouselController,
      ),
    );
  }

  Widget _buildPlanCard(PlanPreset preset) {
    return GestureDetector(
      onTap: () => _onPlanSelected(preset),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 380,
        decoration: BoxDecoration(
          gradient: _getGradientForPreset(preset),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond
              if (preset.coverImage != null)
                Image.network(
                  preset.coverImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: _getGradientForPreset(preset),
                      ),
                    );
                  },
                ),
              // Voile pour lisibilité du texte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black.withOpacity(.65), Colors.transparent],
                  ),
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
                    Text(
                      '${preset.durationDays} jours • ${_getEstimatedTime(preset)} min/jour',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Investissez dans votre croissance spirituelle',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Découvrez des plans de lecture adaptés à votre rythme et vos objectifs.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationDots(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentSlide == index ? Colors.blue : Colors.grey[300],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCustomGeneratorButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomPlanGeneratorPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Générer un plan personnalisé',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  LinearGradient _getGradientForPreset(PlanPreset preset) {
    final gradients = [
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
      ),
    ];
    return gradients[preset.slug.hashCode % gradients.length];
  }

  String _getEstimatedTime(PlanPreset preset) {
    // Estimation basée sur la durée du plan
    if (preset.durationDays <= 15) return '15-20';
    if (preset.durationDays <= 30) return '10-15';
    if (preset.durationDays <= 90) return '8-12';
    return '5-10';
  }

  Future<void> _onPlanSelected(PlanPreset preset) async {
    try {
      // Afficher un dialogue de confirmation avec sélection de date
      final startDate = await _showDatePickerDialog(preset);
      if (startDate == null) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Créer le plan
      await PlanService.createPlanFromPreset(
        userId: 'current_user_id', // Dans une vraie app, récupérer depuis l'auth
        preset: preset,
        startDate: startDate,
      );

      // Fermer le dialogue de chargement
      if (mounted) Navigator.pop(context);

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan "${preset.name}" créé avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Naviguer vers l'onboarding
      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      // Fermer le dialogue de chargement s'il est ouvert
      if (mounted) Navigator.pop(context);

      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du plan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
