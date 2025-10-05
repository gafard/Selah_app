import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> with TickerProviderStateMixin {
  late HomePageModel model;
  late PageController _pageController;
  int _currentIndex = 0;

  final weekDays = [
    {'day': 'Dim', 'date': '26', 'isToday': false},
    {'day': 'Lun', 'date': '27', 'isToday': false},
    {'day': 'Mar', 'date': '28', 'isToday': false},
    {'day': 'Mer', 'date': '29', 'isToday': true},
    {'day': 'Jeu', 'date': '30', 'isToday': false},
    {'day': 'Ven', 'date': '31', 'isToday': false},
  ];

  final activities = [
    {
      'id': 1,
      'name': 'Lecture',
      'badge': 'Quotidien',
      'image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiaWJsZSUyMGJvb2t8ZW58MXx8fHwxNzU5NDg0MjQ3fDA&ixlib=rb-4.1.0&q=80&w=1080',
      'gradient': [const Color(0xFFC6F830), const Color(0xFFD4FA4D), const Color(0xFFC6F830)],
      'patternColor': const Color(0xFFA8D91F),
    },
    {
      'id': 2,
      'name': 'Prière',
      'badge': '3x/semaine',
      'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwcmF5ZXIlMjBjaGFwZWx8ZW58MXx8fHwxNzU5NDg0MjQ4fDA&ixlib=rb-4.1.0&q=80&w=1080',
      'gradient': [const Color(0xFFA78BFA), const Color(0xFFC4B5FD), const Color(0xFFA78BFA)],
      'patternColor': const Color(0xFF8B5CF6),
    },
    {
      'id': 3,
      'name': 'Méditation',
      'badge': '2x/semaine',
      'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtZWRpdGF0aW9uJTIwcGVhY2VmdWx8ZW58MXx8fHwxNzU5NDg0MjQ5fDA&ixlib=rb-4.1.0&q=80&w=1080',
      'gradient': [const Color(0xFF60A5FA), const Color(0xFF93C5FD), const Color(0xFF60A5FA)],
      'patternColor': const Color(0xFF3B82F6),
    },
    {
      'id': 4,
      'name': 'Mur Spirituel',
      'badge': 'Historique',
      'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwcmF5ZXIlMjBjaGFwZWx8ZW58MXx8fHwxNzU5NDg0MjQ4fDA&ixlib=rb-4.1.0&q=80&w=1080',
      'gradient': [const Color(0xFFF59E0B), const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
      'patternColor': const Color(0xFFD97706),
    },
    {
      'id': 5,
      'name': 'Étude',
      'badge': '4x/semaine',
      'image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdHVkeSUyMGJpYmxlJTIwbm90ZXN8ZW58MXx8fHwxNzU5NDg0MjUwfDA&ixlib=rb-4.1.0&q=80&w=1080',
      'gradient': [const Color(0xFFF87171), const Color(0xFFFCA5A5), const Color(0xFFF87171)],
      'patternColor': const Color(0xFFEF4444),
    },
  ];

  @override
  void initState() {
    super.initState();
    model = HomePageModel()..initState(context);
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    model.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            // Background shapes
            _buildBackgroundShapes(),
            
            // Main content
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Main content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Header
                            _buildHeader(),
                            const SizedBox(height: 24),
                            
                            // Calendar
                            _buildCalendar(),
                            const SizedBox(height: 20),
                            
                            // Activity Carousel
                            Expanded(
                              child: _buildActivityCarousel(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Progress Card
                            _buildProgressCard(),
                          ],
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
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // Geometric shapes
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: 30,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC6F830), Color(0xFFD4FA4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: 60,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, Justin',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '29.01.2023',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.network(
              'https://images.unsplash.com/photo-1531299102504-fc718f23c100?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwcm9maWxlJTIwbWFuJTIwY2FzdWFsfGVufDF8fHx8MTc1OTQ4MzM0Nnww&ixlib=rb-4.1.0&q=80&w=1080',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(Icons.person, color: Color(0xFF9CA3AF)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Row(
      children: weekDays.map((day) {
        final isToday = day['isToday'] as bool;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFC6F830) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  day['day'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isToday ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day['date'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityCarousel() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isActive = index == _currentIndex;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                transform: Matrix4.identity()
                  ..scale(isActive ? 1.0 : 0.92),
                child: _buildActivityCard(activity, isActive),
              );
            },
          ),
        ),
        
        // Pagination dots
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(activities.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1F2937) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isActive) {
    return GestureDetector(
      onTap: () => _navigateToActivity(activity),
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activity['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (activity['gradient'][0] as Color).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(activity['patternColor'] as Color),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activity['badge'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Image
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          activity['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Go To Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commencer',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _navigateToActivity(Map<String, dynamic> activity) {
    final activityId = activity['id'] as int;
    final activityName = activity['name'] as String;
    
    switch (activityId) {
      case 1: // Lecture
        Navigator.pushNamed(context, '/reader');
        break;
      case 2: // Prière
        Navigator.pushNamed(context, '/prayer_subjects');
        break;
      case 3: // Méditation
        Navigator.pushNamed(context, '/reader');
        break;
      case 4: // Mur Spirituel
        Navigator.pushNamed(context, '/spiritual_wall');
        break;
      case 5: // Étude
        Navigator.pushNamed(context, '/reader');
        break;
      default:
        print('Navigation non définie pour: $activityName (ID: $activityId)');
    }
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vos objectifs quotidiens presque terminés !',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '5/6 tâches terminées',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          
          // Circular progress
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                // Background circle
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: 5/6,
                    strokeWidth: 4,
                    backgroundColor: Color(0xFF374151),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC6F830)),
                  ),
                ),
                // Percentage text
                Center(
                  child: Text(
                    '83%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  
  _PatternPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    // Draw curved lines
    for (int i = 0; i < 6; i++) {
      final y = 40 + (i * 40);
      path.reset();
      path.moveTo(0, y.toDouble());
      path.quadraticBezierTo(
        size.width * 0.25, y - 20,
        size.width * 0.5, y.toDouble(),
      );
      path.quadraticBezierTo(
        size.width * 0.75, y + 20,
        size.width, y.toDouble(),
      );
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}