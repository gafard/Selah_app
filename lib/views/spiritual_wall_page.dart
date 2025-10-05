import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/meditation_journal_service.dart';
import '../models/meditation_journal_entry.dart';

class SpiritualWallPage extends StatefulWidget {
  const SpiritualWallPage({super.key});

  @override
  State<SpiritualWallPage> createState() => _SpiritualWallPageState();
}

class _SpiritualWallPageState extends State<SpiritualWallPage> {
  List<MeditationJournalEntry> _entries = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'week', 'month', 'year'

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    
    try {
      List<MeditationJournalEntry> entries;
      
      switch (_selectedFilter) {
        case 'week':
          entries = await MeditationJournalService.getRecentEntries(days: 7);
          break;
        case 'month':
          entries = await MeditationJournalService.getEntriesForMonth(DateTime.now());
          break;
        case 'year':
          final startDate = DateTime(DateTime.now().year, 1, 1);
          final endDate = DateTime(DateTime.now().year, 12, 31);
          entries = await MeditationJournalService.getEntriesForPeriod(
            startDate: startDate, 
            endDate: endDate
          );
          break;
        default:
          entries = await MeditationJournalService.getEntries();
      }
      
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ ERREUR lors du chargement du mur spirituel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(
          'Mur Spirituel',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onSelected: (String value) {
              setState(() => _selectedFilter = value);
              _loadEntries();
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toutes les méditations'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('7 derniers jours'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('Ce mois'),
              ),
              const PopupMenuItem(
                value: 'year',
                child: Text('Cette année'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildWall(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Votre mur spirituel est vide',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez une méditation pour voir\ntes versets marquants apparaître ici',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/reader'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Commencer une méditation',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWall() {
    return Column(
      children: [
        // Statistiques
        _buildStats(),
        
        // Liste des entrées
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return _buildEntryCard(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Méditations', _entries.length.toString(), Icons.auto_stories),
          _buildStatItem('Jours', _entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().length.toString(), Icons.calendar_today),
          _buildStatItem('Versets', _entries.map((e) => e.memoryVerseRef).toSet().length.toString(), Icons.book),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(MeditationJournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec date et passage
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(entry.gradientIndex),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.passageRef,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.meditationType.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verset marquant
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verset marquant',
                        style: GoogleFonts.inter(
                          color: Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.memoryVerse,
                        style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.memoryVerseRef,
                        style: GoogleFonts.inter(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Sujets de prière
                if (entry.prayerSubjects.isNotEmpty) ...[
                  Text(
                    'Sujets de prière',
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: entry.prayerSubjects.take(3).map((subject) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          subject,
                          style: GoogleFonts.inter(
                            color: Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (entry.prayerSubjects.length > 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${entry.prayerSubjects.length - 3} autres...',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                
                // Notes de prière
                if (entry.prayerNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Notes de prière',
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.prayerNotes.take(2).map((note) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        note,
                        style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(int index) {
    const gradients = [
      [Color(0xFFFF9F1C), Color(0xFFFFBF69)], // orange
      [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // violet
      [Color(0xFF10B981), Color(0xFF34D399)], // vert
      [Color(0xFF3B82F6), Color(0xFF60A5FA)], // bleu
    ];
    return gradients[index % gradients.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
