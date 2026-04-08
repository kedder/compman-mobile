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
    required this.badgeOnDark,
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
  ///
  /// Note: the foreground text for [badgeNew] badges must be `Colors.black`
  /// (not [badgeOnDark]) because the yellow background does not provide
  /// sufficient contrast against white text (WCAG AA).
  final Color badgeNew;

  /// Foreground text colour for Live, Upcoming, and Past status badges.
  ///
  /// Always white — these dark badge backgrounds provide sufficient contrast
  /// against white text. For the New badge, use `Colors.black` directly.
  final Color badgeOnDark;

  @override
  AppColors copyWith({
    Color? success,
    Color? badgeLive,
    Color? badgeUpcoming,
    Color? badgePast,
    Color? badgeNew,
    Color? badgeOnDark,
  }) {
    return AppColors(
      success: success ?? this.success,
      badgeLive: badgeLive ?? this.badgeLive,
      badgeUpcoming: badgeUpcoming ?? this.badgeUpcoming,
      badgePast: badgePast ?? this.badgePast,
      badgeNew: badgeNew ?? this.badgeNew,
      badgeOnDark: badgeOnDark ?? this.badgeOnDark,
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
      badgeOnDark: Color.lerp(badgeOnDark, other.badgeOnDark, t)!,
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
    // Material 3 generates a full ColorScheme from the seed; primary will be
    // derived from the seed colour but may differ slightly. The seed is the
    // canonical aviation-sky-blue brand colour.
    const seedColor = Color(0xFF0D7FC1);

    // Material 3 default text styles enforce a minimum body size of ~14 sp.
    // With useMaterial3: true the default bodyMedium is 14 sp and bodyLarge
    // is 16 sp. The ui-guidelines require body text at least 16 sp — screens
    // must use bodyLarge (or larger) for primary body content and labelLarge
    // for button labels (already 14 sp bold in M3, overridden below to 16 sp).
    return ThemeData(
      colorSchemeSeed: seedColor,
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
      extensions: const [
        AppColors(
          success: Color(0xFF2E7D32),
          badgeLive: Color(0xFF2E7D32),
          badgeUpcoming: Color(0xFF1565C0),
          badgePast: Color(0xFF757575),
          badgeNew: Color(0xFFF9A825),
          badgeOnDark: Colors.white,
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
