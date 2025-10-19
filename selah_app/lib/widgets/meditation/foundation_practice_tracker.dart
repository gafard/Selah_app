import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/foundations_progress_service.dart';

/// Widget de tracking des pratiques de fondation
class FoundationPracticeTracker extends StatefulWidget {
  final SpiritualFoundation foundation;

  const FoundationPracticeTracker({
    super.key,
    required this.foundation,
  });

  @override
  State<FoundationPracticeTracker> createState() => _FoundationPracticeTrackerState();
}

class _FoundationPracticeTrackerState extends State<FoundationPracticeTracker> {
  bool _practiced = false;
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayPractice();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Charge la pratique d'aujourd'hui si elle existe
  Future<void> _loadTodayPractice() async {
    try {
      final practice = await FoundationsProgressService.getTodayPractice(widget.foundation.id);
      if (practice != null) {
        setState(() {
          _practiced = practice.practiced;
          _noteController.text = practice.note ?? '';
        });
      }
    } catch (e) {
      print('⚠️ Erreur chargement pratique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Icon(
                Icons.landscape_rounded,
                color: widget.foundation.gradient[0],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'As-tu mis en pratique cette fondation aujourd\'hui ?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Checkbox de pratique
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                'Oui, je l\'ai fait',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              value: _practiced,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _practiced = val ?? false);
              },
              activeColor: widget.foundation.gradient[0],
              checkColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
          
          // Champ de note (si pratiqué)
          if (_practiced) ...[
            const SizedBox(height: 16),
            Text(
              'Comment as-tu vécu cette fondation ? (optionnel)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _noteController,
                maxLength: 120,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Ex: J\'ai pardonné à mon collègue...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Bouton d'enregistrement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.foundation.gradient[0],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _practiced ? 'Enregistrer ma pratique' : 'Marquer comme non pratiqué',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_practiced) {
        await FoundationsProgressService.markAsPracticed(
          widget.foundation.id,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Fondation "${widget.foundation.name}" enregistrée !'),
              backgroundColor: widget.foundation.gradient[0],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        await FoundationsProgressService.markAsNotPracticed(widget.foundation.id);
        
        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📝 Fondation marquée comme non pratiquée'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur sauvegarde pratique: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

