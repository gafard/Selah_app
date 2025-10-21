import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bible_context_service.dart';
import '../services/cross_ref_service.dart';
import '../services/lexicon_service.dart';
import '../services/themes_service.dart';
import '../services/mirror_verse_service.dart';
import '../services/version_compare_service.dart';
import '../services/reading_memory_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LANCEUR DU MENU (depuis un verset surligné)
/// ═══════════════════════════════════════════════════════════════════════════

/// Appelle ceci quand l'utilisateur surligne / long-press un verset
Future<void> showReadingActions(BuildContext context, String verseId) async {
  HapticFeedback.selectionClick();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => ReadingActionSheet(verseId: verseId),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// BOTTOM SHEET PRINCIPAL (aligné design gradient + glass)
/// ═══════════════════════════════════════════════════════════════════════════

class ReadingActionSheet extends StatelessWidget {
  final String verseId; // ex: "Jean.3.16"
  const ReadingActionSheet({super.key, required this.verseId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gradient fond
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
                ),
              ),
            ),
            // Glass overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _handle(),
                        const SizedBox(height: 8),
                        _title('Outils d\'étude', subtitle: verseId.replaceAll('.', ' ')),
                        const SizedBox(height: 6),

                        // 1) Références croisées
                        _action(
                          context,
                          icon: Icons.link_rounded,
                          label: 'Références croisées',
                          onTap: () async {
                            context.pop();
                            await _showCrossRefs(context, verseId);
                          },
                        ),

                        // 2) Analyse lexicale
                        _action(
                          context,
                          icon: Icons.translate_rounded,
                          label: 'Analyse lexicale (hébreu/grec)',
                          onTap: () async {
                            context.pop();
                            await _showLexicon(context, verseId);
                          },
                        ),

                        // 3) Verset miroir
                        _action(
                          context,
                          icon: Icons.compare_arrows_rounded,
                          label: 'Verset miroir',
                          onTap: () async {
                            context.pop();
                            await _showMirror(context, verseId);
                          },
                        ),

                        // 4) Thèmes spirituels
                        _action(
                          context,
                          icon: Icons.auto_awesome_rounded,
                          label: 'Thèmes spirituels',
                          onTap: () async {
                            context.pop();
                            await _showThemes(context, verseId);
                          },
                        ),

                        // 5) Comparer avec d'autres versions (désactivé si 1 seule)
                        FutureBuilder<List<String>>(
                          future: VersionCompareService.availableVersions(),
                          builder: (c, snap) {
                            final enabled = (snap.data ?? const []).length >= 2;
                            return _action(
                              context,
                              icon: Icons.view_week_rounded,
                              label: 'Comparer avec d\'autres versions',
                              enabled: enabled,
                              onTap: enabled
                                  ? () async {
                                      context.pop();
                                      await _showCompare(context, verseId);
                                    }
                                  : null,
                            );
                          },
                        ),

                        // 6) Contexte historique
                        _action(
                          context,
                          icon: Icons.history_edu_rounded,
                          label: 'Contexte historique',
                          onTap: () async {
                            context.pop();
                            await _showContext(context, verseId, type: _ContextType.historical);
                          },
                        ),

                        // 7) Contexte culturel
                        _action(
                          context,
                          icon: Icons.public_rounded,
                          label: 'Contexte culturel',
                          onTap: () async {
                            context.pop();
                            await _showContext(context, verseId, type: _ContextType.cultural);
                          },
                        ),

                        // 8) Auteur / personnages
                        _action(
                          context,
                          icon: Icons.group_rounded,
                          label: 'Auteur / personnages',
                          onTap: () async {
                            context.pop();
                            await _showContext(context, verseId, type: _ContextType.author);
                          },
                        ),

                        // 9) Mémoriser ce passage
                        _action(
                          context,
                          icon: Icons.bookmark_add_rounded,
                          label: 'Mémoriser ce passage',
                          onTap: () async {
                            context.pop();
                            await ReadingMemoryService.queueMemoryVerse(verseId);
                            _toast(context, 'Ajouté à mémorisation');
                          },
                        ),

                        const SizedBox(height: 10),
                      ],
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

  Widget _handle() => Container(
    width: 44,
    height: 5,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.35),
      borderRadius: BorderRadius.circular(100),
    ),
  );

  Widget _title(String t, {String? subtitle}) => Column(
    children: [
      Text(
        t,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ]
    ],
  );

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final fg = enabled ? Colors.white : Colors.white38;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(.2)),
              ),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: fg),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext c, String msg) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEUILLES SECONDAIRES (affichages offline)
/// ═══════════════════════════════════════════════════════════════════════════

enum _ContextType { historical, cultural, author }

// A) Références croisées
Future<void> _showCrossRefs(BuildContext context, String id) async {
  final refs = await CrossRefService.crossRefs(id); // ["Luc.6.20", ...]
  await _openSheet(
    context,
    title: 'Références croisées',
    body: refs.isEmpty
        ? _empty('Aucune référence locale')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: refs
                .map((rid) => _pill(
                      context,
                      rid,
                      onTap: () {
                                      context.pop();
                        // -> Naviguer dans le lecteur vers rid
                        _toast(context, 'Navigation vers ${rid.replaceAll('.', ' ')}');
                      },
                    ))
                .toList(),
          ),
  );
}

// B) Lexique
Future<void> _showLexicon(BuildContext context, String id) async {
  final items = await LexiconService.lexemes(id); // List<Lexeme>
  await _openSheet(
    context,
    title: 'Analyse lexicale',
    body: items.isEmpty
        ? _empty('Aucun item lexical local')
        : Column(
            children: items.map((lex) => _lexRow(lex.toJson())).toList(),
          ),
  );
}

