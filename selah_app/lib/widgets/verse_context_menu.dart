import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/verse_key.dart';
import '../services/bible_context_service.dart';
import '../services/cross_ref_service.dart';
import '../services/lexicon_service.dart';
import '../services/themes_service.dart';
import '../services/mirror_verse_service.dart';
import '../services/version_compare_service.dart';
import '../services/reading_memory_service.dart';

/// Menu contextuel pour un verset sélectionné
/// 
/// Affiche les 9 actions d'étude biblique :
/// 1. Références croisées
/// 2. Analyse lexicale (grec/hébreu)
/// 3. Verset miroir
/// 4. Thèmes spirituels
/// 5. Comparer versions
/// 6. Contexte historique
/// 7. Contexte culturel
/// 8. Auteur / Personnages
/// 9. Mémoriser ce passage
class VerseContextMenu {
  
  /// Affiche le menu contextuel
  /// 
  /// [context] : BuildContext
  /// [verseId] : ID du verset (ex: "Jean.3.16")
  /// [verseText] : Texte du verset
  static Future<void> show({
    required BuildContext context,
    required String verseId,
    required String verseText,
  }) async {
    // Vérifier si comparaison de versions possible
    final canCompare = await VersionCompareService.canCompare();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(verseId),
            const Divider(height: 24),
            
            // Actions
            _buildAction(
              context: context,
              icon: Icons.link,
              title: 'Références croisées',
              subtitle: 'Versets liés et parallèles',
              onTap: () => _showCrossRefs(context, verseId),
            ),
            
            _buildAction(
              context: context,
              icon: Icons.language,
              title: 'Analyse lexicale',
              subtitle: 'Grec / Hébreu original',
              onTap: () => _showLexicon(context, verseId),
            ),
            
            _buildAction(
              context: context,
              icon: Icons.compare_arrows,
              title: 'Verset miroir',
              subtitle: 'Typologie AT ↔️ NT',
              onTap: () => _showMirror(context, verseId),
            ),
            
            _buildAction(
              context: context,
              icon: Icons.label,
              title: 'Thèmes spirituels',
              subtitle: 'Concepts et enseignements',
              onTap: () => _showThemes(context, verseId),
            ),
            
            _buildAction(
              context: context,
              icon: Icons.compare,
              title: 'Comparer versions',
              subtitle: canCompare ? 'LSG, S21, BDS...' : 'Téléchargez d\'autres versions',
              enabled: canCompare,
              onTap: canCompare ? () => _showVersionCompare(context, verseId) : null,
            ),
            
            _buildAction(
              context: context,
              icon: Icons.history_edu,
              title: 'Contexte historique',
              subtitle: 'Époque et circonstances',
              onTap: () => _showHistoricalContext(context, verseId),
            ),
            
            _buildAction(
              context: context,
              icon: Icons.public,
              title: 'Contexte culturel',
              subtitle: 'Coutumes et culture',
              onTap: () => _showCulturalContext(context, verseId),
            ),
            
            _buildAction(
              context: context,
              icon: Icons.people,
              title: 'Auteur / Personnages',
              subtitle: 'Qui a écrit, qui est mentionné',
              onTap: () => _showAuthorAndCharacters(context, verseId),
            ),
            
            const Divider(height: 24),
            
            _buildAction(
              context: context,
              icon: Icons.bookmark_add,
              title: 'Mémoriser ce passage',
              subtitle: 'Ajouter à ma liste de mémorisation',
              color: const Color(0xFF4CAF50),
              onTap: () => _memorizeVerse(context, verseId),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════
  
  static Widget _buildHeader(String verseId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: Color(0xFF5C34D1), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Étudier ce passage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  verseId.replaceAll('.', ' '),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? color,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? (color ?? const Color(0xFF5C34D1)) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      enabled: enabled,
      onTap: enabled ? () {
        context.pop();
        onTap?.call();
      } : null,
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // ACTIONS - Affichage des BottomSheets spécifiques
  // ═══════════════════════════════════════════════════════════════
  
  static void _showCrossRefs(BuildContext context, String verseId) async {
    final refs = await CrossRefService.crossRefs(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CrossRefsBottomSheet(
        verseId: verseId,
        crossRefIds: refs,
      ),
    );
  }
  
  static void _showLexicon(BuildContext context, String verseId) async {
    final lexemes = await LexiconService.lexemes(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LexiconBottomSheet(
        verseId: verseId,
        lexemes: lexemes,
      ),
    );
  }
  
  static void _showMirror(BuildContext context, String verseId) async {
    final mirrorId = await MirrorVerseService.mirrorOf(verseId);
    
    if (!context.mounted) return;
    
    if (mirrorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun verset miroir trouvé')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MirrorVerseBottomSheet(
        originalId: verseId,
        mirrorId: mirrorId,
      ),
    );
  }
  
  static void _showThemes(BuildContext context, String verseId) async {
    final themes = await ThemesService.themes(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemesBottomSheet(
        verseId: verseId,
        themes: themes,
      ),
    );
  }
  
  static void _showVersionCompare(BuildContext context, String verseId) async {
    final versions = await VersionCompareService.sideBySide(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VersionCompareBottomSheet(
        verseId: verseId,
        versions: versions,
      ),
    );
  }
  
  static void _showHistoricalContext(BuildContext context, String verseId) async {
    final historical = await BibleContextService.historical(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContextBottomSheet(
        verseId: verseId,
        title: 'Contexte historique',
        icon: Icons.history_edu,
        content: historical ?? 'Aucun contexte historique disponible pour ce verset.',
      ),
    );
  }
  
  static void _showCulturalContext(BuildContext context, String verseId) async {
    final cultural = await BibleContextService.cultural(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContextBottomSheet(
        verseId: verseId,
        title: 'Contexte culturel',
        icon: Icons.public,
        content: cultural ?? 'Aucun contexte culturel disponible pour ce verset.',
      ),
    );
  }
  
  static void _showAuthorAndCharacters(BuildContext context, String verseId) async {
    final author = await BibleContextService.author(verseId);
    final characters = await BibleContextService.characters(verseId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthorCharactersBottomSheet(
        verseId: verseId,
        author: author,
        characters: characters,
      ),
    );
  }
  
  static void _memorizeVerse(BuildContext context, String verseId) async {
    // Dialog pour demander pourquoi mémoriser
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mémoriser ce passage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pourquoi voulez-vous mémoriser ${verseId.replaceAll('.', ' ')} ?'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Note personnelle (optionnel)...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => context.pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(''),
            child: const Text('Mémoriser'),
          ),
        ],
      ),
    );
    
    if (note != null && context.mounted) {
      await ReadingMemoryService.queueMemoryVerse(verseId, note: note.isEmpty ? null : note);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${verseId.replaceAll('.', ' ')} ajouté à votre liste de mémorisation'),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () {
                // TODO: Naviguer vers page mémorisation
              },
            ),
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM SHEETS SPÉCIALISÉS
// ═══════════════════════════════════════════════════════════════

