import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/contextual_prompts_service.dart';
import '../models/spiritual_foundation.dart';

/// Barre de prompts de réflexion contextuels pour le Reader
/// Utilise l'analyse sémantique FalconX pour générer des questions adaptées
class ReaderPromptsBar extends StatefulWidget {
  final void Function(String prompt)? onTapPrompt;
  final bool isDark;
  final String passageRef;
  final SpiritualFoundation? foundation;
  final String userLevel;
  
  const ReaderPromptsBar({
    super.key,
    this.onTapPrompt,
    this.isDark = true,
    required this.passageRef,
    this.foundation,
    this.userLevel = 'intermédiaire',
  });

  @override
  State<ReaderPromptsBar> createState() => _ReaderPromptsBarState();
}

class _ReaderPromptsBarState extends State<ReaderPromptsBar> {
  List<ContextualPrompt> _prompts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContextualPrompts();
  }

  @override
  void didUpdateWidget(ReaderPromptsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passageRef != widget.passageRef || 
        oldWidget.foundation != widget.foundation) {
      _loadContextualPrompts();
    }
  }

  Future<void> _loadContextualPrompts() async {
    setState(() => _isLoading = true);
    
    try {
      final prompts = await ContextualPromptsService.generateContextualPrompts(
        passageRef: widget.passageRef,
        foundation: widget.foundation,
        userLevel: widget.userLevel,
      );
      
      if (mounted) {
        setState(() {
          _prompts = prompts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ Erreur chargement prompts contextuels: $e');
      if (mounted) {
        setState(() {
          _prompts = _getFallbackPrompts();
          _isLoading = false;
        });
      }
    }
  }

  List<ContextualPrompt> _getFallbackPrompts() {
    return [
      const ContextualPrompt(
        text: 'Que dit ce passage sur le caractère de Dieu ?',
        category: 'général',
        priority: 1,
        context: 'Prompts généraux',
      ),
      const ContextualPrompt(
        text: 'Quel verset dois-je garder aujourd\'hui ?',
        category: 'général',
        priority: 2,
        context: 'Prompts généraux',
      ),
      const ContextualPrompt(
        text: 'Quelle étape concrète je prends d\'ici ce soir ?',
        category: 'général',
        priority: 2,
        context: 'Prompts généraux',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _prompts[index];
          return GestureDetector(
            onTap: () => widget.onTapPrompt?.call(prompt.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark 
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05),
                border: Border.all(
                  color: widget.isDark 
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  prompt.text,
                  style: GoogleFonts.inter(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

