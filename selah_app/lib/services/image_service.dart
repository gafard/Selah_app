class ImageService {
  static const String _baseUrl = 'https://images.unsplash.com/photo-';
  
  static String getImage(String imageKey) {
    switch (imageKey) {
      case 'onboarding_bible':
        return '${_baseUrl}1507003211169-0a1dd7d1c6a5?w=400&h=400&fit=crop&crop=center';
      case 'onboarding_meditation':
        return '${_baseUrl}1544367567-0f2fcb009e0b?w=400&h=400&fit=crop&crop=center';
      case 'onboarding_growth':
        return '${_baseUrl}1506905925346-21bda4d32df4?w=400&h=400&fit=crop&crop=center';
      // Images pour les thèmes Thompson
      case 'peace':
        return '${_baseUrl}1506905925346-21bda4d32df4?w=400&h=400&fit=crop&crop=center';
      case 'discipline':
        return '${_baseUrl}1507003211169-0a1dd7d1c6a5?w=400&h=400&fit=crop&crop=center';
      case 'marriage':
        return '${_baseUrl}1519681393784-d120267933ba?w=400&h=400&fit=crop&crop=center';
      case 'community_fellowship':
        return '${_baseUrl}1506801310323-534be5e7f004?w=400&h=400&fit=crop&crop=center';
      case 'prayer':
        return '${_baseUrl}1544367567-0f2fcb009e0b?w=400&h=400&fit=crop&crop=center';
      case 'faith':
        return '${_baseUrl}1506905925346-21bda4d32df4?w=400&h=400&fit=crop&crop=center';
      case 'wisdom':
        return '${_baseUrl}1507003211169-0a1dd7d1c6a5?w=400&h=400&fit=crop&crop=center';
      case 'bible_reading':
        return '${_baseUrl}1507003211169-0a1dd7d1c6a5?w=400&h=400&fit=crop&crop=center';
      default:
        return '${_baseUrl}1507003211169-0a1dd7d1c6a5?w=400&h=400&fit=crop&crop=center';
    }
  }

  static String heroForGoal(String goal) {
    switch (goal) {
      case 'memorisation':
        return 'https://cdn.jsdelivr.net/gh/aurora-ui/medit/assets/hero_memorize.png';
      case 'discipline':
        return 'https://cdn.jsdelivr.net/gh/aurora-ui/medit/assets/hero_schedule.png';
      case 'connaissance':
        return 'https://cdn.jsdelivr.net/gh/aurora-ui/medit/assets/hero_learn.png';
      default:
        return 'https://cdn.jsdelivr.net/gh/aurora-ui/medit/assets/hero_generic.png';
    }
  }
}