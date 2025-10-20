import 'package:flutter/material.dart';
import '../services/bible_comparison_service.dart';

class BibleComparisonPage extends StatefulWidget {
  final String? initialReference;
  
  const BibleComparisonPage({super.key, this.initialReference});

  @override
  State<BibleComparisonPage> createState() => _BibleComparisonPageState();
}

class _BibleComparisonPageState extends State<BibleComparisonPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selectedVerse;
  List<String> _selectedVersions = ['KJV', 'BSB', 'WEB'];
  Map<String, dynamic> _versionsMetadata = {};

  @override
  void initState() {
    super.initState();
    _initializeService();
    if (widget.initialReference != null) {
      _searchController.text = widget.initialReference!;
      _searchVerse();
    }
  }

  Future<void> _initializeService() async {
    await BibleComparisonService.init();
    setState(() {
      _versionsMetadata = BibleComparisonService.getVersionsMetadata();
    });
  }

  Future<void> _searchVerse() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await BibleComparisonService.searchVerse(_searchController.text.trim());
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la recherche: $e')),
        );
      }
    }
  }

  void _selectVerse(Map<String, dynamic> verse) {
    setState(() {
      _selectedVerse = verse;
    });
  }

  void _toggleVersion(String version) {
    setState(() {
      if (_selectedVersions.contains(version)) {
        _selectedVersions.remove(version);
      } else {
        _selectedVersions.add(version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparaison de Versions'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un verset (ex: John 3:16)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchVerse(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchVerse,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          
          // Résultats de recherche
          if (_searchResults.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  // Liste des résultats
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final verse = _searchResults[index];
                        final isSelected = _selectedVerse == verse;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                          child: ListTile(
                            title: Text(
                              verse['reference'] ?? '',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('${verse['book']} ${verse['chapter']}:${verse['verse']}'),
                            trailing: Text(
                              '${(verse['versions'] as Map<String, dynamic>? ?? {}).length} versions',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () => _selectVerse(verse),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Comparaison des versions
                  if (_selectedVerse != null)
                    Expanded(
                      flex: 2,
                      child: _buildVersionComparison(),
                    ),
                ],
              ),
            )
          else if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recherchez un verset pour voir la comparaison',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVersionComparison() {
    final versions = _selectedVerse!['versions'] as Map<String, dynamic>? ?? {};
    
    return Column(
      children: [
        // Sélecteur de versions
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: _versionsMetadata.keys.map((versionCode) {
              final isSelected = _selectedVersions.contains(versionCode);
              final versionInfo = _versionsMetadata[versionCode] as Map<String, dynamic>? ?? {};
              final hasText = versions.containsKey(versionCode);
              
              return FilterChip(
                label: Text(versionCode),
                selected: isSelected,
                onSelected: hasText ? (_) => _toggleVersion(versionCode) : null,
                tooltip: hasText 
                  ? '${versionInfo['name'] ?? versionCode} - ${versionInfo['year'] ?? ''}'
                  : 'Version non disponible',
              );
            }).toList(),
          ),
        ),
        
        // Affichage des versions sélectionnées
        Expanded(
          child: ListView.builder(
            itemCount: _selectedVersions.length,
            itemBuilder: (context, index) {
              final versionCode = _selectedVersions[index];
              final text = versions[versionCode]?.toString() ?? 'Version non disponible';
              final versionInfo = _versionsMetadata[versionCode] as Map<String, dynamic>? ?? {};
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            versionCode,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            versionInfo['name'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            versionInfo['year'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

