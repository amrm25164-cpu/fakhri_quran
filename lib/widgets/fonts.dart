import 'package:flutter/material.dart';

/// Separate font family per text role. Only the Quran role uses the
/// Uthmanic Hafs font (registered by the build when the file exists).
class AppFonts {
  static const Map<String, String?> family = {
    'quran': 'UthmanicHafs',
    'tafsir': null,
    'translation': null,
    'title': null,
    'reciter': null,
  };
  static const fallback = ['Noto Naskh Arabic', 'Amiri', 'Roboto'];

  static TextStyle of(String role, double size, {double? h, Color? c, FontWeight? w}) => TextStyle(
        fontFamily: family[role],
        fontFamilyFallback: fallback,
        fontSize: size,
        height: h,
        color: c,
        fontWeight: w,
      );
}
