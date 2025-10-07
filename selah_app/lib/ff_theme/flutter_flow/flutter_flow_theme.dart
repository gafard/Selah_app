import 'package:flutter/material.dart';

class FlutterFlowTheme {
  static FlutterFlowTheme of(BuildContext context) {
    return FlutterFlowTheme();
  }

  Color get accent3 => Colors.grey[100]!;
  Color get secondaryBackground => Colors.white;
  Color get tertiary => Colors.purple;
  Color get error => Colors.red;
  Color get success => Colors.green;
  Color get accent2 => Colors.orange;
  Color get info => Colors.blue;
  Color get lightMutedColor => Colors.white70;
  Color get darkMutedColor => Colors.black87;
  Color get textColor => Colors.black;
  Color get primaryBackground => Colors.white;
  Color get secondaryText => Colors.grey;

  TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
  );

  TextStyle bodyMediumOverride({
    required TextStyle font,
    required Color color,
    required double fontSize,
    required double letterSpacing,
    required FontWeight fontWeight,
    required FontStyle fontStyle,
    double? lineHeight,
    List<Shadow>? shadows,
  }) {
    return font.copyWith(
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: lineHeight,
      shadows: shadows,
    );
  }
}