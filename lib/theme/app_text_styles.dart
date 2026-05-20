import 'package:flutter/material.dart';

class AppTextStyles {
  static const String headlineFontEn = 'Poppins';
  static const String bodyFontEn = 'Inter';
  static const String headlineFontAr = 'Cairo';
  static const String bodyFontAr = 'Cairo';

  static TextTheme getTextTheme(String languageCode) {
    final isAr = languageCode == 'ar';
    final headFont = isAr ? headlineFontAr : headlineFontEn;
    final bodyFont = isAr ? bodyFontAr : bodyFontEn;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: headFont,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: isAr ? 0 : -0.64,
      ),
      headlineLarge: TextStyle(
        fontFamily: headFont,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.28,
      ),
      headlineMedium: TextStyle(
        fontFamily: headFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
      headlineSmall: TextStyle(
        fontFamily: headFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: headFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
      titleMedium: TextStyle(
        fontFamily: headFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: isAr ? 0 : 0.14,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: isAr ? 0 : 0.55,
      ),
    );
  }

  static TextTheme get defaultTextTheme => getTextTheme('en');

  static TextStyle get displayLarge => getTextTheme('en').displayLarge!;
  static TextStyle get headlineLarge => getTextTheme('en').headlineLarge!;
  static TextStyle get headlineMedium => getTextTheme('en').headlineMedium!;
  static TextStyle get headlineSmall => getTextTheme('en').headlineSmall!;
  static TextStyle get bodyLarge => getTextTheme('en').bodyLarge!;
  static TextStyle get bodyMedium => getTextTheme('en').bodyMedium!;
  static TextStyle get bodySmall => getTextTheme('en').bodySmall!;
  static TextStyle get labelLarge => getTextTheme('en').labelLarge!;
  static TextStyle get labelSmall => getTextTheme('en').labelSmall!;
}
