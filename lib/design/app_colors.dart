import 'package:flutter/material.dart';

/// Semantic color tokens used across the template.
///
/// This is the default "Mogate" visual language: a warm neutral base with a
/// brand accent. Future apps may override these values when a Figma design
/// provides a different palette, but the token names stay stable.
abstract final class AppColors {
  // Brand accent (default warm red).
  static const Color primary = Color(0xFFE53935);
  static const Color primaryDark = Color(0xFFC62828);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFE3E1);
  static const Color onPrimaryContainer = Color(0xFF8C1D18);
  static const Color secondaryContainer = Color(0xFFFFDAD6);
  static const Color onSecondaryContainer = Color(0xFF5C1B17);

  // Light neutrals.
  static const Color lightBackground = Color(0xFFFDF7F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF6ECEC);
  static const Color onLightSurface = Color(0xFF24252C);
  static const Color onLightSurfaceVariant = Color(0xFF6E6A7C);
  static const Color lightOutline = Color(0xFFE7DCDC);

  // Dark neutrals.
  static const Color darkBackground = Color(0xFF17151A);
  static const Color darkSurface = Color(0xFF1F1C22);
  static const Color darkSurfaceContainer = Color(0xFF2A252C);
  static const Color onDarkSurface = Color(0xFFEDE9EE);
  static const Color onDarkSurfaceVariant = Color(0xFFA9A1B0);
  static const Color darkOutline = Color(0xFF3B353D);
  static const Color darkPrimary = Color(0xFFFF6B6B);
  static const Color darkPrimaryContainer = Color(0xFF4C1E1E);
  static const Color darkOnPrimaryContainer = Color(0xFFFFDAD6);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFF9142);
  static const Color info = Color(0xFF0087FF);
  static const Color error = Color(0xFFB3261E);
}
