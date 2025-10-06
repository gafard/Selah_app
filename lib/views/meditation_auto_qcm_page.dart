import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/passage_analysis.dart';

class MeditationAutoQcmPage extends StatefulWidget {
  const MeditationAutoQcmPage({super.key});

  @override
  State<MeditationAutoQcmPage> createState() => _MeditationAutoQcmPageState();
}

class _MeditationAutoQcmPageState extends State<MeditationAutoQcmPage> {
  final Map<int, int> _answers = {}; // questionIndex -> selectedIndex
  List<McqItem> _mcqItems = [];
  bool _isLoading = true;

  // Texte de démonstration (en production, ceci viendrait du passage biblique)
  final String _demoPassage = """
    Jésus se rendit dans la ville de Samarie, appelée Sychar, près du champ que Jacob avait donné à son fils Joseph. 
    Là se trouvait le puits de Jacob. Jésus, fatigué du voyage, était assis au bord du puits. 
    C'était environ la sixième heure. Une femme de Samarie vint puiser de l'eau. 
    Jésus lui dit : Donne-moi à boire. Car ses disciples étaient allés à la ville pour acheter des vivres. 
    La femme samaritaine lui dit : Comment toi, qui es Juif, me demandes-tu à boire, à moi qui suis une femme samaritaine ? 
    Jésus lui répondit : Si tu connaissais le don de Dieu et qui est celui qui te dit : Donne-moi à boire, tu lui aurais toi-même demandé à boire, et il t'aurait donné de l'eau vive.
  """;

  @override
  void initState() {
    super.initState();
    _generateMcqs();
  }

  void _generateMcqs() {
    setState(() {
      _isLoading = true;
    });

    // Simuler un délai de traitement
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _mcqItems = buildMcqs(_demoPassage);
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('QCM Automatique', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF7F7F9),
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateMcqs,
            tooltip: 'Générer de nouvelles questions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _mcqItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune question générée',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le texte ne contient pas assez d\'éléments pour générer des questions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _mcqItems.length,
                        itemBuilder: (context, index) {
                          final item = _mcqItems[index];
                          final selectedAnswer = _answers[index];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Numéro de question
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Question ${index + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Question
                                Text(
                                  item.question,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Options
                                ...item.choices.asMap().entries.map((entry) {
                                  final choiceIndex = entry.key;
                                  final choice = entry.value;
                                  final isSelected = selectedAnswer == choiceIndex;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _answers[index] = choiceIndex;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                                                border: Border.all(
                                                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade400,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 12,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                choice,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? const Color(0xFF6366F1) : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Bouton de correction
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _answers.length == _mcqItems.length ? _showResults : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _answers.length == _mcqItems.length 
                                  ? 'Voir les résultats'
                                  : 'Répondez à toutes les questions (${_answers.length}/${_mcqItems.length})',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showResults() {
    int correctAnswers = 0;
    for (int i = 0; i < _mcqItems.length; i++) {
      if (_answers[i] == _mcqItems[i].correctIndex) {
        correctAnswers++;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Résultats',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous avez obtenu $correctAnswers sur ${_mcqItems.length}',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: correctAnswers / _mcqItems.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateMcqs();
            },
            child: const Text('Nouvelles questions'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
