import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_vm.dart';
import '../services/background_tasks.dart';

/// Example d'intégration du nouveau HomeVM avec une page d'accueil
class HomeIntegrationExample extends StatelessWidget {
  const HomeIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selah - Accueil'),
        actions: [
          // Badge de sync
          Consumer<HomeVM>(
            builder: (context, homeVM, child) {
              if (homeVM.state.hasPendingSync) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.sync,
                    color: Colors.orange,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<HomeVM>(
        builder: (context, homeVM, child) {
          final state = homeVM.state;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salutation
                _buildGreetingCard(state.greetingName),
                
                const SizedBox(height: 16),
                
                // Version de la Bible
                _buildBibleVersionCard(state.bibleVersion, homeVM),
                
                const SizedBox(height: 16),
                
                // Progression du jour
                _buildProgressCard(state),
                
                const SizedBox(height: 16),
                
                // Bouton pour télécharger une version
                _buildDownloadButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreetingCard(String name) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shalom, $name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Que ta journée soit bénie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibleVersionCard(String? version, HomeVM homeVM) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version de la Bible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version actuelle: ${version ?? 'Aucune'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => homeVM.changeBibleVersion('LSG'),
                  child: const Text('LSG'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => homeVM.changeBibleVersion('S21'),
                  child: const Text('S21'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => homeVM.changeBibleVersion('BDS'),
                  child: const Text('BDS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(HomeState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression du jour',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.tasksDone}/${state.tasksTotal} tâches terminées',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${(state.progress * 100).toStringAsFixed(1)}% complété',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Téléchargements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Téléchargez des versions de la Bible pour un accès hors-ligne.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await BackgroundTasks.queueBible('LSG');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Téléchargement de LSG en cours...'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger LSG'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await BackgroundTasks.queueBible('S21');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Téléchargement de S21 en cours...'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger S21'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemple d'utilisation dans une page de paramètres
class SettingsIntegrationExample extends StatelessWidget {
  const SettingsIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section Bible
          const ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('Version de la Bible'),
            subtitle: Text('Choisissez votre version préférée'),
          ),
          
          // Boutons de téléchargement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await BackgroundTasks.queueBible('LSG');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Téléchargement de LSG en cours...'),
                        ),
                      );
                    }
                  },
                  child: const Text('Télécharger LSG'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await BackgroundTasks.queueBible('S21');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Téléchargement de S21 en cours...'),
                        ),
                      );
                    }
                  },
                  child: const Text('Télécharger S21'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Section Sync
          Consumer<HomeVM>(
            builder: (context, homeVM, child) {
              return ListTile(
                leading: Icon(
                  homeVM.state.hasPendingSync ? Icons.sync : Icons.check_circle,
                  color: homeVM.state.hasPendingSync ? Colors.orange : Colors.green,
                ),
                title: const Text('Synchronisation'),
                subtitle: Text(
                  homeVM.state.hasPendingSync 
                    ? 'Synchronisation en cours...' 
                    : 'Tout est synchronisé',
                ),
                trailing: homeVM.state.hasPendingSync 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

