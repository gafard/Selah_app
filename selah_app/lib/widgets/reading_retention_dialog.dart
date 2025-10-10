import 'package:flutter/material.dart';
import '../services/reading_memory_service.dart';

/// Dialog "Retenu de ma lecture"
/// 
/// Affiché quand l'utilisateur appuie sur "Marquer comme lu"
/// 
/// Permet de capturer :
/// - Ce que l'utilisateur a retenu
/// - Où envoyer (Journal / Mur spirituel)
/// 
/// Puis propose de créer un Poster en fin de prière
class ReadingRetentionDialog {
  
  /// Affiche le dialog de rétention
  /// 
  /// [context] : BuildContext
  /// [verseId] : ID du passage lu
  /// [onSaved] : Callback quand sauvegardé
  /// 
  /// Retourne : true si sauvegardé, false si annulé
  static Future<bool> show({
    required BuildContext context,
    required String verseId,
    VoidCallback? onSaved,
  }) async {
    final controller = TextEditingController();
    bool addToJournal = true;
    bool addToWall = false;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFFFA726)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Qu\'as-tu retenu ?',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Référence
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          verseId.replaceAll('.', ' '),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Texte libre
                  Text(
                    'Résumé de ta lecture :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ce que Dieu m\'a parlé, ce que j\'ai appris...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Options
                  Text(
                    'Enregistrer dans :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  CheckboxListTile(
                    title: const Row(
                      children: [
                        Icon(Icons.book, size: 20, color: Color(0xFF2196F3)),
                        SizedBox(width: 8),
                        Text('Journal spirituel'),
                      ],
                    ),
                    value: addToJournal,
                    onChanged: (value) => setState(() => addToJournal = value ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  CheckboxListTile(
                    title: const Row(
                      children: [
                        Icon(Icons.view_agenda, size: 20, color: Color(0xFF9C27B0)),
                        SizedBox(width: 8),
                        Text('Mur spirituel'),
                      ],
                    ),
                    subtitle: const Text(
                      'Privé, visible uniquement par vous',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: addToWall,
                    onChanged: (value) => setState(() => addToWall = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Info Poster
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.image, size: 16, color: Color(0xFF4CAF50)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Un poster te sera proposé en fin de prière',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final retained = controller.text.trim();
                  
                  if (retained.isEmpty) {
                    // Proposer de continuer sans rétention
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Aucun texte saisi'),
                        content: const Text('Voulez-vous continuer sans enregistrer de rétention ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Non, retour'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Oui, continuer'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      Navigator.pop(context, true);
                    }
                    return;
                  }
                  
                  // Sauvegarder la rétention
                  await ReadingMemoryService.saveRetention(
                    id: verseId,
                    retained: retained,
                    date: DateTime.now(),
                    addToJournal: addToJournal,
                    addToWall: addToWall,
                  );
                  
                  Navigator.pop(context, true);
                  onSaved?.call();
                },
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C34D1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return result ?? false;
  }
}

/// Widget pour proposer la création de Posters
/// 
/// À afficher en fin de prière ou au retour sur la HomePage
class PosterProposalWidget extends StatelessWidget {
  const PosterProposalWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ReadingMemoryService.pendingForPoster(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final pending = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.image, color: Color(0xFF4CAF50), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Créer des posters',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Tu as ${pending.length} passage(s) à transformer en poster visuel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Repousser à plus tard
                        Navigator.pop(context);
                      },
                      child: const Text('Plus tard'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Naviguer vers page de création Poster
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/verse_poster',
                          arguments: {
                            'pendingItems': pending,
                          },
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Créer maintenant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
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
}