/// BottomSheet pour les références croisées
class CrossRefsBottomSheet extends StatelessWidget {
  final String verseId;
  final List<String> crossRefIds;
  
  const CrossRefsBottomSheet({
    super.key,
    required this.verseId,
    required this.crossRefIds,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHandle(),
              _buildTitle('Références croisées', Icons.link),
              _buildSubtitle(verseId.replaceAll('.', ' ')),
              const Divider(),
              Expanded(
                child: crossRefIds.isEmpty
                  ? _buildEmpty('Aucune référence croisée disponible')
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: crossRefIds.length,
                      itemBuilder: (context, index) {
                        return _buildCrossRefTile(context, crossRefIds[index]);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildCrossRefTile(BuildContext context, String refId) {
    final ref = refId.replaceAll('.', ' ');
    
    return ListTile(
      leading: const Icon(Icons.link, color: Color(0xFF5C34D1)),
      title: Text(ref, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Appuyez pour voir le verset'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Ouvrir prévisualisation du verset
        _showVersePreview(context, refId);
      },
    );
  }
  
  void _showVersePreview(BuildContext context, String verseId) {
    // TODO: Implémenter prévisualisation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Prévisualisation de ${verseId.replaceAll('.', ' ')}')),
    );
  }
  
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  
  Widget _buildTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5C34D1)),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubtitle(String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet pour le lexique grec/hébreu
class LexiconBottomSheet extends StatelessWidget {
  final String verseId;
  final List<Lexeme> lexemes;
  
  const LexiconBottomSheet({
    super.key,
    required this.verseId,
    required this.lexemes,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(height: 24),
          
          if (lexemes.isEmpty)
            _buildEmpty()
          else
            ...lexemes.map((lex) => _buildLexemeTile(lex)),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.language, color: Color(0xFF5C34D1)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lexique',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Mots originaux grec/hébreu',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLexemeTile(Lexeme lex) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: lex.lang == 'grc' ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
        child: Text(
          lex.languageFlag,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        lex.lemma,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lex.languageName} • ${lex.gloss}',
            style: const TextStyle(fontSize: 14),
          ),
          if (lex.strongsNumber != null)
            Text(
              'Strong: ${lex.strongsNumber}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée lexicale disponible pour ce verset',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// BottomSheet pour verset miroir
class MirrorVerseBottomSheet extends StatelessWidget {
  final String originalId;
  final String mirrorId;
  
  const MirrorVerseBottomSheet({
    super.key,
    required this.originalId,
    required this.mirrorId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: Color(0xFF5C34D1)),
              SizedBox(width: 12),
              Text(
                'Verset miroir',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Verset original
          _buildVerseCard(originalId, true),
          
          // Flèche
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.sync_alt, size: 32, color: Color(0xFF5C34D1)),
          ),
          
          // Verset miroir
          _buildVerseCard(mirrorId, false),
          
          const SizedBox(height: 16),
          
          // Explication
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF9C27B0)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getExplanation(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildVerseCard(String verseId, bool isOriginal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOriginal ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOriginal ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verseId.replaceAll('.', ' '),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Texte du verset ici...', // TODO: Récupérer texte réel
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  String _getExplanation() {
    // TODO: Récupérer explication réelle
    if (originalId == 'Genèse.22.8' && mirrorId == 'Jean.1.29') {
      return 'L\'agneau que Dieu pourvoira (Isaac) préfigure l\'Agneau de Dieu (Jésus)';
    }
    return 'Ces versets s\'éclairent mutuellement par leur connexion typologique';
  }
}

/// BottomSheet pour les thèmes
class ThemesBottomSheet extends StatelessWidget {
  final String verseId;
  final List<String> themes;
  
  const ThemesBottomSheet({
    super.key,
    required this.verseId,
    required this.themes,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.label, color: Color(0xFF5C34D1)),
              SizedBox(width: 12),
              Text(
                'Thèmes spirituels',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verseId.replaceAll('.', ' '),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          
          if (themes.isEmpty)
            const Text('Aucun thème disponible')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themes.map((theme) => Chip(
                label: Text(theme),
                backgroundColor: const Color(0xFFE8EAF6),
                labelStyle: const TextStyle(
                  color: Color(0xFF5C34D1),
                  fontWeight: FontWeight.w600,
                ),
              )).toList(),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// BottomSheet pour comparer les versions
class VersionCompareBottomSheet extends StatelessWidget {
  final String verseId;
  final List<VersionText> versions;
  
  const VersionCompareBottomSheet({
    super.key,
    required this.verseId,
    required this.versions,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHandle(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.compare, color: Color(0xFF5C34D1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comparer versions',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            verseId.replaceAll('.', ' '),
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: versions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return _buildVersionTile(version);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildVersionTile(VersionText version) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C34D1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  version.version,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  version.versionName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            version.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// BottomSheet générique pour contexte (historique/culturel)
class ContextBottomSheet extends StatelessWidget {
  final String verseId;
  final String title;
  final IconData icon;
  final String content;
  
  const ContextBottomSheet({
    super.key,
    required this.verseId,
    required this.title,
    required this.icon,
    required this.content,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5C34D1)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verseId.replaceAll('.', ' '),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Divider(height: 24),
          
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          
          const SizedBox(height: 20),
          
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }
}

/// BottomSheet pour auteur et personnages
class AuthorCharactersBottomSheet extends StatelessWidget {
  final String verseId;
  final AuthorInfo? author;
  final List<Character> characters;
  
  const AuthorCharactersBottomSheet({
    super.key,
    required this.verseId,
    required this.author,
    required this.characters,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              const Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF5C34D1)),
                  SizedBox(width: 12),
                  Text(
                    'Auteur & Personnages',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                verseId.replaceAll('.', ' '),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              
              // Auteur
              if (author != null) ...[
                const Text(
                  'Auteur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAuthorCard(author!),
                const SizedBox(height: 24),
              ],
              
              // Personnages
              if (characters.isNotEmpty) ...[
                const Text(
                  'Personnages',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...characters.map((char) => _buildCharacterCard(char)),
              ],
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildAuthorCard(AuthorInfo author) {
    return Card(
      elevation: 0,
      color: const Color(0xFFE8EAF6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              author.role,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(author.shortBio),
            if (author.timeline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    author.timeline!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCharacterCard(Character character) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              character.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(character.description),
          ],
        ),
      ),
    );
  }
}


