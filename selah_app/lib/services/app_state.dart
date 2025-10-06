/// Service de gestion de l'état global de l'application
class AppState {
  bool _isLoading = false;
  bool _isFirstLaunch = true;
  String? _currentUser;
  bool _isLoggedIn = false;
  bool _hasOnboarded = false;
  String? _currentPlanId;
  Map<String, dynamic>? _profile;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;
  String? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasOnboarded => _hasOnboarded;
  String? get currentPlanId => _currentPlanId;
  Map<String, dynamic>? get profile => _profile;
  Map<String, dynamic>? get user => _profile;
  
  // Méthodes pour gérer l'état
  void setLoading(bool loading) {
    _isLoading = loading;
  }
  
  void setFirstLaunch(bool firstLaunch) {
    _isFirstLaunch = firstLaunch;
  }
  
  void setCurrentUser(String? user) {
    _currentUser = user;
  }
  
  void setLoggedIn(bool loggedIn) {
    _isLoggedIn = loggedIn;
  }
  
  void setOnboarded(bool onboarded) {
    _hasOnboarded = onboarded;
  }
  
  void setCurrentPlanId(String? planId) {
    _currentPlanId = planId;
  }
  
  void setProfile(Map<String, dynamic>? profile) {
    _profile = profile;
  }
  
  // Singleton
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();
}