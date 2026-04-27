import 'package:flutter/material.dart';

/// A small coloured label badge used for status and update indicators.
///
/// All badge variants in the app are built on this widget. Colors must come
/// from the [ColorScheme] or `AppColors` — never hardcoded literals.
class AppBadge extends StatelessWidget {
  /// Creates an [AppBadge].
  const AppBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.hasRing = false,
  });

  /// The uppercase text shown inside the badge.
  final String label;

  /// Badge background color.
  final Color backgroundColor;

  /// Badge text color.
  final Color foregroundColor;

  /// When true, adds a subtle ring around the badge.
  final bool hasRing;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );

    if (!hasRing) {
      return badge;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: badge,
    );
  }
}
