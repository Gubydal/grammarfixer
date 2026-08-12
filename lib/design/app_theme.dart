import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Primary bundled font. Rubik is the fallback (also bundled) so Arabic and
/// other scripts that Lexend Deca does not cover still render consistently.
const String kAppFontFamily = 'LexendDeca';

ThemeData lightMode = _buildTheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  background: AppColors.lightBackground,
  surface: AppColors.lightSurface,
  surfaceContainer: AppColors.lightSurfaceContainer,
  onSurface: AppColors.onLightSurface,
  onSurfaceVariant: AppColors.onLightSurfaceVariant,
  outline: AppColors.lightOutline,
);

ThemeData darkMode = _buildTheme(
  brightness: Brightness.dark,
  primary: AppColors.darkPrimary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.darkPrimaryContainer,
  onPrimaryContainer: AppColors.darkOnPrimaryContainer,
  secondaryContainer: AppColors.darkSurfaceContainer,
  onSecondaryContainer: AppColors.onDarkSurface,
  background: AppColors.darkBackground,
  surface: AppColors.darkSurface,
  surfaceContainer: AppColors.darkSurfaceContainer,
  onSurface: AppColors.onDarkSurface,
  onSurfaceVariant: AppColors.onDarkSurfaceVariant,
  outline: AppColors.darkOutline,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required Color primary,
  required Color onPrimary,
  required Color primaryContainer,
  required Color onPrimaryContainer,
  required Color secondaryContainer,
  required Color onSecondaryContainer,
  required Color background,
  required Color surface,
  required Color surfaceContainer,
  required Color onSurface,
  required Color onSurfaceVariant,
  required Color outline,
}) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: onSurfaceVariant,
    onSecondary: surface,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: AppColors.warning,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFFFE0CC),
    onTertiaryContainer: const Color(0xFF5C2400),
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceContainer,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outline,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: onSurface,
    onInverseSurface: surface,
    inversePrimary: primaryContainer,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: kAppFontFamily,
    fontFamilyFallback: ['Rubik'],
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 9,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: background,
      foregroundColor: onSurface,
      titleTextStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainer,
      labelStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      hintStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: primary,
        foregroundColor: onPrimary,
        disabledBackgroundColor: onSurfaceVariant.withValues(alpha: 0.3),
        disabledForegroundColor: onSurface.withValues(alpha: 0.4),
        textStyle: const TextStyle(
          fontFamily: kAppFontFamily,
          fontFamilyFallback: ['Rubik'],
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        foregroundColor: onSurface,
        side: BorderSide(color: outline),
        textStyle: const TextStyle(
          fontFamily: kAppFontFamily,
          fontFamilyFallback: ['Rubik'],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(
          fontFamily: kAppFontFamily,
          fontFamilyFallback: ['Rubik'],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceContainer,
      selectedColor: primary,
      labelStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: kAppFontFamily,
          fontFamilyFallback: ['Rubik'],
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primary : onSurfaceVariant,
          size: 24,
        );
      }),
    ),
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: onSurfaceVariant,
      textColor: onSurface,
      titleTextStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontFamilyFallback: ['Rubik'],
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
    ),
  );
}
