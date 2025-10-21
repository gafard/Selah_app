import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/bible_version_manager.dart';

/// Page de gestion des versions de Bible
class BibleVersionsPage extends StatefulWidget {
  const BibleVersionsPage({super.key});

  @override
  State<BibleVersionsPage> createState() => _BibleVersionsPageState();
}

class _BibleVersionsPageState extends State<BibleVersionsPage> {
  final Map<String, bool> _downloadStatus = {};
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await BibleVersionManager.getDownloadStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Versions de Bible',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Versions françaises', Icons.flag),
                  const SizedBox(height: 16),
                  _buildVersionsList(BibleVersionManager.getFrenchVersions()),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Versions anglaises', Icons.language),
                  const SizedBox(height: 16),
                  _buildVersionsList(BibleVersionManager.getEnglishVersions()),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                'Versions',
                '${_stats!['downloaded_versions']}',
                Icons.library_books,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                'Versets',
                '${_stats!['total_verses']}',
                Icons.format_quote,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                'Livres',
                '${_stats!['total_books']}',
                Icons.book,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionsList(Map<String, Map<String, String>> versions) {
    return Column(
      children: versions.entries.map((entry) {
        final versionId = entry.key;
        final version = entry.value;
        final isDownloaded = _stats?['versions']?.any(
              (v) => v['id'] == versionId,
            ) ?? false;

        return _buildVersionCard(versionId, version, isDownloaded);
      }).toList(),
    );
  }

  Widget _buildVersionCard(
    String versionId,
    Map<String, String> version,
    bool isDownloaded,
  ) {
    final isDownloading = _downloadStatus[versionId] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDownloaded
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDownloaded
                  ? Colors.green.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDownloaded
                  ? Icons.check_circle
                  : isDownloading
                      ? Icons.downloading
                      : Icons.download,
              color: isDownloaded
                  ? Colors.green
                  : isDownloading
                      ? Colors.blue
                      : Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Informations de la version
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
                const SizedBox(height: 4),
                Text(
                  version['description']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.language,
                      size: 14,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      version['language']!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bouton d'action
          if (!isDownloaded && !isDownloading)
            ElevatedButton(
              onPressed: () => _downloadVersion(versionId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Télécharger',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isDownloading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          else
            IconButton(
              onPressed: () => _removeVersion(versionId),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadVersion(String versionId) async {
    setState(() {
      _downloadStatus[versionId] = true;
    });

    try {
      final versions = BibleVersionManager.getAvailableVersions();
      final version = versions[versionId];
      
      if (version == null) {
        throw Exception('Version non trouvée');
      }

      bool success;
      if (version['language'] == 'fr') {
        success = await BibleVersionManager.downloadVideoPsalmVersion(versionId);
      } else {
        success = await BibleVersionManager.downloadOpenBibleVersion(versionId);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${version['name']} téléchargée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats(); // Recharger les statistiques
      } else {
        throw Exception('Échec du téléchargement');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _downloadStatus[versionId] = false;
      });
    }
  }

  Future<void> _removeVersion(String versionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Supprimer la version',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette version ?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BibleVersionManager.removeVersion(versionId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Version supprimée'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadStats(); // Recharger les statistiques
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
