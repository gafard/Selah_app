import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Temporairement désactivé
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/selah_logo.dart';
import '../widgets/uniform_back_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const SelahAppIcon(size: 28),
            const SizedBox(width: 12),
            Text('Mon parcours', style: GoogleFonts.playfairDisplay(color: const Color(0xFFF5F5F5))),
          ],
        ),
        leading: UniformBackButtonAppBar(
          onPressed: () => context.pop(),
          iconColor: const Color(0xFF8B7355),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileStats(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8B7355)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée', style: TextStyle(color: Colors.grey)));
          }

          final stats = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(context),
                const SizedBox(height: 24),
                _buildStatCard('Fidélité', 'Jour ${stats['currentStreak']} d\'affilée', Icons.local_fire_department, Colors.orange),
                _buildStatCard('Plans terminés', '${stats['completedPlans']}', Icons.check_circle, Colors.green),
                _buildStatCard('Notes écrites', '${stats['totalNotes']}', Icons.note, const Color(0xFF8B7355)),
                _buildStatCard('Versets surlignés', '${stats['totalHighlights']}', Icons.highlight, Colors.blue),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchProfileStats(BuildContext context) async {
    // Simulation de données pour les tests
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      return {
        'currentStreak': 7,
        'completedPlans': 3,
        'totalNotes': 15,
        'totalHighlights': 42,
      };
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
      return {};
    }
  }

  // Logique simplifiée pour calculer la série de jours consécutifs
  Future<int> _calculateCurrentStreak(String userId) async {
    // Simulation de calcul de série pour les tests
    await Future.delayed(const Duration(milliseconds: 300));
    return 7; // Série simulée de 7 jours
  }

  Widget _buildProfileHeader(BuildContext context) {
    final appState = context.watch<AppState>();
    final displayName = appState.profile?['display_name'] ?? 'Pèlerin';
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF8B7355),
          child: Text(displayName[0].toUpperCase(), style: GoogleFonts.playfairDisplay(fontSize: 40, color: const Color(0xFF1C1C1E))),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFF5F5F5), fontSize: 28),
        ),
        Text(
          'Fidèle depuis ${appState.profile?['created_at'] != null ? '${DateTime.now().difference(DateTime.parse(appState.profile!['created_at'])).inDays} jours' : 'quelques jours'}',
          style: GoogleFonts.lato(color: const Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: const Color(0xFF2C2C2E),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: GoogleFonts.lato(color: const Color(0xFFF5F5F5), fontWeight: FontWeight.bold)),
        trailing: Text(value, style: GoogleFonts.lato(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
