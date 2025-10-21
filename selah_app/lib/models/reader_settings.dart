import 'package:flutter/material.dart';

class ReaderSettings {
  final String theme;
  final String font;
  final double fontSize;
  final double brightness;
  final String textAlignment;
  final bool isSearchEnabled;

  const ReaderSettings({
    this.theme = 'light',
    this.font = 'Gilroy',
    this.fontSize = 16.0,
    this.brightness = 1.0,
    this.textAlignment = 'Left',
    this.isSearchEnabled = true,
  });

  ReaderSettings copyWith({
    String? theme,
    String? font,
    double? fontSize,
    double? brightness,
    String? textAlignment,
    bool? isSearchEnabled,
  }) {
    return ReaderSettings(
      theme: theme ?? this.theme,
      font: font ?? this.font,
      fontSize: fontSize ?? this.fontSize,
      brightness: brightness ?? this.brightness,
      textAlignment: textAlignment ?? this.textAlignment,
      isSearchEnabled: isSearchEnabled ?? this.isSearchEnabled,
    );
  }

  TextStyle getFontStyle() {
    switch (font.toLowerCase().replaceAll(' ', '')) {
      case 'gilroy':
        return TextStyle(
          fontFamily: 'Gilroy',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
      case 'inter':
        // Utilise Inter si disponible, sinon fallback vers Roboto (système Android)
        return TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
      case 'lora':
        // Utilise Lora si disponible, sinon fallback vers serif système
        return TextStyle(
          fontFamily: 'Lora',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
      case 'roboto':
        // Roboto est disponible par défaut sur Android
        return TextStyle(
          fontFamily: 'Roboto',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
      case 'merriweather':
        // Utilise Merriweather si disponible, sinon fallback vers serif système
        return TextStyle(
          fontFamily: 'Merriweather',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
      case 'ptserif':
        // Utilise PT Serif si disponible, sinon fallback vers serif système
        return TextStyle(
          fontFamily: 'PT Serif',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
      default:
        print('⚠️ Police "$font" non reconnue, fallback vers Gilroy');
        return TextStyle(
          fontFamily: 'Gilroy',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        );
    }
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
    'isSearchEnabled': isSearchEnabled,
  };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
    theme: json['theme'] ?? 'light',
    font: json['font'] ?? 'Gilroy',
    fontSize: (json['fontSize'] ?? 16.0).toDouble(),
    brightness: (json['brightness'] ?? 1.0).toDouble(),
    textAlignment: json['textAlignment'] ?? 'Left',
    isSearchEnabled: json['isSearchEnabled'] ?? true,
  );
}
