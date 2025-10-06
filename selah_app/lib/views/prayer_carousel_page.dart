import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' show Random;
import '../utils/prayer_subjects_mapper.dart';
import '../utils/verse_analyzer.dart';

class PrayerCarouselPage extends StatefulWidget {
  const PrayerCarouselPage({super.key});

  @override
  State<PrayerCarouselPage> createState() => _PrayerCarouselPageState();
}

class _PrayerCarouselPageState extends State<PrayerCarouselPage> {
  List<PrayerItem> _items = [];
  final int _currentIndex = 0;
  String _memoryVerse = ''; // Verset noté par l'utilisateur

  @override
  void initState() {
    super.initState();
    
    // Récupérer les arguments passés lors de la navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      print('🔍 ARGUMENTS REÇUS: $args');
      print('🔍 TYPE: ${args.runtimeType}');
      
      if (args is List) {
        print('🔍 NOMBRE D\'ITEMS: ${args.length}');
        setState(() {
          _items = args.cast<PrayerItem>();
        });
        print('🔍 ITEMS FINAUX: ${_items.length}');
        for (int i = 0; i < _items.length; i++) {
          print('🔍 Item $i: ${_items[i].theme} - ${_items[i].subject}');
        }
      } else if (args is Map && args.containsKey('items')) {
        final itemsList = args['items'] as List;
        _memoryVerse = (args['memoryVerse'] as String?)?.trim() ?? '';
        print('🔍 NOMBRE D\'ITEMS (Map): ${itemsList.length}');
        print('🔍 MEMORY VERSE: "$_memoryVerse"');
        setState(() {
          _items = itemsList.cast<PrayerItem>();
        });
        print('🔍 ITEMS FINAUX (Map): ${_items.length}');
        for (int i = 0; i < _items.length; i++) {
          print('🔍 Item $i: ${_items[i].theme} - ${_items[i].subject}');
        }
      } else {
        // Si aucun argument n'est fourni, créer des données de test
        print('🔍 AUCUN ARGUMENT - CRÉATION DE DONNÉES DE TEST');
        setState(() {
          _items = _createTestPrayerItems();
        });
        print('🔍 ITEMS DE TEST CRÉÉS: ${_items.length}');
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
              
              // Cartes avec CardSwiper
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Center(
                    child: CardSwiper(
                      cardsCount: _items.length,
                      isLoop: false, // Pas de boucle - finir quand toutes les cartes sont swipées
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        return _buildPrayerCard(_items[index], index);
                      },
                      onSwipe: _onCardSwiped,
                      onEnd: () {
                        // Quand toutes les cartes sont swipées, afficher la page de succès
                        debugPrint('Toutes les cartes ont été swipées - Prière terminée !');
                        _showSuccessPage();
                        return true;
                      },
                    ),
                  ),
                ),
              ),
              
              // Indicateurs de pagination
              if (_items.length > 1) _buildPageIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerItem item, int index) {
    final isValidated = item.validated;
    
    // Couleurs vives de papier postiche
    final paperColors = [
      Colors.pink[100]!,
      Colors.blue[100]!,
      Colors.green[100]!,
      Colors.yellow[100]!,
      Colors.orange[100]!,
      Colors.purple[100]!,
      Colors.cyan[100]!,
      Colors.lime[100]!,
    ];
    
    final cardColor = paperColors[index % paperColors.length];
    
    return Container(
      child: GestureDetector(
        onTap: () => _toggleValidate(index),
        child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: isValidated ? Colors.grey[200] : cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Texture papier de fond
                _buildPaperTexture(),
                
                // Contenu de la carte
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec icône
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isValidated ? Colors.grey[400] : item.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isValidated ? Icons.check : Icons.touch_app,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.theme.toUpperCase(),
                              style: GoogleFonts.caveat(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                decoration: isValidated ? TextDecoration.lineThrough : TextDecoration.none,
                                decorationColor: Colors.black,
                                decorationThickness: 2.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Sujet de prière
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subject,
                              style: GoogleFonts.kalam(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                decoration: isValidated ? TextDecoration.lineThrough : TextDecoration.none,
                                decorationColor: Colors.black,
                                decorationThickness: 2.0,
                              ),
                            ),
                            
                            // Afficher les notes si elles existent
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ce que Dieu me dit:',
                                      style: GoogleFonts.caveat(
                                        color: Colors.blue[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.notes,
                                      style: GoogleFonts.kalam(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Zone action avec boutons
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Bouton Écrire
                            GestureDetector(
                              onTap: () => _showNotesDialog(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.notes.isNotEmpty ? Colors.green : Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.notes.isNotEmpty ? 'MODIFIER' : 'ÉCRIRE',
                                      style: GoogleFonts.caveat(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.notes.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            
                            // Statut de validation
                            Text(
                              isValidated ? 'VALIDÉ' : 'TAPER POUR VALIDER',
                              style: GoogleFonts.caveat(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildPaperTexture() {
    return Positioned.fill(
      child: CustomPaint(
        painter: PaperTexturePainter(),
        size: const Size(300, 400),
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

  Future<bool> _onCardSwiped(int previousIndex, int? currentIndex, CardSwiperDirection direction) async {
    if (previousIndex >= _items.length) return true;
    
    final item = _items[previousIndex];
    
    // Vérifier si la carte est validée avant de permettre le swipe
    if (!item.validated) {
      // Si la carte n'est pas validée, on empêche le swipe
      // L'utilisateur doit d'abord cliquer pour griser
      return false;
    }
    
    
    debugPrint('Carte swipée: ${item.theme}, $direction');
    return true;
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