Widget _lexRow(Map<String, dynamic> m) => Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${m['lemma']} (${m['lang']})",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${m['gloss']}",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

// C) Verset miroir
Future<void> _showMirror(BuildContext context, String id) async {
  final mirror = await MirrorVerseService.mirrorOf(id); // "Jean.1.29"
  await _openSheet(
    context,
    title: 'Verset miroir',
    body: mirror == null
        ? _empty('Aucun miroir local')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pill(context, id),
              const SizedBox(height: 8),
              const Icon(Icons.sync_alt, color: Colors.white70, size: 24),
              const SizedBox(height: 8),
              _pill(
                context,
                mirror,
                primary: true,
                onTap: () {
                                      context.pop();
                  // -> Aller au verset miroir
                  _toast(context, 'Navigation vers ${mirror.replaceAll('.', ' ')}');
                },
              ),
            ],
          ),
  );
}

// D) Thèmes
Future<void> _showThemes(BuildContext context, String id) async {
  final themes = await ThemesService.themes(id); // ["humilité","béatitudes"]
  await _openSheet(
    context,
    title: 'Thèmes spirituels',
    body: themes.isEmpty
        ? _empty('Aucun thème local')
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: themes.map((t) => _chip(t)).toList(),
          ),
  );
}

Widget _chip(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.2)),
      ),
      child: Text(t, style: GoogleFonts.inter(color: Colors.white)),
    );

// E) Comparer versions
Future<void> _showCompare(BuildContext context, String id) async {
  final rows = await VersionCompareService.sideBySide(id);
  await _openSheet(
    context,
    title: 'Comparer les versions',
    body: rows.isEmpty
        ? _empty('Une seule version locale')
        : Column(
            children: rows.map((r) => _compareRow(r)).toList(),
          ),
  );
}

Widget _compareRow(VersionText r) => Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.version,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            r.text,
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ],
      ),
    );

// F) Contexte (historique / culturel / auteur)
Future<void> _showContext(
  BuildContext context,
  String id, {
  required _ContextType type,
}) async {
  String title = 'Contexte';
  String? text;

  switch (type) {
    case _ContextType.historical:
      title = 'Contexte historique';
      text = await BibleContextService.historical(id);
      break;
    case _ContextType.cultural:
      title = 'Contexte culturel';
      text = await BibleContextService.cultural(id);
      break;
    case _ContextType.author:
      title = 'Auteur / personnages';
      final author = await BibleContextService.author(id);
      if (author != null) {
        text = '${author.name}\n\n${author.shortBio}\n\nRôle : ${author.role}';
        if (author.timeline != null) {
          text += '\nÉpoque : ${author.timeline}';
        }
      }
      break;
  }

  await _openSheet(
    context,
    title: title,
    body: text == null || text.isEmpty
        ? _empty('Donnée non disponible localement')
        : Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CONTENEUR DE FEUILLE SECONDAIRE (même design)
/// ═══════════════════════════════════════════════════════════════════════════

Future<void> _openSheet(
  BuildContext context, {
  required String title,
  required Widget body,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.35),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: SingleChildScrollView(child: body)),
                        ],
                      ),
                    ),
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

Widget _pill(
  BuildContext c,
  String id, {
  bool primary = false,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: primary ? Colors.white : Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.2)),
      ),
      child: Text(
        id.replaceAll('.', ' '),
        style: GoogleFonts.inter(
          color: primary ? const Color(0xFF1C1740) : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget _empty(String txt) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          txt,
          style: GoogleFonts.inter(color: Colors.white54),
        ),
      ),
    );

void _toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HOOK "MARQUER COMME LU" → "RETENU DE MA LECTURE"
/// ═══════════════════════════════════════════════════════════════════════════

/// À déclencher à la place de l'ancien flux Poster immédiat
Future<void> promptRetainedThenMarkRead(
  BuildContext context,
  String verseId,
) async {
  final controller = TextEditingController();
  final addToJournal = ValueNotifier<bool>(true);
  final addToWall = ValueNotifier<bool>(false);

  await _openSheet(
    context,
    title: 'Ce que j\'ai retenu',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Écris en 1–3 phrases ce que Dieu t\'a dit aujourd\'hui…',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(.06),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(.18)),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(.18)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _toggle('Ajouter au Journal', addToJournal),
        const SizedBox(height: 6),
        _toggle('Ajouter au Mur spirituel', addToWall),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () async {
              final retained = controller.text.trim();
              
              if (retained.isEmpty) {
                _toast(context, '⚠️ Veuillez saisir votre rétention');
                return;
              }
              
              await ReadingMemoryService.saveRetention(
                id: verseId,
                retained: retained,
                date: DateTime.now(),
                addToJournal: addToJournal.value,
                addToWall: addToWall.value,
              );
              
                                      context.pop();
              _toast(context, '✅ Rétention enregistrée');
              
              // Ici : marquer comme lu (progress local)
              // await _saveReadingProgress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C1740),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Enregistrer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        )
      ],
    ),
  );
}

Widget _toggle(String label, ValueNotifier<bool> noti) {
  return ValueListenableBuilder<bool>(
    valueListenable: noti,
    builder: (_, v, __) => InkWell(
      onTap: () => noti.value = !v,
      child: Row(
        children: [
          Checkbox(
            value: v,
            onChanged: (nv) => noti.value = nv ?? v,
            activeColor: Colors.white,
            checkColor: const Color(0xFF1C1740),
            side: const BorderSide(color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}




