import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/design_tokens.dart';
import 'choice_card.dart';

/// Dialog modal pour choisir le style de méditation
class ModalOptionChooser extends StatefulWidget {
  final Function(int option) onSelected;

  const ModalOptionChooser({
    super.key,
    required this.onSelected,
  });

  @override
  State<ModalOptionChooser> createState() => _ModalOptionChooserState();
}

class _ModalOptionChooserState extends State<ModalOptionChooser>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectOption(int option) {
    setState(() {
      selectedOption = option;
    });
    HapticFeedback.lightImpact();
    
    // Attendre un peu pour montrer la sélection
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onSelected(option);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1B69),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choisis ton style',
                      style: DesignTokens.heading.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    ChoiceCard(
                      title: 'Processus de Découverte',
                      description: 'Demander/Chercher/Frapper',
                      icon: Icons.explore_rounded,
                      isSelected: selectedOption == 1,
                      onTap: () => _selectOption(1),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ChoiceCard(
                      title: 'Lecture Quotidienne',
                      description: '8 questions d\'étude',
                      icon: Icons.menu_book_rounded,
                      isSelected: selectedOption == 2,
                      onTap: () => _selectOption(2),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Tu pourras changer ce choix à tout moment',
                      style: DesignTokens.body.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
