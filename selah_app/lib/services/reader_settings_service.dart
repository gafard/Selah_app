import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/reader_settings.dart';

class ReaderSettingsService extends ChangeNotifier {
  static final ReaderSettingsService _instance = ReaderSettingsService._internal();
  factory ReaderSettingsService() => _instance;
  ReaderSettingsService._internal();

  ReaderSettings _settings = const ReaderSettings();
  static const String _settingsKey = 'reader_settings';

  // Getters
  String get selectedTheme => _settings.theme;
  String get selectedFont => _settings.font;
  double get fontSize => _settings.fontSize;
  String get textAlignment => _settings.textAlignment;
  bool get isOfflineMode => _settings.isOfflineMode;
  bool get isLocked => _settings.isLocked;
  bool get isSearchEnabled => _settings.isSearchEnabled;
  bool get isTransitionsEnabled => _settings.isTransitionsEnabled;
  double get brightness => _settings.brightness;

  ReaderSettings get settings => _settings;

  // Initialize settings from storage
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        _settings = ReaderSettings.fromJson(jsonDecode(settingsJson));
        notifyListeners();
      }
    } catch (e) {
      // Use default settings if loading fails
      _settings = const ReaderSettings();
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      // Handle save error silently
    }
  }

  // Setters
  void setTheme(String theme) {
    _settings = _settings.copyWith(theme: theme);
    _saveSettings();
    notifyListeners();
  }

  void setFont(String font) {
    _settings = _settings.copyWith(font: font);
    _saveSettings();
    notifyListeners();
  }

  void setFontSize(double size) {
    _settings = _settings.copyWith(fontSize: size);
    _saveSettings();
    notifyListeners();
  }

  void setTextAlignment(String alignment) {
    _settings = _settings.copyWith(textAlignment: alignment);
    _saveSettings();
    notifyListeners();
  }

  void setOfflineMode(bool enabled) {
    _settings = _settings.copyWith(isOfflineMode: enabled);
    _saveSettings();
    notifyListeners();
  }

  void setLocked(bool locked) {
    _settings = _settings.copyWith(isLocked: locked);
    _saveSettings();
    notifyListeners();
  }

  void setSearchEnabled(bool enabled) {
    _settings = _settings.copyWith(isSearchEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  void setTransitionsEnabled(bool enabled) {
    _settings = _settings.copyWith(isTransitionsEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  void setBrightness(double brightness) {
    _settings = _settings.copyWith(brightness: brightness);
    _saveSettings();
    notifyListeners();
  }

  // Helper methods
  TextStyle getFontStyle() {
    Color textColor = _settings.theme == 'dark' ? Colors.white : const Color(0xFF333333);
    
    // Apply brightness with minimum value to avoid text disappearing
    double adjustedBrightness = (_settings.brightness * 0.7) + 0.3; // Keep between 30% and 100% brightness
    textColor = Color.fromRGBO(
      (textColor.red * adjustedBrightness).round(),
      (textColor.green * adjustedBrightness).round(),
      (textColor.blue * adjustedBrightness).round(),
      textColor.opacity,
    );

    return _settings.getFontStyle().copyWith(
      color: textColor,
      height: 1.6,
    );
  }

  TextAlign getTextAlign() {
    return _settings.getTextAlign();
  }

  Color getBackgroundColor() {
    return _settings.theme == 'dark' ? const Color(0xFF2D2D2D) : Colors.white;
  }
}