import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomPlanPage extends StatefulWidget {
  const CustomPlanPage({super.key});

  @override
  State<CustomPlanPage> createState() => _CustomPlanPageState();
}

class _CustomPlanPageState extends State<CustomPlanPage> {
  int currentStep = 0;
  
  // Form data
  String planName = 'Mon plan de lecture';
  String startDate = '[StartDate]';
  String totalDays = '[totalDays]';
  String readingOrder = 'traditional';
  List<String> selectedContent = ['Ancien Testament'];
  
  // Step 1 data
  List<String> readingDays = ['Lun'];
  bool overlapOTNT = false;
  bool reverseOrder = false;
  bool showStatistics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D29), // Fond sombre comme Superlist
        ),
        child: Stack(
          children: [
            // Formes décoratives en arrière-plan
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundShapesPainter(),
              ),
            ),
            // AppBar personnalisé
            SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'Plan Personnalisé',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Pour centrer le titre
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          _buildProgressIndicator(),
                          
                          const SizedBox(height: 32),
                          
                          // Step content
                          _buildStepContent(),
                          
                          const SizedBox(height: 32),
                          
                          // Navigation buttons
                          _buildNavigationButtons(),
                          
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        for (int i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: i <= currentStep 
                    ? const Color(0xFF8B5CF6) 
                    : const Color(0xFF374151),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de base',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Configurez les paramètres généraux de votre plan',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Plan name
        _buildInputField(
          'Nom du plan',
          planName,
          (value) => setState(() => planName = value),
        ),
        
        const SizedBox(height: 20),
        
        // Start date
        _buildInputField(
          'Date de début',
          startDate,
          (value) => setState(() => startDate = value),
        ),
        
        const SizedBox(height: 20),
        
        // Total days
        _buildInputField(
          'Nombre total de jours',
          totalDays,
          (value) => setState(() => totalDays = value),
        ),
        
        const SizedBox(height: 20),
        
        // Reading order
        _buildDropdownField(
          'Ordre de lecture',
          readingOrder,
          ['traditional', 'chronological', 'thematic'],
          (value) => setState(() => readingOrder = value),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenu à inclure',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Sélectionnez les parties de la Bible à inclure',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildCheckboxList(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres avancés',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Personnalisez davantage votre expérience de lecture',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildAdvancedSettings(),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récapitulatif',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Vérifiez vos paramètres avant de créer le plan',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildSummary(),
      ],
    );
  }

  Widget _buildInputField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextField(
          onChanged: onChanged,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Entrez $label',
            hintStyle: GoogleFonts.inter(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF374151),
              style: GoogleFonts.inter(color: Colors.white),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              items: options.map<DropdownMenuItem<String>>((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxList() {
    final options = [
      'Ancien Testament',
      'Nouveau Testament',
      'Psaumes',
      'Proverbes',
      'Évangiles',
    ];

    return Column(
      children: options.map((option) {
        final isSelected = selectedContent.contains(option);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CheckboxListTile(
            title: Text(
              option,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedContent.add(option);
                } else {
                  selectedContent.remove(option);
                }
              });
            },
            activeColor: const Color(0xFF8B5CF6),
            checkColor: Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      children: [
        _buildSwitchTile(
          'Jours de lecture',
          'Lun, Mar, Mer, Jeu, Ven',
          () => _showDaysSelector(),
        ),
        
        const SizedBox(height: 16),
        
        _buildSwitchTile(
          'Superposition AT/NT',
          'Lire l\'Ancien et le Nouveau Testament en parallèle',
          () => setState(() => overlapOTNT = !overlapOTNT),
          overlapOTNT,
        ),
        
        const SizedBox(height: 16),
        
        _buildSwitchTile(
          'Ordre inverse',
          'Commencer par la fin de la Bible',
          () => setState(() => reverseOrder = !reverseOrder),
          reverseOrder,
        ),
        
        const SizedBox(height: 16),
        
        _buildSwitchTile(
          'Afficher les statistiques',
          'Voir vos progrès de lecture',
          () => setState(() => showStatistics = !showStatistics),
          showStatistics,
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, VoidCallback onTap, [bool? value]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          if (value != null)
            Switch(
              value: value,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF8B5CF6),
            )
          else
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nom du plan: $planName',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Date de début: $startDate',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Nombre de jours: $totalDays',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Contenu: ${selectedContent.join(', ')}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => currentStep--),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF374151),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Précédent',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        
        if (currentStep > 0) const SizedBox(width: 16),
        
        Expanded(
          child: ElevatedButton(
            onPressed: currentStep < 3 
                ? () => setState(() => currentStep++)
                : _createPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              currentStep < 3 ? 'Suivant' : 'Créer le plan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDaysSelector() {
    // Implementation for days selector
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF374151),
        title: Text(
          'Jours de lecture',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Sélectionnez les jours de la semaine pour votre lecture',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: const Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
    );
  }

  void _createPlan() {
    // Implementation for plan creation
    Navigator.pushReplacementNamed(context, '/success', arguments: {
      'title': 'Plan Créé !',
      'message': 'Votre plan personnalisé "$planName" a été créé avec succès.',
      'buttonText': 'Commencer la lecture',
      'nextRoute': '/home',
    });
  }
}

// Background painter for decorative shapes
class BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw some decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.1),
      60,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      40,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      80,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
