import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReaderSettings {
  final String theme;
  final String font;
  final double fontSize;
  final double brightness;
  final String textAlignment;
  final bool isOfflineMode;
  final bool isLocked;
  final bool isSearchEnabled;
  final bool isTransitionsEnabled;

  const ReaderSettings({
    this.theme = 'light',
    this.font = 'Inter',
    this.fontSize = 16.0,
    this.brightness = 1.0,
    this.textAlignment = 'Left',
    this.isOfflineMode = false,
    this.isLocked = false,
    this.isSearchEnabled = true,
    this.isTransitionsEnabled = true,
  });

  ReaderSettings copyWith({
    String? theme,
    String? font,
    double? fontSize,
    double? brightness,
    String? textAlignment,
    bool? isOfflineMode,
    bool? isLocked,
    bool? isSearchEnabled,
    bool? isTransitionsEnabled,
  }) {
    return ReaderSettings(
      theme: theme ?? this.theme,
      font: font ?? this.font,
      fontSize: fontSize ?? this.fontSize,
      brightness: brightness ?? this.brightness,
      textAlignment: textAlignment ?? this.textAlignment,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isLocked: isLocked ?? this.isLocked,
      isSearchEnabled: isSearchEnabled ?? this.isSearchEnabled,
      isTransitionsEnabled: isTransitionsEnabled ?? this.isTransitionsEnabled,
    );
  }

  TextStyle getFontStyle() {
    return GoogleFonts.getFont(
      font,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
    );
  }

  TextAlign getTextAlign() {
    switch (textAlignment) {
      case 'Left':
        return TextAlign.left;
      case 'Center':
        return TextAlign.center;
      case 'Right':
        return TextAlign.right;
      case 'Justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'font': font,
    'fontSize': fontSize,
    'brightness': brightness,
    'textAlignment': textAlignment,
    'isOfflineMode': isOfflineMode,
    'isLocked': isLocked,
    'isSearchEnabled': isSearchEnabled,
    'isTransitionsEnabled': isTransitionsEnabled,
  };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
    theme: json['theme'] ?? 'light',
    font: json['font'] ?? 'Inter',
    fontSize: (json['fontSize'] ?? 16.0).toDouble(),
    brightness: (json['brightness'] ?? 1.0).toDouble(),
    textAlignment: json['textAlignment'] ?? 'Left',
    isOfflineMode: json['isOfflineMode'] ?? false,
    isLocked: json['isLocked'] ?? false,
    isSearchEnabled: json['isSearchEnabled'] ?? true,
    isTransitionsEnabled: json['isTransitionsEnabled'] ?? true,
  );
}
