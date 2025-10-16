import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // Temporairement désactivé
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import '../services/meditation_journal_service.dart';

class VersePosterPage extends StatefulWidget {
  const VersePosterPage({super.key});

  @override
  State<VersePosterPage> createState() => _VersePosterPageState();
}

class _VersePosterPageState extends State<VersePosterPage> {
  final _repaintKey = GlobalKey();
  int _grad = 0;
  late String _text;
  late String _ref;
  final _grads = const [
    [Color(0xFFFF9F1C), Color(0xFFFFBF69)], // orange
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // violet
    [Color(0xFF10B981), Color(0xFF34D399)], // vert
    [Color(0xFF3B82F6), Color(0xFF60A5FA)], // bleu
  ];

  @override
  void initState() {
    super.initState();
    // Initialiser avec des valeurs par défaut
    _text = 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.';
    _ref = 'Jean 3:16';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer les arguments passés via Navigator.pushReplacementNamed
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _text = (args['text'] as String?)?.trim() ?? _text;
    _ref = (args['ref'] as String?)?.trim() ?? _ref;
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    // Vérifier le statut des permissions
    var photosStatus = await Permission.photos.status;
    var storageStatus = await Permission.storage.status;
    
    // Demander les permissions si nécessaire
    if (photosStatus.isDenied || storageStatus.isDenied) {
      await Permission.photos
          .onDeniedCallback(() {
            // Permission refusée
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission refusée pour sauvegarder l\'image')),
            );
          })
          .onGrantedCallback(() {
            // Permission accordée
          })
          .onPermanentlyDeniedCallback(() {
            // Permission définitivement refusée
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission définitivement refusée. Veuillez l\'activer dans les paramètres.')),
            );
          })
          .request();
          
      await Permission.storage
          .onDeniedCallback(() {
            // Permission refusée
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission refusée pour accéder au stockage')),
            );
          })
          .onGrantedCallback(() {
            // Permission accordée
          })
          .onPermanentlyDeniedCallback(() {
            // Permission définitivement refusée
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission de stockage définitivement refusée. Veuillez l\'activer dans les paramètres.')),
            );
          })
          .request();
    }
    
    // Vérifier à nouveau après la demande
    photosStatus = await Permission.photos.status;
    storageStatus = await Permission.storage.status;
    
    if (photosStatus.isDenied || storageStatus.isDenied) {
      return;
    }

    final bytes = await _capturePng();
    if (bytes == null) return;
    
    // Utiliser share_plus pour partager l'image (alternative à la sauvegarde)
    await Share.shareXFiles([
      XFile.fromData(bytes, name: 'selah_verse_${DateTime.now().millisecondsSinceEpoch}.png', mimeType: 'image/png')
    ], text: 'Verset partagé depuis Selah');
    
    _saveToJournal(); // Sauvegarder dans le journal
    if (!mounted) return;
    
    // Naviguer vers la page de gratitude
    context.go('/gratitude');
  }

  Future<void> _share() async {
    final bytes = await _capturePng();
    if (bytes == null) return;
    final xFile = XFile.fromData(bytes, mimeType: 'image/png', name: 'selah_verse.png');
    await Share.shareXFiles([xFile], text: _ref);
    _saveToJournal(); // Sauvegarder dans le journal
    
    // Naviguer vers la page de gratitude
    context.go('/gratitude');
  }

  void _toCommunity() {
    _saveToJournal(); // Sauvegarder dans le journal
    context.go('/community/new-post', extra: {
      'imageFromPoster': true,
      'verseRef': _ref,
      'caption': _text,
    });
    // Note: Avec GoRouter, on ne peut pas utiliser .then() car context.go() retourne void
    // La navigation vers gratitude sera gérée par la page de destination
  }

  void _setAsWallpaper() {
    _saveToGallery(); // Pour l'instant, on sauvegarde puis l'utilisateur définit en fond
    _saveToJournal(); // Sauvegarder dans le journal
    // La navigation vers la page de gratitude se fait déjà dans _saveToGallery()
  }

  /// Sauvegarder cette session de méditation dans le journal
  Future<void> _saveToJournal() async {
    try {
      // Capturer l'image du poster
      final posterImageBytes = await _capturePng();
      
      // Récupérer les données de méditation depuis les arguments
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      final passageRef = (args['passageRef'] as String?)?.trim() ?? '';
      final passageText = (args['passageText'] as String?)?.trim() ?? '';
      final selectedTagsByField = (args['selectedTagsByField'] as Map<String, Set<String>>?) ?? {};
      final selectedAnswersByField = (args['selectedAnswersByField'] as Map<String, Set<String>>?) ?? {};
      final freeTextResponses = (args['freeTextResponses'] as Map<String, String>?) ?? {};
      
      // Déterminer le type de méditation
      final meditationType = freeTextResponses.values.any((text) => text.isNotEmpty) ? 'free' : 'qcm';
      
      // Extraire les sujets de prière et notes depuis les PrayerItems
      final prayerItems = (args['prayerItems'] as List<dynamic>?) ?? [];
      final prayerSubjects = <String>[];
      final prayerNotes = <String>[];
      
      for (final item in prayerItems) {
        final itemMap = item as Map<String, dynamic>;
        prayerSubjects.add('${itemMap['theme']}: ${itemMap['subject']}');
        if (itemMap['notes'] != null && (itemMap['notes'] as String).isNotEmpty) {
          prayerNotes.add(itemMap['notes'] as String);
        }
      }
      
      // Créer l'entrée du journal
      final entry = MeditationJournalService.createEntryFromMeditation(
        passageRef: passageRef,
        passageText: passageText,
        memoryVerse: _text,
        memoryVerseRef: _ref,
        prayerSubjects: prayerSubjects,
        prayerNotes: prayerNotes,
        gradientIndex: _grad % 4,
        posterImageBytes: posterImageBytes,
        meditationType: meditationType,
        meditationData: {
          'selectedTagsByField': selectedTagsByField.map((k, v) => MapEntry(k, v.toList())),
          'selectedAnswersByField': selectedAnswersByField.map((k, v) => MapEntry(k, v.toList())),
          'freeTextResponses': freeTextResponses,
        },
      );
      
      // Sauvegarder dans le journal
      await MeditationJournalService.saveEntry(entry);
      
      print('📖 SESSION SAUVEGARDÉE dans le journal: ${entry.passageRef} - ${entry.memoryVerseRef}');
    } catch (e) {
      print('❌ ERREUR lors de la sauvegarde dans le journal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _grads[_grad % _grads.length];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF1F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Changer le style',
            icon: const Icon(Icons.color_lens_outlined, color: Colors.black87),
            onPressed: () => setState(() => _grad++),
          )
        ],
        title: Text('Poster du verset', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Aperçu type mockup (arrondis + ombre)
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: AspectRatio(
                  aspectRatio: 9/16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 24, offset: const Offset(0, 12))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          // fond dégradé
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors,
                              ),
                            ),
                          ),
                          // grand coin arrondi blanc en bas (style ta ref)
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: double.infinity,
                              height: 90,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(topRight: Radius.circular(60)),
                              ),
                            ),
                          ),
                          // contenu
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 40, 28, 110),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // quotes
                                Text('"', style: GoogleFonts.inter(color: Colors.white, fontSize: 56, height: .6, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    _text,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 22,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _ref.isEmpty ? '' : _ref,
                                        style: GoogleFonts.inter(color: Colors.white.withOpacity(.9), letterSpacing: .4),
                                      ),
                                    ),
                                    // petite bulle % déco
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white.withOpacity(.6)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('Mem', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // bande d'actions style dock
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 78,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _dock('Partager', Icons.ios_share_rounded, _share),
                                  _dock('Galerie', Icons.download_rounded, _saveToGallery),
                                  _dock('Communauté', Icons.groups_rounded, _toCommunity),
                                  _dock('Écran veille', Icons.wallpaper_rounded, _setAsWallpaper),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _dock(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
