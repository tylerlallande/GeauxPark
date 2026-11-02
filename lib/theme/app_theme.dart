import 'package:flutter/material.dart';

/// Brand and semantic colors for GeauxPark.
///
/// Screens should read colors from `Theme.of(context).colorScheme` where a
/// matching role exists (primary, secondary, tertiary, surface, outline...).
/// Use these constants only for the few values the color scheme does not
/// cover, such as text on the purple brand panels.
abstract final class AppColors {
  /// LSU purple. Headers, brand panels, selected states.
  static const purple = Color(0xFF461D7C);

  /// LSU gold. Accents, highlights, selected chips and nav indicator.
  static const gold = Color(0xFFFDD023);

  /// Action blue. Primary buttons, focus rings, availability, live location.
  static const actionBlue = Color(0xFF1464A5);

  /// Main text color.
  static const ink = Color(0xFF24152F);

  /// Secondary text color.
  static const inkMuted = Color(0xFF615869);

  /// App background.
  static const surface = Color(0xFFF8F7FB);

  /// Cards, inputs, and raised surfaces.
  static const card = Colors.white;

  /// Hairline borders on cards, inputs, and chips.
  static const border = Color(0xFFE5DDEC);

  /// Body text placed on a [purple] panel.
  static const onPurpleMuted = Color(0xD1FFFFFF);

  /// Captions and timestamps placed on a [purple] panel.
  static const onPurpleSubtle = Color(0xB3FFFFFF);
}

/// Corner radii shared across the app, smallest to largest.
abstract final class AppRadii {
  static const tag = 6.0;
  static const chip = 12.0;
  static const button = 16.0;
  static const card = 18.0;
  static const panel = 24.0;
}

/// Spacing scale. Screens use [screen] for their outer horizontal padding.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const screen = 20.0;
  static const section = 24.0;
}

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.light,
      primary: AppColors.purple,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      tertiary: AppColors.actionBlue,
      onTertiary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      useMaterial3: true,
      textTheme: _textTheme(colorScheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
        margin: EdgeInsets.zero,
      ),
      searchBarTheme: const SearchBarThemeData(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(AppColors.card),
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
          borderSide: BorderSide(color: AppColors.actionBlue, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.actionBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.gold.withValues(alpha: 0.3),
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.chip)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.gold.withValues(alpha: 0.32),
        elevation: 8,
        shadowColor: AppColors.purple.withValues(alpha: 0.14),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  /// Text styles for the whole app. Screens use these roles directly and
  /// only override color, never size or weight.
  ///
  /// | Role            | Size | Weight | Used for                         |
  /// |-----------------|------|--------|----------------------------------|
  /// | headlineSmall   | 24   | 900    | Screen titles, lot name on hero  |
  /// | titleLarge      | 22   | 900    | Brand wordmark, empty states     |
  /// | titleMedium     | 16   | 800    | Section and card titles          |
  /// | bodyLarge       | 16   | 400    | Subtitles and paragraphs         |
  /// | bodyMedium      | 14   | 400    | Default body text                |
  /// | bodySmall       | 12   | 400    | Captions and secondary lines     |
  /// | labelLarge      | 14   | 800    | Values, counts, inline actions   |
  /// | labelMedium     | 12   | 600    | Lot facts (distance, price)      |
  /// | labelSmall      | 11   | 900    | Status tags (OPEN NOW, FULL)     |
  static TextTheme _textTheme(ColorScheme colors) {
    final base = Typography.material2021(colorScheme: colors).black
        .apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}
