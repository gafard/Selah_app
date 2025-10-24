import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' show Random;
import '../utils/prayer_subjects_mapper.dart';
import '../utils/verse_analyzer.dart';
import '../services/audio_player_service.dart';
import '../widgets/circular_audio_progress.dart';

class PrayerCarouselPage extends StatefulWidget {
  const PrayerCarouselPage({super.key});

  @override
  State<PrayerCarouselPage> createState() => _PrayerCarouselPageState();
}

class _PrayerCarouselPageState extends State<PrayerCarouselPage> {
  List<PrayerItem> _items = [];
  final int _currentIndex = 0;
  String _memoryVerse = ''; // Verset noté par l'utilisateur
  
  // Audio player
  late final AudioPlayerService _audio;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;


  // Fonction utilitaire pour récupérer les arguments GoRouter
  Map _readArgs(BuildContext context) {
    final goExtra = (GoRouterState.of(context).extra as Map?) ?? {};
    final modal = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    return {...modal, ...goExtra}; // go_router prioritaire
  }

  // Utilitaires responsive + rotation stable
  Size _responsiveCardSize(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;

    // Base: carte occupe ~70–80% en largeur/hauteur selon l'espace
    final cardW = (w * 0.78).clamp(280.0, 520.0);
    final cardH = (h * 0.70).clamp(360.0, 640.0);
    return Size(cardW, cardH);
  }

