import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet pour le mini-journal avec 3 puces d'application
Future<List<String>?> showMiniJournalSheet(BuildContext context) {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1B3B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Comment appliquer cela aujourd\'hui ?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Note 3 actions concrètes que tu peux prendre aujourd\'hui (3 max)',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            
            // 3 champs de texte avec puces
            _buildBulletField(c1, '1.'),
            const SizedBox(height: 12),
            _buildBulletField(c2, '2.'),
            const SizedBox(height: 12),
            _buildBulletField(c3, '3.'),
            const SizedBox(height: 24),
            
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final responses = [
                    c1.text.trim(),
                    c2.text.trim(),
                    c3.text.trim(),
                  ].where((text) => text.isNotEmpty).toList();
                  
                  Navigator.pop(context, responses);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Enregistrer',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
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

/// Widget pour un champ de texte avec puce
Widget _buildBulletField(TextEditingController controller, String bullet) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: '$bullet ...',
        hintStyle: GoogleFonts.inter(color: Colors.white54),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );
}



