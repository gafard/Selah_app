import 'package:flutter/material.dart';

class FlutterFlowTheme {
  static FlutterFlowTheme of(BuildContext context) {
    return FlutterFlowTheme();
  }

  Color get accent3 => const Color(0xFFF3F4F6);
  Color get secondaryBackground => Colors.white;
  Color get tertiary => const Color(0xFF8B5CF6);
  Color get error => const Color(0xFFEF4444);
  Color get success => const Color(0xFF10B981);
  Color get accent2 => const Color(0xFF06B6D4);
  Color get info => const Color(0xFF3B82F6);
  Color get lightMutedColor => Colors.white;
  Color get darkMutedColor => const Color(0xFF374151);
  Color get primaryBackground => Colors.white;
  Color get secondaryText => const Color(0xFF6B7280);
  Color get textColor => const Color(0xFF1F2937);

  TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF374151),
  );
}