  /// rotation légère par index (constante, pas d'anim)
  double _tiltForIndex(int index) {
    final rnd = Random(index);          // seedé par l'index
    final deg = (rnd.nextDouble() - 0.5) * 4.0; // -2°..+2°
    return deg * 3.1415926535 / 180.0;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize audio player
    _audio = AudioPlayerService();
    _initAudio();
    
    // Récupérer les arguments passés lors de la navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = _readArgs(context);
      print('🔍 ARGUMENTS REÇUS: $args');
      print('🔍 TYPE: ${args.runtimeType}');
      
      if (args.containsKey('items')) {
        final itemsList = args['items'] as List;
        _memoryVerse = (args['memoryVerse'] as String?)?.trim() ?? '';
        setState(() { _items = itemsList.cast<PrayerItem>(); });
        print('🔍 ITEMS FINAUX: ${_items.length}');
        for (int i = 0; i < _items.length; i++) {
          print('🔍 Item $i: ${_items[i].theme} - ${_items[i].subject}');
        }
      } else if (args is List) {
        setState(() { _items = (args as List).cast<PrayerItem>(); });
        print('🔍 ITEMS FINAUX: ${_items.length}');
        for (int i = 0; i < _items.length; i++) {
          print('🔍 Item $i: ${_items[i].theme} - ${_items[i].subject}');
        }
      } else {
        setState(() { _items = _createTestPrayerItems(); });
        print('🔍 ARGUMENTS NON RECONNUS, UTILISATION DES ITEMS DE TEST');
      }
    });
  }

  List<PrayerItem> _createTestPrayerItems() {
    return [
      PrayerItem(
        theme: 'Gratitude',
        subject: 'Remerciez Dieu pour ses bénédictions dans votre vie',
        color: Colors.blue,
        validated: false,
        notes: '',
      ),
      PrayerItem(
        theme: 'Guérison',
        subject: 'Priez pour la guérison de vos proches malades',
        color: Colors.green,
        validated: false,
        notes: '',
      ),
      PrayerItem(
        theme: 'Sagesse',
        subject: 'Demandez la sagesse divine pour vos décisions',
        color: Colors.purple,
        validated: false,
        notes: '',
      ),
      PrayerItem(
        theme: 'Paix',
        subject: 'Priez pour la paix dans votre cœur et votre famille',
        color: Colors.orange,
        validated: false,
        notes: '',
      ),
    ];
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    try {
      // TODO: Replace with your actual audio URL (instrumental chill/lofi local asset or CDN)
      await _audio.init(url: Uri.parse('https://cdn.example.com/loops/lofi-01.mp3'));
      _audio.position$.listen((d) => setState(() => _pos = d));
      _audio.duration$.listen((d) => setState(() => _dur = d ?? Duration.zero));
    } catch (e) {
      // Handle audio initialization error silently
      print('Audio initialization failed: $e');
    }
  }

  void _toggleAudio() async {
    try {
      if (_audio.isPlaying) {
        await _audio.pause();
      } else {
        await _audio.play();
      }
      // HapticFeedback.lightImpact(); // Temporairement désactivé
    } catch (e) {
      _showSnackBar('Erreur audio', Icons.error, Colors.red);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$mm:$ss';
  }

  void _openInstrumentalsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final items = [
          ('Lo-fi 01', 'https://cdn.example.com/loops/lofi-01.mp3'),
          ('Piano Soft', 'https://cdn.example.com/loops/piano-soft.mp3'),
          ('Ambient Pad', 'https://cdn.example.com/loops/ambient-pad.mp3'),
        ];
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('Instrumentaux', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...items.map((it) => ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(it.$1, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text(Uri.parse(it.$2).pathSegments.last, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                onTap: () async {
                  await _audio.init(url: Uri.parse(it.$2));
                  await _audio.play();
                  if (mounted) context.pop();
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Sujets de Prière',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez pour griser • Glissez pour passer à la suivante',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cartes avec CardSwiper - Version responsive
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardSize = _responsiveCardSize(constraints);
                      return Center(
                        child: CardSwiper(
                          cardsCount: _items.length,
                          isLoop: false, // Pas de boucle - finir quand toutes les cartes sont swipées
                          cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                            return _buildPrayerCard(_items[index], index, cardSize);
                          },
                          // onSwipe: _onCardSwiped, // Temporairement désactivé pour la compatibilité
                          onEnd: () {
                            // Quand toutes les cartes sont swipées, afficher la page de succès
                            debugPrint('Toutes les cartes ont été swipées - Prière terminée !');
                            _showSuccessPage();
                            return true;
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Section audio
              _buildAudioSection(),
              
              // Indicateurs de pagination
              if (_items.length > 1) _buildPageIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerItem item, int index, Size cardSize) {
    final isValidated = item.validated;

    // palette papier (tes couleurs déjà OK)
    final paperColors = [
      Colors.yellow[200]!, Colors.pink[200]!, Colors.green[200]!,
      Colors.blue[200]!, Colors.orange[200]!, Colors.purple[200]!,
      Colors.lime[200]!, Colors.cyan[200]!,
    ];
    final cardColor = paperColors[index % paperColors.length];

    // légère rotation statique
    final tilt = _tiltForIndex(index);

    return Transform.rotate(
      angle: tilt,
      child: GestureDetector(
        onTap: () => _toggleValidate(index),
        child: ColorFiltered(
          colorFilter: isValidated
              ? const ColorFilter.matrix(<double>[
                  // désat. simple
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Container(
            width: cardSize.width,
            height: cardSize.height,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10), // post-it = coins peu arrondis
              boxShadow: [
                // ombre principale
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
                // ombre de proximité
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // grain + lignes légères (tu avais PaperTexturePainter)
                Positioned.fill(child: CustomPaint(painter: PaperTexturePainter())),

                // bande washi (adhésif) au sommet
                Positioned(
                  top: 8,
                  left: 30,
                  right: 30,
                  child: CustomPaint(
                    painter: WashiTapePainter(),
                    child: const SizedBox(height: 22),
                  ),
                ),

                // petit coin replié en bas à droite
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    painter: FoldedCornerPainter(color: cardColor),
                    child: const SizedBox(width: 46, height: 46),
                  ),
                ),

                // contenu
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 38, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "épingle" visuelle = petit rond foncé + icône check/tap
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.theme.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.caveat(
                                color: Colors.black87,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                decoration: isValidated
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: Colors.black,
                                decorationThickness: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(isValidated ? Icons.check : Icons.touch_app,
                              size: 18, color: Colors.black87),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // sujet (scroll si très long)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            item.subject,
                            style: GoogleFonts.kalam(
                              color: Colors.black87,
                              fontSize: 22,
                              height: 1.25,
                              decoration: isValidated
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.black,
                              decorationThickness: 2.0,
                            ),
                          ),
                        ),
                      ),

                      // notes si présentes
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ce que Dieu me dit :',
                                  style: GoogleFonts.caveat(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                item.notes,
                                style: GoogleFonts.kalam(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // bande d'action "post-it" (noir tranchait bcp; on reste papier)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showNotesDialog(index),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (item.notes.isNotEmpty
                                          ? Colors.green[700]
                                          : Colors.blue[700])
                                      ?.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.notes.isNotEmpty
                                          ? 'MODIFIER'
                                          : 'ÉCRIRE',
                                      style: GoogleFonts.caveat(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (item.notes.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.edit,
                                          size: 16, color: Colors.white),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isValidated ? 'VALIDÉ' : 'TAPER POUR VALIDER',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.caveat(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAudioSection() {
    final progress = _dur.inMilliseconds == 0
        ? 0.0
        : _pos.inMilliseconds / _dur.inMilliseconds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircularAudioProgress(
            progress: progress.clamp(0.0, 1.0),
            size: 50,
            progressColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.3),
            icon: (_dur > Duration.zero && _pos < _dur) ? Icons.pause : Icons.play_arrow,
            onTap: _toggleAudio,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrumental • Focus', 
                  style: GoogleFonts.inter(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.white
                  )
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _dur.inMilliseconds == 0 ? null : progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(_pos), 
                      style: GoogleFonts.inter(
                        fontSize: 10, 
                        color: Colors.white70
                      )
                    ),
                    Text(
                      _fmt(_dur), 
                      style: GoogleFonts.inter(
                        fontSize: 10, 
                        color: Colors.white70
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openInstrumentalsSheet,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(
                Icons.library_music, 
                color: Colors.white, 
                size: 18
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.validated 
                ? Colors.green 
                : (index == _currentIndex ? Colors.white : Colors.white30),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _toggleValidate(int index) {
    setState(() {
      _items[index].validated = !_items[index].validated;
    });
  }


  void _showSuccessPage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Prière Terminée !',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Vous avez terminé tous vos sujets de prière. Que Dieu vous bénisse !',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Bouton Terminer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermer le dialog
                      _finishPrayer(); // Appeler la nouvelle méthode
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Terminer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotesDialog(int index) {
    final item = _items[index];
    final TextEditingController notesController = TextEditingController(text: item.notes);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                Text(
                  'Ce que Dieu me dit',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Sujet de prière
                Text(
                  item.subject,
                  style: GoogleFonts.kalam(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Zone de texte
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: notesController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: GoogleFonts.kalam(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écrivez ce que Dieu vous révèle...',
                      hintStyle: GoogleFonts.kalam(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _items[index].notes = notesController.text;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Sauvegarder',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _finishPrayer() async {
    // 1) Sauvegarde (ex: Supabase) — pseudo-code
    // await supabase.from('prayers').insert({
    //   'user_id': userId,
    //   'plan_id': planId,
    //   'day_number': dayNumber,
    //   'content': _prayerController.text.trim(),
    //   'subjects': _selectedSubjects, // si tu les enregistres
    // });

    // 2) Récupère le verset à mémoriser depuis la méditation
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final passageRef = (args['passageRef'] as String?)?.trim() ?? '';
    final passageText = (args['passageText'] as String?)?.trim() ?? '';
    final selectedTagsByField = (args['selectedTagsByField'] as Map<String, Set<String>>?) ?? {};
    final selectedAnswersByField = (args['selectedAnswersByField'] as Map<String, Set<String>>?) ?? {};
    final freeTextResponses = (args['freeTextResponses'] as Map<String, String>?) ?? {};

    // 3) Utiliser la fonction intelligente pour déterminer le verset final
    Map<String, String> finalVerse;
    
    if (_memoryVerse.isNotEmpty) {
      // Si l'utilisateur a saisi du texte, analyser pour trouver le verset exact
      finalVerse = VerseAnalyzer.analyzeUserText(_memoryVerse);
      print('🔍 VERSET ANALYSÉ depuis le texte saisi: "${finalVerse['text']}" (${finalVerse['ref']})');
    } else {
      // Si l'utilisateur a passé, utiliser les réponses de méditation pour choisir intelligemment
      finalVerse = VerseAnalyzer.chooseVerseFromMeditation(
        selectedTagsByField: selectedTagsByField,
        selectedAnswersByField: selectedAnswersByField,
        freeTextResponses: freeTextResponses,
        passageRef: passageRef,
        passageText: passageText,
      );
      print('🔍 VERSET CHOISI depuis la méditation: "${finalVerse['text']}" (${finalVerse['ref']})');
    }

    // 4) Enchaîne vers le poster avec le verset final et toutes les données
    context.go('/verse_poster', extra: {
      'text': finalVerse['text']!,
      'ref': finalVerse['ref']!,
      'passageRef': passageRef,
      'passageText': passageText,
      'selectedTagsByField': selectedTagsByField,
      'selectedAnswersByField': selectedAnswersByField,
      'freeTextResponses': freeTextResponses,
      'prayerItems': _items.map((item) => {
        'theme': item.theme,
        'subject': item.subject,
        'notes': item.notes,
      }).toList(),
    });
  }

}

class PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Lignes de texture papier horizontales
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Lignes de texture papier verticales
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Points de texture aléatoires
    final random = Random(42); // Seed fixe pour cohérence
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.05;
      
      canvas.drawCircle(
        Offset(x, y),
        0.5,
        Paint()..color = Colors.black.withOpacity(opacity),
      );
    }

    // Ombres de pliure
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Ligne de pliure diagonale
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      shadowPaint,
    );

    // Ligne de pliure horizontale
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.3),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WashiTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF3A6).withOpacity(0.9); // beige tape

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(r, base);

    // motif strié léger
    final stripe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withOpacity(0.06);

    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 12, size.height), stripe);
    }

    // ombre douce
    canvas.drawShadow(Path()..addRRect(r), Colors.black.withOpacity(0.25), 6, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FoldedCornerPainter extends CustomPainter {
  final Color color;
  FoldedCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // triangle du coin replié
    final path = Path()
      ..moveTo(w, h)
      ..lineTo(0, h)
      ..lineTo(w, 0)
      ..close();

    final base = Paint()..color = color.withOpacity(0.95);
    canvas.drawPath(path, base);

    // ombre du pli
    final edge = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w, 0), Offset(0, h), edge);

    // reflet
    final highlight = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w - 1.5, 0), Offset(0, h - 1.5), highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}