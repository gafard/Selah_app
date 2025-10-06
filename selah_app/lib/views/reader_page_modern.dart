import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/reader_settings_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/highlightable_text.dart';
import '../widgets/circular_audio_progress.dart';

class ReaderPageModern extends StatefulWidget {
  final String? passageRef;
  final String? passageText;
  final String? dayTitle;
  
  const ReaderPageModern({
    super.key,
    this.passageRef,
    this.passageText,
    this.dayTitle,
  });

  @override
  State<ReaderPageModern> createState() => _ReaderPageModernState();
}

class _ReaderPageModernState extends State<ReaderPageModern>
    with TickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isMarkedAsRead = false;
  late AnimationController _buttonAnimationController;
  String _notedVerse = ''; // Verset noté par l'utilisateur
  
  // Audio player
  late final AudioPlayerService _audio;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  
  // Default passage data
  late final String _passageRef;
  late final String _passageText;
  late final String _dayTitle;

  @override
  void initState() {
    super.initState();
    
    // Initialize passage data with defaults or arguments
    _passageRef = widget.passageRef ?? 'Jean 14:1-19';
    _passageText = widget.passageText ?? '''Que votre cœur ne se trouble point. Croyez en Dieu, et croyez en moi.

Il y a plusieurs demeures dans la maison de mon Père. Si cela n'était pas, je vous l'aurais dit. Je vais vous préparer une place.

Et, lorsque je m'en serai allé, et que je vous aurai préparé une place, je reviendrai, et je vous prendrai avec moi, afin que là où je suis vous y soyez aussi.

Vous savez où je vais, et vous en savez le chemin.

Thomas lui dit: Seigneur, nous ne savons où tu vas; comment pouvons-nous en savoir le chemin?

Jésus lui dit: Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.

Si vous me connaissiez, vous connaîtriez aussi mon Père. Et dès maintenant vous le connaissez, et vous l'avez vu.

Philippe lui dit: Seigneur, montre-nous le Père, et cela nous suffit.

Jésus lui dit: Il y a si longtemps que je suis avec vous, et tu ne m'as pas connu, Philippe! Celui qui m'a vu a vu le Père; comment dis-tu: Montre-nous le Père?

Ne crois-tu pas que je suis dans le Père, et que le Père est en moi? Les paroles que je vous dis, je ne les dis pas de moi-même; et le Père qui demeure en moi, c'est lui qui fait les œuvres.

Croyez-moi, je suis dans le Père, et le Père est en moi; croyez du moins à cause de ces œuvres.

En vérité, en vérité, je vous le dis, celui qui croit en moi fera aussi les œuvres que je fais, et il en fera de plus grandes, parce que je m'en vais au Père;

et tout ce que vous demanderez en mon nom, je le ferai, afin que le Père soit glorifié dans le Fils.

Si vous demandez quelque chose en mon nom, je le ferai.

Si vous m'aimez, gardez mes commandements.

Et moi, je prierai le Père, et il vous donnera un autre consolateur, afin qu'il demeure éternellement avec vous,

l'Esprit de vérité, que le monde ne peut recevoir, parce qu'il ne le voit point et ne le connaît point; mais vous, vous le connaissez, car il demeure avec vous, et il sera en vous.

Je ne vous laisserai pas orphelins, je viendrai à vous.

Encore un peu de temps, et le monde ne me verra plus; mais vous, vous me verrez, car je vis, et vous vivrez aussi.''';
    _dayTitle = widget.dayTitle ?? 'Jour 15';
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Initialize audio player
    _audio = AudioPlayerService();
    _initAudio();
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
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
      HapticFeedback.lightImpact();
    } catch (e) {
      _showSnackBar('Erreur audio', Icons.error, Colors.red);
    }
  }


  void _markAsRead() {
    setState(() {
      _isMarkedAsRead = !_isMarkedAsRead;
    });
    HapticFeedback.mediumImpact();
    
    if (_isMarkedAsRead) {
      // Afficher le bottom sheet pour noter le verset marquant
      _showVerseNoteBottomSheet();
    } else {
      _showSnackBar(
        'Marqué comme non lu',
        Icons.radio_button_unchecked,
        Colors.grey,
      );
    }
  }

  void _goToMeditation() {
    // Vérifier si le texte est marqué comme lu
    if (!_isMarkedAsRead) {
      _showSnackBar(
        'Veuillez d\'abord marquer le texte comme lu',
        Icons.info,
        Colors.orange,
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(
      context,
      '/meditation/chooser', // page avec 2 options
      arguments: {
        'passageRef': _passageRef,
        'passageText': _passageText,
        'memoryVerse': _notedVerse, // Verset noté par l'utilisateur
      },
    );
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

  String _findExactVerse(String userText) {
    // Use the dynamic passage text
    final fullPassage = _passageText;

    // Normaliser le texte utilisateur (supprimer espaces, ponctuation, majuscules)
    final normalizedUserText = userText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Diviser le passage en phrases/versets
    final sentences = fullPassage.split(RegExp(r'[.!?]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Chercher la correspondance la plus proche
    String bestMatch = '';
    int bestScore = 0;

    for (final sentence in sentences) {
      final normalizedSentence = sentence
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Calculer un score de similarité basique
      int score = 0;
      final userWords = normalizedUserText.split(' ');
      final sentenceWords = normalizedSentence.split(' ');

      for (final userWord in userWords) {
        if (userWord.length > 2) { // Ignorer les mots trop courts
          for (final sentenceWord in sentenceWords) {
            if (sentenceWord.contains(userWord) || userWord.contains(sentenceWord)) {
              score += userWord.length; // Plus le mot est long, plus il compte
            }
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = sentence;
      }
    }

    // Si on trouve une correspondance significative, la retourner
    if (bestScore > 10 && bestMatch.isNotEmpty) {
      return bestMatch;
    }

    // Sinon, retourner le texte utilisateur tel quel
    return userText;
  }

  void _showVerseNoteBottomSheet() {
    final TextEditingController verseController = TextEditingController(text: _notedVerse);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Notez le verset qui vous a marqué',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Recopiez simplement le texte qui vous a touché. Il sera utilisé pour créer votre poster.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Zone de texte
                Expanded(
                  child: TextField(
                    controller: verseController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écrivez le verset qui vous a marqué...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Passer',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final userText = verseController.text.trim();
                          if (userText.isNotEmpty) {
                            // Analyser le texte pour trouver le verset exact
                            final exactVerse = _findExactVerse(userText);
                            setState(() {
                              _notedVerse = exactVerse;
                            });
                            Navigator.of(context).pop();
                            _showSnackBar(
                              'Verset analysé et noté !',
                              Icons.check_circle,
                              Colors.green,
                            );
                          } else {
                            Navigator.of(context).pop();
                            _showSnackBar(
                              'Aucun texte saisi',
                              Icons.info,
                              Colors.orange,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sauvegarder',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildMainContent(),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.grey.shade700,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayTitle,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _passageRef,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/reader_settings'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: Colors.grey.shade700,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: _buildTextContent(),
          ),
          _buildBottomWidgets(),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Consumer<ReaderSettingsService>(
      builder: (context, settings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _passageRef,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 16),
              HighlightableText(
                text: _passageText,
                style: settings.getFontStyle(),
                textAlign: settings.getTextAlign(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomWidgets() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAudioSection(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    final progress = _dur.inMilliseconds == 0
        ? 0.0
        : _pos.inMilliseconds / _dur.inMilliseconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircularAudioProgress(
            progress: progress.clamp(0.0, 1.0),
            size: 60,
            progressColor: const Color(0xFFD77B04),
            backgroundColor: Colors.grey.shade300,
            icon: (_dur > Duration.zero && _pos < _dur) ? Icons.pause : Icons.play_arrow,
            onTap: _toggleAudio,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instrumental • Focus', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D))),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _dur.inMilliseconds == 0 ? null : progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFD77B04)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_pos), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                    Text(_fmt(_dur), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openInstrumentalsSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.library_music, color: Colors.white, size: 22),
            ),
          ),
        ],
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
                  if (mounted) Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _markAsRead,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _isMarkedAsRead ? Colors.green.shade600 : Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Marquer comme lu',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _goToMeditation,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _isMarkedAsRead ? Colors.black : Colors.grey[400],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Méditation',
                    style: GoogleFonts.inter(
                      color: _isMarkedAsRead ? Colors.white : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomAction(Icons.note_add_rounded, 'Note', Colors.blue),
          _buildBottomAction(Icons.highlight_alt_rounded, 'Surligner', Colors.yellow),
          _buildBottomAction(Icons.share_rounded, 'Partager', Colors.green),
          _buildBottomAction(Icons.bookmark_rounded, 'Marque-page', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSnackBar('$label activé', icon, color);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

