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
      '/meditation/start',
      arguments: {
        'planId': 'demo-plan',
        'day': 1,
        'ref': 'Jean 4:10-12',
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
