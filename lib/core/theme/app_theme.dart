import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AppColors — ThemeExtension for tokens that live outside standard
// ColorScheme / ThemeData slots.
// ---------------------------------------------------------------------------

/// Custom colour tokens that supplement the standard [ColorScheme].
///
/// Access in widgets via [AppColorsContext.appColors] or:
/// ```dart
/// final appColors = Theme.of(context).extension<AppColors>()!;
/// ```
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Creates an [AppColors] instance.
  const AppColors({
    required this.success,
    required this.badgeLive,
    required this.badgeUpcoming,
    required this.badgePast,
    required this.badgeNew,
    required this.badgeLiveText,
    required this.badgeUpcomingText,
    required this.badgePastText,
    required this.badgeNewText,
  });

  /// Colour used for success SnackBars and positive confirmations.
  final Color success;

  /// Background colour for "Live" status badges.
  final Color badgeLive;

  /// Background colour for "Upcoming" status badges.
  final Color badgeUpcoming;

  /// Background colour for "Past" status badges.
  final Color badgePast;

  /// Background colour for "New / Updated" status badges.
  final Color badgeNew;

  /// Foreground text colour for "Live" status badges.
  final Color badgeLiveText;

  /// Foreground text colour for "Upcoming" status badges.
  final Color badgeUpcomingText;

  /// Foreground text colour for "Past" status badges.
  final Color badgePastText;

  /// Foreground text colour for "New / Updated" status badges.
  final Color badgeNewText;

  @override
  AppColors copyWith({
    Color? success,
    Color? badgeLive,
    Color? badgeUpcoming,
    Color? badgePast,
    Color? badgeNew,
    Color? badgeLiveText,
    Color? badgeUpcomingText,
    Color? badgePastText,
    Color? badgeNewText,
  }) {
    return AppColors(
      success: success ?? this.success,
      badgeLive: badgeLive ?? this.badgeLive,
      badgeUpcoming: badgeUpcoming ?? this.badgeUpcoming,
      badgePast: badgePast ?? this.badgePast,
      badgeNew: badgeNew ?? this.badgeNew,
      badgeLiveText: badgeLiveText ?? this.badgeLiveText,
      badgeUpcomingText: badgeUpcomingText ?? this.badgeUpcomingText,
      badgePastText: badgePastText ?? this.badgePastText,
      badgeNewText: badgeNewText ?? this.badgeNewText,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      badgeLive: Color.lerp(badgeLive, other.badgeLive, t)!,
      badgeUpcoming: Color.lerp(badgeUpcoming, other.badgeUpcoming, t)!,
      badgePast: Color.lerp(badgePast, other.badgePast, t)!,
      badgeNew: Color.lerp(badgeNew, other.badgeNew, t)!,
      badgeLiveText: Color.lerp(badgeLiveText, other.badgeLiveText, t)!,
      badgeUpcomingText: Color.lerp(
        badgeUpcomingText,
        other.badgeUpcomingText,
        t,
      )!,
      badgePastText: Color.lerp(badgePastText, other.badgePastText, t)!,
      badgeNewText: Color.lerp(badgeNewText, other.badgeNewText, t)!,
    );
  }
}

/// Named button style helpers for non-standard button variants.
abstract final class AppButtonStyles {
  /// Primary filled button — used for prominent actions like "Download task".
  /// Uses theme's primary colour for background and onPrimary for foreground.
  static ButtonStyle primary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  /// Success-coloured filled button — used for the full-width "Fly XCSoar"
  /// CTA. Uses [AppColors.success] for background, sized to match the other
  /// full-width buttons ("Download task", "Email flight logs").
  static ButtonStyle success(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: context.appColors.success,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  /// Full-width white/outlined button — used for secondary-weight CTAs that
  /// still need a comfortable, easy-to-hit target (e.g. "Email flight
  /// logs"), sized to match the full-width "Download task" button.
  static ButtonStyle outlinedFullWidth(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: primary.withValues(alpha: 0.3)),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  /// Ghost/utility button for secondary file-operation actions.
  static ButtonStyle ghost(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: primary.withValues(alpha: 0.3)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ---------------------------------------------------------------------------
// AppTheme — ThemeData factory
// ---------------------------------------------------------------------------

/// Factory for the app's [ThemeData].
///
/// All design tokens from `docs/ui-guidelines.md` are encoded here.
/// Widgets must consume colours via [Theme.of(context).colorScheme] or
/// [AppColors] — hardcoded [Colors.*] values are not permitted in widget code
/// except for transparent / black / white used as modifiers (e.g. shadow alpha).
///
/// To add dark mode in the future, add [AppTheme.dark] mirroring the same
/// structure — no widget code will need to change.
abstract final class AppTheme {
  /// Light theme. Used as the app's default theme in [MaterialApp].
  static ThemeData light() {
    const seedColor = Color(0xFF006591);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: seedColor,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF0EA5E9),
          onPrimaryContainer: const Color(0xFF003751),
          secondary: const Color(0xFF505F76),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFD0E1FB),
          onSecondaryContainer: const Color(0xFF54647A),
          tertiary: const Color(0xFF5C5F61),
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFF999C9E),
          onTertiaryContainer: const Color(0xFF303436),
          error: const Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: const Color(0xFFFFDAD6),
          onErrorContainer: const Color(0xFF93000A),
          surface: const Color(0xFFF9F9FF),
          onSurface: const Color(0xFF111C2D),
          onSurfaceVariant: const Color(0xFF3E4850),
          outline: const Color(0xFF6E7881),
          outlineVariant: const Color(0xFFBEC8D2),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF0F3FF),
          surfaceContainer: const Color(0xFFE7EEFF),
          surfaceContainerHigh: const Color(0xFFDEE8FF),
          surfaceContainerHighest: const Color(0xFFD8E3FB),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: Typography.material2021().black.apply(fontFamily: 'Inter'),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111C2D),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Color(0xFFBEC8D2))),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0xFFBEC8D2)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFBEC8D2),
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
      ),
      extensions: const [
        AppColors(
          success: Color(0xFF059669),
          badgeLive: Color(0xFF006591),
          badgeUpcoming: Color(0xFFD0E1FB),
          badgePast: Color(0xFF999C9E),
          badgeNew: Color(0xFFBA1A1A),
          badgeLiveText: Colors.white,
          badgeUpcomingText: Color(0xFF54647A),
          badgePastText: Color(0xFF303436),
          badgeNewText: Colors.white,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BuildContext convenience extension
// ---------------------------------------------------------------------------

/// Convenience getter for [AppColors] from any [BuildContext].
extension AppColorsContext on BuildContext {
  /// Returns the [AppColors] extension from the nearest [Theme].
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
