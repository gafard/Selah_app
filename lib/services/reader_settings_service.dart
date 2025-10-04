import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ReaderSettingsService extends ChangeNotifier {
  static final ReaderSettingsService _instance = ReaderSettingsService._internal();
  factory ReaderSettingsService() => _instance;
  ReaderSettingsService._internal();

  // Settings
  String _selectedTheme = 'light';
  String _selectedVoice = 'default';
          String _selectedFont = 'Inter';
  double _fontSize = 15.0;
  double _fontWeight = 400.0;
  bool _ligaturesEnabled = false;
  String _textAlignment = 'Default';
  bool _isOfflineMode = false;
  bool _isLocked = false;
  bool _isSearchEnabled = false;
  bool _isTransitionsEnabled = false;
  double _brightness = 1.0;

  // Getters
  String get selectedTheme => _selectedTheme;
  String get selectedVoice => _selectedVoice;
  String get selectedFont => _selectedFont;
  double get fontSize => _fontSize;
  double get fontWeight => _fontWeight;
  bool get ligaturesEnabled => _ligaturesEnabled;
  String get textAlignment => _textAlignment;
  bool get isOfflineMode => _isOfflineMode;
  bool get isLocked => _isLocked;
  bool get isSearchEnabled => _isSearchEnabled;
  bool get isTransitionsEnabled => _isTransitionsEnabled;
  double get brightness => _brightness;

  // Setters
  void setTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  void setVoice(String voice) {
    _selectedVoice = voice;
    notifyListeners();
  }

  void setFont(String font) {
    _selectedFont = font;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setFontWeight(double weight) {
    _fontWeight = weight;
    notifyListeners();
  }

  void setLigaturesEnabled(bool enabled) {
    _ligaturesEnabled = enabled;
    notifyListeners();
  }

  void setTextAlignment(String alignment) {
    _textAlignment = alignment;
    notifyListeners();
  }

  void setOfflineMode(bool enabled) {
    _isOfflineMode = enabled;
    notifyListeners();
  }

  void setLocked(bool locked) {
    _isLocked = locked;
    notifyListeners();
  }

  void setSearchEnabled(bool enabled) {
    _isSearchEnabled = enabled;
    notifyListeners();
  }

  void setTransitionsEnabled(bool enabled) {
    _isTransitionsEnabled = enabled;
    notifyListeners();
  }

  void setBrightness(double brightness) {
    _brightness = brightness;
    notifyListeners();
  }

  // Helper methods
  TextStyle getFontStyle() {
    Color textColor = _selectedTheme == 'dark' ? Colors.white : const Color(0xFF333333);
    
    // Appliquer la luminosité avec une valeur minimale pour éviter que le texte disparaisse
    double adjustedBrightness = (_brightness * 0.7) + 0.3; // Garde entre 30% et 100% de luminosité
    textColor = Color.fromRGBO(
      (textColor.red * adjustedBrightness).round(),
      (textColor.green * adjustedBrightness).round(),
      (textColor.blue * adjustedBrightness).round(),
      textColor.opacity,
    );

          // Sélectionner la police Google Fonts
          TextStyle baseStyle;
          switch (_selectedFont) {
            case 'Inter':
              baseStyle = GoogleFonts.inter();
              break;
            case 'Playfair Display':
              baseStyle = GoogleFonts.playfairDisplay();
              break;
            case 'Lora':
              baseStyle = GoogleFonts.lora();
              break;
            case 'Poppins':
              baseStyle = GoogleFonts.poppins();
              break;
            case 'Montserrat':
              baseStyle = GoogleFonts.montserrat();
              break;
            case 'Source Sans Pro':
              baseStyle = GoogleFonts.roboto(); // Alternative disponible
              break;
            case 'Open Sans':
              baseStyle = GoogleFonts.openSans();
              break;
            case 'Roboto':
              baseStyle = GoogleFonts.roboto();
              break;
            case 'Nunito':
              baseStyle = GoogleFonts.nunito();
              break;
            case 'Work Sans':
              baseStyle = GoogleFonts.workSans();
              break;
            default:
              baseStyle = GoogleFonts.inter();
          }

    return baseStyle.copyWith(
      fontSize: _fontSize,
      fontWeight: _fontWeight <= 300 
          ? FontWeight.w300
          : _fontWeight <= 400 
              ? FontWeight.w400
              : _fontWeight <= 500
                  ? FontWeight.w500
                  : _fontWeight <= 600
                      ? FontWeight.w600
                      : FontWeight.w700,
      height: 1.6,
      color: textColor,
      fontFeatures: _ligaturesEnabled ? [const FontFeature('liga', 1)] : [],
    );
  }

  TextAlign getTextAlign() {
    switch (_textAlignment) {
      case 'Justify':
        return TextAlign.justify;
      case 'Center':
        return TextAlign.center;
      case 'Right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Color getBackgroundColor() {
    return _selectedTheme == 'dark' ? const Color(0xFF2D2D2D) : Colors.white;
  }
}
