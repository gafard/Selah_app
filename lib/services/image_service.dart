class ImageService {
  // Images de votre librairie postimg.cc/gallery/xc6Y4ZH
  // Rotation quotidienne des images pour une expérience dynamique
  
  // Toutes vos images disponibles
  static const List<String> _allImages = [
    'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
    'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
    'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
    'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
    'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
    'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
    'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
  ];
  
  // Mapping thématique avec rotation quotidienne
  static const Map<String, List<String>> _themedImages = {
    // Images pour Lecture/Bible
    'bible_reading': [
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
    ],
    'bible_open': [
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
    ],
    'scripture_study': [
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
    ],
    
    // Images pour Journal Spirituel
    'journal_writing': [
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
    ],
    'prayer_journal': [
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
    ],
    'spiritual_notes': [
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
    ],
    
    // Images pour Mur Spirituel
    'prayer_chapel': [
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
    ],
    'spiritual_wall': [
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
    ],
    'meditation_space': [
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
    ],
    
    // Images pour Quiz Biblique
    'bible_study': [
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
    ],
    'scripture_notes': [
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
    ],
    'bible_quiz': [
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
    ],
    
    // Images pour Communauté
    'community_fellowship': [
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
    ],
    'church_community': [
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
    ],
    'faith_sharing': [
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
    ],
    
    // Images pour Profil utilisateur - Image fixe de l'utilisateur
    'user_profile': [
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg', // Image fixe de l'utilisateur
    ],
    'christian_profile': [
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
    ],
    'faithful_user': [
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
    ],
    
    // Images pour Onboarding
    'onboarding_bible': [
      'https://i.postimg.cc/sGKV2JJ2/86b66393fe2abddb7aa772458d11673b.jpg',
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
    ],
    'onboarding_meditation': [
      'https://i.postimg.cc/MftWGYYc/caf319f92d5998a6cab7b4d462655071.jpg',
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
    ],
    'onboarding_growth': [
      'https://i.postimg.cc/8fw1Cbbv/f98d2e702a0b49aa477e41f5a7538ec4.jpg',
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
    ],
    
    // Images pour Splash/Logo
    'app_logo': [
      'https://i.postimg.cc/K3QZY55c/21b1298f86e169728b67a700d9f4268e.jpg',
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
    ],
    'splash_background': [
      'https://i.postimg.cc/JHK1hQQz/355c44bd5772246e2ee5167158dfbb2a.jpg',
      'https://i.postimg.cc/BPNqvCCJ/5b2435d6b855c469b3326e8ffa2c1fd5.jpg',
      'https://i.postimg.cc/p5k2dBBT/7f327ee3b2d9139dba52d8aeeac615b5.jpg',
    ],
  };
  
  /// Récupère une image selon sa thématique avec rotation quotidienne
  static String getImage(String theme) {
    final images = _themedImages[theme];
    if (images == null || images.isEmpty) {
      return _allImages[0]; // Fallback
    }
    
    // Calculer l'index basé sur le jour de l'année
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final imageIndex = dayOfYear % images.length;
    
    return images[imageIndex];
  }
  
  /// Récupère une image aléatoire pour une thématique (pour usage spécial)
  static String getRandomImage(String theme) {
    final images = _themedImages[theme];
    if (images == null || images.isEmpty) {
      return _allImages[0]; // Fallback
    }
    
    final random = DateTime.now().millisecondsSinceEpoch % images.length;
    return images[random];
  }
  
  /// Récupère toutes les images disponibles pour une thématique
  static List<String> getAllImagesForTheme(String theme) {
    return _themedImages[theme] ?? _allImages;
  }
  
  /// Récupère toutes les images disponibles
  static List<String> getAllImages() {
    return _allImages;
  }
  
  /// Récupère les images par catégorie
  static Map<String, List<String>> getImagesByCategory() {
    return {
      'bible': ['bible_reading', 'bible_open', 'scripture_study'],
      'journal': ['journal_writing', 'prayer_journal', 'spiritual_notes'],
      'prayer': ['prayer_chapel', 'spiritual_wall', 'meditation_space'],
      'study': ['bible_study', 'scripture_notes', 'bible_quiz'],
      'community': ['community_fellowship', 'church_community', 'faith_sharing'],
      'profile': ['user_profile', 'christian_profile', 'faithful_user'],
      'onboarding': ['onboarding_bible', 'onboarding_meditation', 'onboarding_growth'],
    };
  }
  
  /// Récupère le jour de l'année actuel (pour debug)
  static int getCurrentDayOfYear() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays;
  }
}