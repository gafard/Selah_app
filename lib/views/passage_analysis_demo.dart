import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/passage_analysis.dart';

class PassageAnalysisDemo extends StatefulWidget {
  const PassageAnalysisDemo({super.key});

  @override
  State<PassageAnalysisDemo> createState() => _PassageAnalysisDemoState();
}

class _PassageAnalysisDemoState extends State<PassageAnalysisDemo> {
  final TextEditingController _textController = TextEditingController();
  PassageFacts? _extractedFacts;
  List<McqItem> _generatedMcqs = [];

  final String _demoText = """
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
    _textController.text = _demoText;
    _analyzeText();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _analyzeText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _extractedFacts = extractFacts(text);
        _generatedMcqs = buildMcqs(text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Analyse de Passage', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF7F7F9),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Zone de texte
          Container(
            margin: const EdgeInsets.all(16),
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
                Text(
                  'Texte à analyser',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    hintText: 'Collez votre texte biblique ici...',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _analyzeText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Analyser le texte',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: _extractedFacts == null
                ? const Center(
                    child: Text('Entrez un texte et cliquez sur "Analyser"'),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Faits extraits
                      _buildFactsCard(),
                      const SizedBox(height: 16),
                      
                      // QCM générés
                      _buildMcqsCard(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactsCard() {
    return Container(
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
          Text(
            'Faits extraits',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Personnages
          if (_extractedFacts!.people.isNotEmpty) ...[
            _buildFactSection('Personnages', _extractedFacts!.people.toList()),
            const SizedBox(height: 12),
          ],
          
          // Lieux
          if (_extractedFacts!.places.isNotEmpty) ...[
            _buildFactSection('Lieux', _extractedFacts!.places.toList()),
            const SizedBox(height: 12),
          ],
          
          // Événements
          if (_extractedFacts!.keyEvents.isNotEmpty) ...[
            _buildFactSection('Événements clés', _extractedFacts!.keyEvents),
          ],
        ],
      ),
    );
  }

  Widget _buildFactSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6366F1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMcqsCard() {
    return Container(
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
          Text(
            'Questions générées (${_generatedMcqs.length})',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_generatedMcqs.isEmpty)
            Text(
              'Aucune question générée. Le texte ne contient pas assez d\'éléments.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )
          else
            ..._generatedMcqs.asMap().entries.map((entry) {
              final index = entry.key;
              final mcq = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}: ${mcq.question}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...mcq.choices.asMap().entries.map((choiceEntry) {
                      final choiceIndex = choiceEntry.key;
                      final choice = choiceEntry.value;
                      final isCorrect = choiceIndex == mcq.correctIndex;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFD1FAE5) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCorrect ? const Color(0xFF10B981) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isCorrect)
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF10B981),
                              )
                            else
                              const Icon(
                                Icons.radio_button_unchecked,
                                size: 16,
                                color: Colors.grey,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                choice,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isCorrect ? const Color(0xFF10B981) : Colors.black,
                                  fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
