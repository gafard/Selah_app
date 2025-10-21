import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget réutilisable pour sélectionner une version de Bible
class BibleVersionSelector extends StatefulWidget {
  final String? selectedVersion;
  final Function(String) onVersionChanged;
  final String? label;
  final bool showLabel;

  const BibleVersionSelector({
    super.key,
    this.selectedVersion,
    required this.onVersionChanged,
    this.label,
    this.showLabel = true,
  });

  @override
  State<BibleVersionSelector> createState() => _BibleVersionSelectorState();
}

class _BibleVersionSelectorState extends State<BibleVersionSelector> {
  List<Map<String, String>> _availableVersions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableVersions();
  }

  Future<void> _loadAvailableVersions() async {
    try {
      // ✅ VERSIONS DISPONIBLES (4 versions intégrées)
      final availableVersions = [
        {'id': 'lsg1910', 'name': 'Louis Segond 1910', 'language': 'fr', 'source': 'assets'},
        {'id': 'francais_courant', 'name': 'Français Courant', 'language': 'fr', 'source': 'assets'},
        {'id': 'semeur', 'name': 'Bible du Semeur', 'language': 'fr', 'source': 'assets'},
        {'id': 'nouvelle_segond', 'name': 'Nouvelle Bible Segond', 'language': 'fr', 'source': 'assets'},
        {'id': 'oecumenique', 'name': 'Œcuménique de la Bible', 'language': 'fr', 'source': 'assets'},
      ];
      
      setState(() {
        _availableVersions = availableVersions;
        _isLoading = false;
      });
      
      print('✅ Versions chargées: ${availableVersions.length} versions disponibles');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('⚠️ Erreur chargement versions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_availableVersions.isEmpty) {
      return Container(
        height: 48, // ✅ Même hauteur que les autres containers
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Aucune version disponible',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final currentVersion = _availableVersions.firstWhere(
      (v) => v['id'] == widget.selectedVersion,
      orElse: () => _availableVersions.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _showVersionSelector,
          child: Container(
            height: 48, // ✅ Même hauteur que les autres containers
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  currentVersion['name']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showVersionSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // ✅ Limiter la hauteur
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Header fixe
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Choisir une version de Bible',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            // ✅ Liste scrollable
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableVersions.length,
                itemBuilder: (context, index) {
                  final version = _availableVersions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildVersionOption(version),
                  );
                },
              ),
            ),
            // ✅ Bouton fixe en bas
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionOption(Map<String, String> version) {
    final isSelected = version['id'] == widget.selectedVersion;
    
    return GestureDetector(
      onTap: () {
        widget.onVersionChanged(version['id']!);
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.blue
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version['name']!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    version['language']!.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
