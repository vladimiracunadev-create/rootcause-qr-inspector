import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light({bool highContrast = false, bool largeControls = false, bool reduceMotion = false}) =>
      _build(Brightness.light, highContrast: highContrast, largeControls: largeControls, reduceMotion: reduceMotion);

  static ThemeData dark({bool highContrast = false, bool largeControls = false, bool reduceMotion = false}) =>
      _build(Brightness.dark, highContrast: highContrast, largeControls: largeControls, reduceMotion: reduceMotion);

  static ThemeData _build(
    Brightness brightness, {
    required bool highContrast,
    required bool largeControls,
    required bool reduceMotion,
  }) {
    final bool dark = brightness == Brightness.dark;
    final Color seed = dark ? const Color(0xFF43E0C4) : const Color(0xFF006C61);
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      contrastLevel: highContrast ? 1.0 : 0.0,
    ).copyWith(
      primary: dark ? const Color(0xFF59E3CA) : const Color(0xFF006C61),
      onPrimary: dark ? const Color(0xFF00201C) : Colors.white,
      secondary: dark ? const Color(0xFF9BCAC1) : const Color(0xFF406760),
      tertiary: dark ? const Color(0xFFFFC56E) : const Color(0xFF805500),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      surface: dark ? const Color(0xFF071411) : const Color(0xFFF5F8F7),
      surfaceContainerLowest: dark ? const Color(0xFF04100E) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF0C1C18) : const Color(0xFFEDF3F1),
      surfaceContainer: dark ? const Color(0xFF11231E) : const Color(0xFFE6EFEC),
      surfaceContainerHigh: dark ? const Color(0xFF193029) : const Color(0xFFDDE9E6),
      outline: dark ? const Color(0xFF78918A) : const Color(0xFF6F817C),
      outlineVariant: dark ? const Color(0xFF354C46) : const Color(0xFFC4D3CF),
    );
    final TextTheme text = ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        );
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.surface,
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.1),
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.45),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.25),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
      visualDensity: largeControls ? const VisualDensity(horizontal: 1, vertical: 1) : VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: _NoTransitionsBuilder(),
              TargetPlatform.iOS: _NoTransitionsBuilder(),
              TargetPlatform.macOS: _NoTransitionsBuilder(),
              TargetPlatform.windows: _NoTransitionsBuilder(),
              TargetPlatform.linux: _NoTransitionsBuilder(),
              TargetPlatform.fuchsia: _NoTransitionsBuilder(),
            })
          : const PageTransitionsTheme(),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: highContrast ? 1 : 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: highContrast ? colors.outline : colors.outlineVariant.withValues(alpha: 0.65),
            width: highContrast ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
          return text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? colors.primary : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: colors.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLow,
        selectedColor: colors.primaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: text.labelLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        modalBackgroundColor: colors.surfaceContainerLowest,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant.withValues(alpha: 0.75)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF18352D) : const Color(0xFF113D35),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) => child;
}
