import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fancy_stack_carousel/fancy_stack_carousel.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late Future<List<Map<String, dynamic>>> _presetsFuture;
  int _currentSlide = 0;
  late FancyStackCarouselController _carouselController;
  List<FancyStackItem> _carouselItems = [];

  @override
  void initState() {
    super.initState();
    _presetsFuture = _fetchPresets();
    _carouselController = FancyStackCarouselController();
  }

  Future<List<Map<String, dynamic>>> _fetchPresets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final presets = [
      {
        'title': 'Nouveau Testament',
        'subtitle': '3 mois • ~15 min/jour',
        'image': 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1200',
        'gradient': const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        ),
        'id': 'nt_3m',
      },
      {
        'title': 'Bible entière',
        'subtitle': '6 mois • ~25 min/jour',
        'image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=1200',
        'gradient': const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFFC4B5FD)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        ),
        'id': 'bible_6m',
      },
    ];

    // Créer les FancyStackItem
    _carouselItems = presets.asMap().entries.map((entry) {
      final index = entry.key;
      final preset = entry.value;
      return FancyStackItem(
        id: index + 1, // Utiliser l'index comme ID (commence à 1)
        child: _buildPlanCard(preset),
      );
    }).toList();

    return presets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _presetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'Aucun plan trouvé.',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              );
            }

            final presets = snapshot.data!;
            return _buildROIOnboardingPage(presets);
          },
        ),
      ),
    );
  }

  Widget _buildROIOnboardingPage(List<Map<String, dynamic>> presets) {
    return Column(
      children: [
        // Cards Section
        Expanded(
          flex: 3,
          child: _buildCardsSection(presets),
        ),
        // Text Content
        _buildTextContent(),
        // Pagination Dots
        _buildPaginationDots(presets.length),
        // Bottom Navigation
        _buildBottomNavigation(presets.length),
      ],
    );
  }

  Widget _buildCardsSection(List<Map<String, dynamic>> presets) {
    return Container(
      height: 420,
      child: FancyStackCarousel(
        items: _carouselItems,
        options: FancyStackCarouselOptions(
          size: const Size(300, 420),
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
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

  Widget _buildPlanCard(Map<String, dynamic> preset) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 380,
        decoration: BoxDecoration(
          gradient: preset['gradient'] as Gradient,
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
              Image.network(
                preset['image'] as String, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: preset['gradient'] as Gradient,
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
                      preset['title'] as String,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset['subtitle'] as String,
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
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            'Choisis ton plan de lecture.',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Découvre des parcours de lecture biblique adaptés à ton rythme et tes objectifs spirituels.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
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
            color: isActive ? Colors.black : Colors.grey[300],
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
          _buildNavButton(
            icon: Icons.chevron_left,
            onPressed: _currentSlide > 0 
              ? () => _carouselController.animateToLeft()
              : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
          const SizedBox(width: 16),
          _buildNavButton(
            icon: Icons.chevron_right,
            onPressed: _currentSlide < totalItems - 1 
              ? () => _carouselController.animateToRight()
              : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.black : Colors.grey[400],
        ),
        onPressed: onPressed,
      ),
    );
  }
}