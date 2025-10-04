import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/reader_settings_service.dart';
import '../widgets/highlightable_text.dart';
import '../widgets/circular_audio_progress.dart';

class ReaderPageModern extends StatefulWidget {
  const ReaderPageModern({super.key});

  @override
  State<ReaderPageModern> createState() => _ReaderPageModernState();
}

class _ReaderPageModernState extends State<ReaderPageModern>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isMarkedAsRead = false;
  double _audioProgress = 0.0;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _toggleAudio() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _simulateAudioProgress();
      } else {
        _audioProgress = 0.0;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _simulateAudioProgress() {
    if (_isPlaying && _audioProgress < 1.0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _isPlaying) {
          setState(() {
            _audioProgress += 0.01;
          });
          _simulateAudioProgress();
        }
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    HapticFeedback.lightImpact();
    _showSnackBar(
      _isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris',
      _isFavorite ? Icons.favorite : Icons.favorite_border,
      _isFavorite ? Colors.red : Colors.grey,
    );
  }

  void _markAsRead() {
    setState(() {
      _isMarkedAsRead = !_isMarkedAsRead;
    });
    HapticFeedback.mediumImpact();
    _showSnackBar(
      _isMarkedAsRead ? 'Marqué comme lu !' : 'Marqué comme non lu',
      _isMarkedAsRead ? Icons.check_circle : Icons.radio_button_unchecked,
      _isMarkedAsRead ? Colors.green : Colors.grey,
    );
  }

  void _goToMeditation() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(
      context,
      '/meditation/chooser', // page avec 2 options
      arguments: {
        'passageRef': 'Ézéchiel 33:1-18',
        'passageText': '''1 La parole de l'Éternel me fut adressée, en ces mots :

2 Fils de l'homme, parle aux enfants de ton peuple, et dis-leur : Lorsque je fais venir l'épée sur un pays, et que le peuple du pays prend dans son sein un homme et l'établit comme sentinelle,

3 si cet homme voit venir l'épée sur le pays, sonne de la trompette, et avertit le peuple ;

4 et si celui qui entend le son de la trompette ne se laisse pas avertir, et que l'épée vienne le surprendre, son sang sera sur sa tête.

5 Il a entendu le son de la trompette, et ne s'est pas laissé avertir : son sang sera sur lui. S'il se laisse avertir, il sauvera son âme.

6 Si la sentinelle voit venir l'épée, et ne sonne pas de la trompette ; si le peuple n'est pas averti, et que l'épée vienne enlever à quelqu'un la vie, celui-ci périra à cause de son iniquité, mais je redemanderai son sang à la sentinelle.

7 Toi, fils de l'homme, je t'ai établi comme sentinelle sur la maison d'Israël. Tu dois écouter la parole qui sort de ma bouche, et les avertir de ma part.

8 Quand je dis au méchant : Méchant, tu mourras ! si tu ne parles pas pour détourner le méchant de sa voie, ce méchant mourra dans son iniquité, et je redemanderai son sang à ta main.

9 Mais si tu avertis le méchant pour le détourner de sa voie et qu'il ne s'en détourne pas, il mourra dans son iniquité, et toi tu sauveras ton âme.

10 Et toi, fils de l'homme, dis à la maison d'Israël : Vous dites : Nos transgressions et nos péchés sont sur nous, et c'est à cause d'eux que nous sommes frappés de langueur ; comment pourrions-nous vivre ?

11 Dis-leur : Je suis vivant ! dit le Seigneur, l'Éternel, ce que je désire, ce n'est pas que le méchant meure, c'est qu'il change de conduite et qu'il vive. Revenez, revenez de votre mauvaise voie ; et pourquoi mourriez-vous, maison d'Israël ?

12 Et toi, fils de l'homme, dis aux enfants de ton peuple : La justice du juste ne le sauvera pas au jour de sa transgression ; et le méchant ne tombera pas par sa méchanceté le jour où il s'en détournera, de même que le juste ne pourra pas vivre par sa justice au jour où il péchera.

13 Lorsque je dis au juste qu'il vivra, -s'il se confie dans sa justice et commet l'iniquité, toute sa justice sera oubliée, et il mourra à cause de l'iniquité qu'il a commise.

14 Lorsque je dis au méchant : Tu mourras ! -s'il revient de son péché et pratique la droiture et la justice,

15 s'il rend le gage, s'il restitue ce qu'il a ravi, s'il suit les préceptes qui donnent la vie, sans commettre l'iniquité, il vivra, il ne mourra pas.

16 Tous les péchés qu'il a commis seront oubliés ; il pratique la droiture et la justice, il vivra.

17 Les enfants de ton peuple disent : La voie du Seigneur n'est pas droite. C'est leur voie qui n'est pas droite.

18 Si le juste se détourne de sa justice et commet l'iniquité, il mourra à cause de cela.''',
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
                  'Jour 15',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Jean 4:10-12',
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
                'Jean 4:10-12',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 16),
              HighlightableText(
                text: '''10 Jésus lui répondit : « Si tu connaissais le don de Dieu et qui est celui qui te dit : "Donne-moi à boire", tu lui aurais toi-même demandé à boire, et il t'aurait donné de l'eau vive. »

11 « Seigneur, lui dit la femme, tu n'as rien pour puiser, et le puits est profond. D'où aurais-tu donc cette eau vive ? 12 Es-tu plus grand que notre père Jacob, qui nous a donné ce puits, et qui en a bu lui-même, ainsi que ses fils et ses troupeaux ? »''',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircularAudioProgress(
            progress: _audioProgress,
            size: 60,
            progressColor: const Color(0xFFD77B04),
            backgroundColor: Colors.grey.shade300,
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: _toggleAudio,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Bible',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying 
                      ? 'Lecture en cours... ${(_audioProgress * 100).round()}%'
                      : 'Appuyez pour écouter',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isFavorite ? Colors.red.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey.shade600,
                size: 24,
              ),
            ),
          ),
        ],
      ),
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Méditation',
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
