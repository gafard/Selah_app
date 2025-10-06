import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/selah_logo.dart';

class PrayerGeneratorPage extends StatefulWidget {
  const PrayerGeneratorPage({super.key});

  @override
  State<PrayerGeneratorPage> createState() => _PrayerGeneratorPageState();
}

class _PrayerGeneratorPageState extends State<PrayerGeneratorPage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  String _selectedMood = 'gratitude';
  String _generatedPrayer = '';
  bool _isGenerating = false;

  final List<Map<String, String>> _moods = [
    {'value': 'gratitude', 'label': 'Action de Grâce', 'icon': '🙏'},
    {'value': 'repentance', 'label': 'Repentance', 'icon': '😔'},
    {'value': 'intercession', 'label': 'Intercession', 'icon': '🤲'},
    {'value': 'praise', 'label': 'Louange', 'icon': '🙌'},
    {'value': 'guidance', 'label': 'Direction', 'icon': '🧭'},
    {'value': 'healing', 'label': 'Guérison', 'icon': '💚'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const SelahAppIcon(size: 28),
            const SizedBox(width: 12),
            Text(
              'Générateur de Prière',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de configuration
            _buildConfigSection(),
            
            const SizedBox(height: 24),
            
            // Bouton de génération
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generatePrayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B7355),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Générer la Prière',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Prière générée
            if (_generatedPrayer.isNotEmpty)
              _buildGeneratedPrayerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B7355).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration de la Prière',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Sujet de la prière
          Text(
            'Sujet de la Prière',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextField(
            controller: _topicController,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Ma famille, Mon travail, Ma santé...',
              hintStyle: GoogleFonts.inter(
                color: Colors.white54,
              ),
              filled: true,
              fillColor: const Color(0xFF3A3A3C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contexte
          Text(
            'Contexte (optionnel)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextField(
            controller: _contextController,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Décrivez la situation ou les circonstances...',
              hintStyle: GoogleFonts.inter(
                color: Colors.white54,
              ),
              filled: true,
              fillColor: const Color(0xFF3A3A3C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Type de prière
          Text(
            'Type de Prière',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF8B7355) 
                        : const Color(0xFF3A3A3C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF8B7355) 
                          : const Color(0xFF5A5A5C),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mood['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mood['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPrayerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Prière Générée',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _generatedPrayer,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _copyPrayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Copier',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _regeneratePrayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Régénérer',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _generatePrayer() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un sujet pour la prière'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Simulation de génération
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _generatedPrayer = _createPrayer();
      _isGenerating = false;
    });
  }

  String _createPrayer() {
    final topic = _topicController.text.trim();
    final context = _contextController.text.trim();
    final mood = _moods.firstWhere((m) => m['value'] == _selectedMood);
    
    String prayer = '';
    
    switch (_selectedMood) {
      case 'gratitude':
        prayer = 'Seigneur, je te remercie du fond du cœur pour $topic. ';
        if (context.isNotEmpty) {
          prayer += 'Dans cette situation où $context, ';
        }
        prayer += 'Je reconnais ta bonté et ta fidélité dans ma vie. Merci pour toutes tes bénédictions. Amen.';
        break;
        
      case 'repentance':
        prayer = 'Père céleste, je viens devant toi avec un cœur repentant concernant $topic. ';
        if (context.isNotEmpty) {
          prayer += 'Je reconnais que dans $context, ';
        }
        prayer += 'j\'ai péché contre toi. Pardonne-moi et aide-moi à marcher dans ta justice. Amen.';
        break;
        
      case 'intercession':
        prayer = 'Seigneur, je t\'élève $topic dans la prière. ';
        if (context.isNotEmpty) {
          prayer += 'Je sais que $context, ';
        }
        prayer += 'et je te demande d\'intervenir avec ta puissance et ta grâce. Bénis et protège selon ta volonté. Amen.';
        break;
        
      case 'praise':
        prayer = 'Gloire à toi, Seigneur ! Tu es digne de toute louange pour $topic. ';
        if (context.isNotEmpty) {
          prayer += 'Même dans $context, ';
        }
        prayer += 'tu manifestes ta grandeur et ta majesté. Je t\'adore et je te magnifie. Amen.';
        break;
        
      case 'guidance':
        prayer = 'Père, je te demande ta direction et ta sagesse pour $topic. ';
        if (context.isNotEmpty) {
          prayer += 'Dans cette situation où $context, ';
        }
        prayer += 'guide mes pas et éclaire mon chemin selon ta volonté parfaite. Amen.';
        break;
        
      case 'healing':
        prayer = 'Seigneur de guérison, je t\'élève $topic pour ta restauration. ';
        if (context.isNotEmpty) {
          prayer += 'Je sais que $context, ';
        }
        prayer += 'mais je crois en ta puissance de guérison. Que ta main bienfaisante touche et restaure. Amen.';
        break;
        
      default:
        prayer = 'Seigneur, je te prie pour $topic. ';
        if (context.isNotEmpty) {
          prayer += 'Dans $context, ';
        }
        prayer += 'que ta volonté soit faite. Amen.';
    }
    
    return prayer;
  }

  void _copyPrayer() {
    // Simulation de copie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prière copiée dans le presse-papiers'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _regeneratePrayer() {
    _generatePrayer();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _contextController.dispose();
    super.dispose();
  }
}
