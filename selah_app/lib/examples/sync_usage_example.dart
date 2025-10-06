import 'package:flutter/material.dart';
import '../app_state.dart';

/// Example d'utilisation du nouveau système de sync dans l'UI
class SyncUsageExample extends StatelessWidget {
  const SyncUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Example'),
        // Badge de sync dans l'AppBar
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              if (appState.hasPendingSync) {
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
      body: Column(
        children: [
          // Affichage du profil local
          Consumer<AppState>(
            builder: (context, appState, child) {
              final profile = appState.profile;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profil local:', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('ID: ${profile?['id'] ?? 'Non défini'}'),
                      Text('Nom: ${profile?['display_name'] ?? 'Non défini'}'),
                      Text('Onboardé: ${profile?['hasOnboarded'] ?? false}'),
                      Text('Dernière MAJ: ${profile?['updated_at_local'] ?? 'Jamais'}'),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bouton pour simuler l'onboarding optimiste
          ElevatedButton(
            onPressed: () async {
              final app = AppStateProvider.of(context);
              await app.setHasOnboardedOptimistic();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding marqué comme terminé (sync en cours)')),
                );
              }
            },
            child: const Text('Marquer comme onboardé (optimiste)'),
          ),
          
          const SizedBox(height: 16),
          
          // Indicateur de sync en cours
          Consumer<AppState>(
            builder: (context, appState, child) {
              return Card(
                color: appState.hasPendingSync ? Colors.orange.shade100 : Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        appState.hasPendingSync ? Icons.sync : Icons.check_circle,
                        color: appState.hasPendingSync ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appState.hasPendingSync 
                          ? 'Sync en cours...' 
                          : 'Tout est synchronisé',
                        style: TextStyle(
                          color: appState.hasPendingSync ? Colors.orange.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Exemple d'utilisation dans une page d'onboarding
class OnboardingExample extends StatelessWidget {
  const OnboardingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue dans Selah!'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Écriture optimiste avant la redirection
                final app = AppStateProvider.of(context);
                await app.setHasOnboardedOptimistic();
                
                if (context.mounted) {
                  // Redirection immédiate
                  Navigator.of(context).pushReplacementNamed('/congrats');
                }
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}


