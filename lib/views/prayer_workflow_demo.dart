import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PrayerWorkflowDemo extends StatefulWidget {
  const PrayerWorkflowDemo({super.key});

  @override
  State<PrayerWorkflowDemo> createState() => _PrayerWorkflowDemoState();
}

class _PrayerWorkflowDemoState extends State<PrayerWorkflowDemo> {
  final List<String> _selectedSubjects = [];
  final List<String> _prayerItems = [];
  final TextEditingController _prayerController = TextEditingController();
  
  // Sujets de prière suggérés
  final List<String> _suggestedSubjects = [
    'Action de grâce',
    'Repentance',
    'Obéissance',
    'Intercession',
    'Foi',
    'Sagesse',
    'Paix',
    'Protection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workflow de Prière',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Étape 1: Sujets de prière
            _buildStepCard(
              title: '1. Sujets de Prière',
              subtitle: 'Sélectionnez les sujets pour votre prière',
              child: _buildSubjectsSection(),
            ),
            
            const SizedBox(height: 16),
            
            // Étape 2: Génération de prière
            if (_selectedSubjects.isNotEmpty)
              _buildStepCard(
                title: '2. Génération de Prière',
                subtitle: 'Vos sujets sélectionnés',
                child: _buildPrayerGenerationSection(),
              ),
            
            const SizedBox(height: 16),
            
            // Étape 3: Éditeur de prière
            if (_prayerItems.isNotEmpty)
              _buildStepCard(
                title: '3. Éditeur de Prière',
                subtitle: 'Personnalisez votre prière',
                child: _buildPrayerEditorSection(),
              ),
            
            const SizedBox(height: 32),
            
            // Bouton de finalisation
            if (_prayerItems.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishPrayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Finaliser la Prière',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B7355).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
          
          const SizedBox(height: 16),
          
          child,
        ],
      ),
    );
  }

  Widget _buildSubjectsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedSubjects.map((subject) {
        final isSelected = _selectedSubjects.contains(subject);
        return GestureDetector(
          onTap: () => _toggleSubject(subject),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF8B7355) 
                  : const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF8B7355) 
                    : const Color(0xFF5A5A5C),
                width: 1,
              ),
            ),
            child: Text(
              subject,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrayerGenerationSection() {
    return Column(
      children: [
        // Bouton de génération
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generatePrayerItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Générer des Éléments de Prière',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Éléments générés
        if (_prayerItems.isNotEmpty)
          Column(
            children: _prayerItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removePrayerItem(index),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPrayerEditorSection() {
    return Column(
      children: [
        TextField(
          controller: _prayerController,
          maxLines: 6,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Écrivez votre prière personnalisée...',
            hintStyle: GoogleFonts.inter(
              color: Colors.white54,
            ),
            filled: true,
            fillColor: const Color(0xFF3A3A3C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bouton d'ajout
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addCustomPrayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ajouter à la Prière',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  void _generatePrayerItems() {
    setState(() {
      _prayerItems.clear();
      for (final subject in _selectedSubjects) {
        _prayerItems.add(_generatePrayerItemForSubject(subject));
      }
    });
  }

  String _generatePrayerItemForSubject(String subject) {
    switch (subject) {
      case 'Action de grâce':
        return 'Seigneur, je te remercie pour toutes tes bénédictions dans ma vie.';
      case 'Repentance':
        return 'Pardonne-moi mes péchés et aide-moi à marcher dans ta justice.';
      case 'Obéissance':
        return 'Donne-moi la force d\'obéir à ta parole et à ta volonté.';
      case 'Intercession':
        return 'Je prie pour mes proches et pour ceux qui ont besoin de toi.';
      case 'Foi':
        return 'Renforce ma foi et ma confiance en toi, Seigneur.';
      case 'Sagesse':
        return 'Accorde-moi ta sagesse pour les décisions que je dois prendre.';
      case 'Paix':
        return 'Donne-moi ta paix qui surpasse toute intelligence.';
      case 'Protection':
        return 'Protège-moi et ma famille de tout mal et danger.';
      default:
        return 'Seigneur, je te prie pour $subject.';
    }
  }

  void _removePrayerItem(int index) {
    setState(() {
      _prayerItems.removeAt(index);
    });
  }

  void _addCustomPrayer() {
    if (_prayerController.text.trim().isNotEmpty) {
      setState(() {
        _prayerItems.add(_prayerController.text.trim());
        _prayerController.clear();
      });
    }
  }

  void _finishPrayer() {
    // Navigation vers la page de succès
    context.pushReplacement('/success', extra: {
      'title': 'Prière Finalisée !',
      'message': 'Votre prière a été enregistrée avec succès. Que Dieu vous bénisse !',
      'buttonText': 'Retour à l\'Accueil',
      'nextRoute': '/home',
    });
  }

  @override
  void dispose() {
    _prayerController.dispose();
    super.dispose();
  }
}
