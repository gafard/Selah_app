import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bible_pack_manager.dart';

class BiblePacksPage extends StatefulWidget {
  const BiblePacksPage({super.key});

  @override
  State<BiblePacksPage> createState() => _BiblePacksPageState();
}

class _BiblePacksPageState extends State<BiblePacksPage> {
  Map<String, dynamic> _packStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackStats();
  }

  Future<void> _loadPackStats() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await BiblePackManager.getPackStats();
      setState(() {
        _packStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur chargement des packs', Icons.error, Colors.red);
    }
  }

  Future<void> _extractPack(String packId) async {
    setState(() => _isLoading = true);
    
    try {
      final success = await BiblePackManager.extractPack(packId);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _showSnackBar('Pack extrait avec succès !', Icons.check_circle, Colors.green);
          _loadPackStats(); // Recharger les stats
        } else {
          _showSnackBar('Échec de l\'extraction', Icons.error, Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erreur: $e', Icons.error, Colors.red);
      }
    }
  }

  Future<void> _removePack(String packId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le pack ?'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce pack ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await BiblePackManager.removePack(packId);
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Pack supprimé !', Icons.delete_forever, Colors.orange);
          _loadPackStats(); // Recharger les stats
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Erreur: $e', Icons.error, Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Packs Bibliques',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final packs = _packStats['packs'] as Map<String, dynamic>? ?? {};
    final total = _packStats['total'] as int? ?? 0;
    final extracted = _packStats['extracted'] as int? ?? 0;

    return Column(
      children: [
        // Statistiques
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packs Bibliques',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$extracted / $total packs extraits',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.folder_zip,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
        
        // Liste des packs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final packId = packs.keys.elementAt(index);
              final packData = packs[packId] as Map<String, dynamic>;
              
              return _buildPackCard(packId, packData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPackCard(String packId, Map<String, dynamic> packData) {
    final name = packData['name'] as String? ?? 'Pack inconnu';
    final description = packData['description'] as String? ?? '';
    final extracted = packData['extracted'] as bool? ?? false;
    final size = packData['size'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: extracted ? Colors.green.withOpacity(0.1) : Colors.blueGrey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: extracted ? Colors.green.withOpacity(0.3) : Colors.blueGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      if (extracted && size > 0)
                        Text(
                          'Taille: ${(size / 1024).toStringAsFixed(1)} KB',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                    ],
                  ),
                ),
                if (extracted)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.orange),
                        onPressed: () => _removePack(packId),
                      ),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _extractPack(packId),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: Text(
                      'Extraire',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
