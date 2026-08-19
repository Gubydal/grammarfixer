import 'package:flutter/material.dart';

/// Semantic color tokens for GrammarFix (White + Green design system).
///
/// Designed to feel clean, calm, private, trustworthy, and writing-focused.
/// Replaces legacy red/starter palettes completely.
abstract final class AppColors {
  // Brand Primary (Forest Green)
  static const Color primary = Color(0xFF178A4B);
  static const Color primaryPressed = Color(0xFF116B39);
  static const Color primarySoft = Color(0xFFDDF3E5);
  static const Color primaryStrong = Color(0xFF0D5A30);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Light Palette
  static const Color lightBackground = Color(0xFFF8FBF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSoft = Color(0xFFF0F7F2);
  static const Color lightSurfaceStrong = Color(0xFFE5F1E8);
  static const Color lightTextPrimary = Color(0xFF17231B);
  static const Color lightTextSecondary = Color(0xFF5A685F);
  static const Color lightTextTertiary = Color(0xFF849087);
  static const Color lightBorder = Color(0xFFDCE6DF);
  static const Color lightBorderStrong = Color(0xFFC5D4C9);

  // Dark Palette (Green-tinted dark mode)
  static const Color darkBackground = Color(0xFF0C1410);
  static const Color darkSurface = Color(0xFF121D16);
  static const Color darkSurfaceElevated = Color(0xFF19271E);
  static const Color darkSurfaceGreen = Color(0xFF163322);
  static const Color darkPrimary = Color(0xFF66D58C);
  static const Color darkPrimaryPressed = Color(0xFF80E39F);
  static const Color darkPrimarySoft = Color(0xFF183B26);
  static const Color darkTextPrimary = Color(0xFFF2F8F3);
  static const Color darkTextSecondary = Color(0xFFC2CEC5);
  static const Color darkTextTertiary = Color(0xFF8EA096);
  static const Color darkBorder = Color(0xFF27382D);
  static const Color onDarkPrimary = Color(0xFF0C1410);

  // Semantic Correction Tokens
  static const Color issueAmberBg = Color(0xFFFFF2DF);
  static const Color issueAmberBorder = Color(0xFFD97706);
  static const Color issueCoralBg = Color(0xFFFEF2F2);
  static const Color issueCoralBorder = Color(0xFFDC2626);

  static const Color fixedGreenBg = Color(0xFFDDF3E5);
  static const Color fixedGreenBorder = Color(0xFF178A4B);

  static const Color ignoredBg = Color(0xFFF3F4F6);
  static const Color ignoredBorder = Color(0xFF6B7280);

  // Semantic Status Tokens
  static const Color success = Color(0xFF178A4B);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0284C7);
  static const Color error = Color(0xFFDC2626);
}
