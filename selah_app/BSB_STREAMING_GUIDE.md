# 📚 Guide du Système de Streaming BSB

## 🎯 **Vue d'ensemble**

Le système de streaming BSB permet de charger des données bibliques volumineuses de manière optimisée, en séparant les données légères (embarquées) des données volumineuses (téléchargeables).

## 📁 **Structure des fichiers**

### **Données légères (embarquées dans l'APK)**
- `assets/data/topics_min.json` - Index des sujets (quelques Ko)

### **Données volumineuses (téléchargeables)**
- `topics_links.jsonl.gz` - Liens sujet-référence (compressé)
- `concordance.jsonl.gz` - Concordance complète (compressé)

## 🚀 **Configuration du serveur**

### **1. Hébergement des fichiers**

Placez vos fichiers générés sur votre serveur :

```
https://votre-serveur.com/bsb-data/
├── topics_links.jsonl.gz
└── concordance.jsonl.gz
```

### **2. Configuration des URLs**

Dans `BSBDownloadService`, modifiez les URLs :

```dart
static const String _baseUrl = 'https://votre-serveur.com/bsb-data';
```

## 🔧 **Utilisation**

### **1. Génération des données**

```bash
# Convertir vos fichiers Excel
python3 tools/convert_bsb_to_json.py \
  --topical "chemin/bsb_topical_index.xlsx" \
  --concordance "chemin/bsb_concordance.xlsx" \
  --out "./export_bsb"

# Générer des données de test
python3 tools/generate_test_bsb_data.py
```

### **2. Intégration Flutter**

```dart
// Initialiser le service
await BSBStreamingService.init();

// Rechercher des sujets
final topics = BSBStreamingService.getTopics();

// Rechercher des références
final references = await BSBStreamingService.searchTopicReferences(topicId);

// Rechercher dans la concordance
final concordance = await BSBStreamingService.searchConcordance("mot");
```

### **3. Téléchargement des données**

```dart
// Télécharger un fichier
await BSBDownloadService.downloadDataFile('topics_links.jsonl.gz');

// Télécharger tous les fichiers
await BSBDownloadService.downloadAllDataFiles();

// Vérifier le statut
final stats = await BSBDownloadService.getDownloadStats();
```

## 📱 **Interface utilisateur**

### **Page de téléchargement**

Accédez à `BSBDownloadPage` pour :
- Voir le statut des téléchargements
- Télécharger les fichiers manuellement
- Gérer l'espace de stockage

### **Intégration dans l'app**

```dart
// Dans votre navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BSBDownloadPage(),
  ),
);
```

## 🔄 **Flux de données**

1. **Au démarrage** : Chargement de `topics_min.json` (léger)
2. **Première utilisation** : Téléchargement des fichiers volumineux
3. **Recherche** : Parsing en streaming des fichiers compressés
4. **Cache** : Stockage local pour accès hors ligne

## 📊 **Avantages**

- **APK léger** : Seulement l'index des sujets embarqué
- **Scalable** : Gros volumes téléchargeables à la demande
- **Rapide** : Parsing en streaming, faible utilisation mémoire
- **Hors ligne** : Données mises en cache localement
- **Interopérable** : Références normalisées

## 🛠️ **Dépannage**

### **Problèmes courants**

1. **Fichiers non trouvés**
   - Vérifiez les URLs de téléchargement
   - Vérifiez la connectivité réseau

2. **Erreurs de parsing**
   - Vérifiez le format des fichiers JSONL
   - Vérifiez l'intégrité des fichiers compressés

3. **Performances lentes**
   - Vérifiez la taille des fichiers
   - Optimisez les requêtes de recherche

### **Logs de débogage**

```dart
// Activer les logs détaillés
print('🔍 BSB Streaming Debug: $message');
```

## 📈 **Optimisations**

### **1. Compression**
- Utilisez gzip pour réduire la taille des fichiers
- Optimisez le format JSONL pour le streaming

### **2. Cache**
- Mettez en cache les résultats fréquents
- Implémentez une stratégie de cache intelligente

### **3. Indexation**
- Créez des index pour accélérer les recherches
- Utilisez des structures de données optimisées

## 🔐 **Sécurité**

- Validez les données téléchargées
- Implémentez des checksums pour l'intégrité
- Chiffrez les données sensibles si nécessaire

## 📝 **Exemple complet**

```dart
// Initialisation
await BSBStreamingService.init();

// Vérifier la disponibilité des données
final hasTopics = await BSBStreamingService.hasDataFile('topics_links.jsonl.gz');
if (!hasTopics) {
  await BSBDownloadService.downloadDataFile('topics_links.jsonl.gz');
}

// Recherche
final topics = BSBStreamingService.getTopics();
final references = await BSBStreamingService.searchTopicReferences(0);
final concordance = await BSBStreamingService.searchConcordance("amour");
```

## 🎉 **Résultat**

Avec ce système, vous obtenez :
- Une application légère et rapide
- Des données bibliques complètes
- Une expérience utilisateur fluide
- Une architecture scalable et maintenable

