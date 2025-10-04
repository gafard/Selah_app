import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentPlanId;
  int _currentDayNumber = 1;
  List<String> _currentReferences = [];
  final bool _isLoggedIn = false;
  final bool _hasOnboarded = false;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _user;

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get currentPlanId => _currentPlanId;
  int get currentDayNumber => _currentDayNumber;
  List<String> get currentReferences => _currentReferences;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasOnboarded => _hasOnboarded;
  Map<String, dynamic>? get profile => _profile;
  Map<String, dynamic>? get user => _user;

  // Setters
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set currentUserId(String? value) {
    _currentUserId = value;
    notifyListeners();
  }

  set currentPlanId(String? value) {
    _currentPlanId = value;
    notifyListeners();
  }

  set currentDayNumber(int value) {
    _currentDayNumber = value;
    notifyListeners();
  }

  set currentReferences(List<String> value) {
    _currentReferences = value;
    notifyListeners();
  }

  // Methods
  void initializeApp() async {
    isLoading = true;
    
    // Simulate initialization
    await Future.delayed(const Duration(seconds: 2));
    
    // Set default values
    _currentUserId = 'user_123';
    _currentPlanId = 'plan_1';
    _currentDayNumber = 1;
    _currentReferences = ['Jean 3:16-18'];
    
    isLoading = false;
  }

  void updateCurrentDay(int dayNumber, List<String> references) {
    _currentDayNumber = dayNumber;
    _currentReferences = references;
    notifyListeners();
  }

  void reset() {
    _isLoading = true;
    _currentUserId = null;
    _currentPlanId = null;
    _currentDayNumber = 1;
    _currentReferences = [];
    notifyListeners();
  }
}