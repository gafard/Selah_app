/// Configuration des URLs de téléchargement BSB
class BSBConfig {
  /// URLs de base pour les données BSB
  static const String baseUrl = 'https://votre-serveur.com/bsb-data';
  
  /// URLs complètes pour chaque fichier
  static const Map<String, String> downloadUrls = {
    'topics_links.jsonl.gz': '$baseUrl/topics_links.jsonl.gz',
    'concordance.jsonl.gz': '$baseUrl/concordance.jsonl.gz',
  };
  
  /// Configuration pour différents environnements
  static const Map<String, Map<String, String>> environments = {
    'development': {
      'baseUrl': 'http://localhost:8080/bsb-data',
    },
    'staging': {
      'baseUrl': 'https://staging.votre-serveur.com/bsb-data',
    },
    'production': {
      'baseUrl': 'https://votre-serveur.com/bsb-data',
    },
  };
  
  /// Obtenir l'URL de base selon l'environnement
  static String getBaseUrl([String environment = 'production']) {
    return environments[environment]?['baseUrl'] ?? baseUrl;
  }
  
  /// Obtenir les URLs de téléchargement selon l'environnement
  static Map<String, String> getDownloadUrls([String environment = 'production']) {
    final envBaseUrl = getBaseUrl(environment);
    return {
      'topics_links.jsonl.gz': '$envBaseUrl/topics_links.jsonl.gz',
      'concordance.jsonl.gz': '$envBaseUrl/concordance.jsonl.gz',
    };
  }
}


