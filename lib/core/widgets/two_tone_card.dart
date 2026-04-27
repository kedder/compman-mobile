import 'package:flutter/material.dart';

/// A card with a white header region and a tinted footer region, separated by
/// a hairline divider.
///
/// Follows the card spec from `docs/ui-guidelines.md`: white background, 12 px
/// radius, 1 px `outlineVariant` border, and a small shadow.
class TwoToneCard extends StatelessWidget {
  /// Creates a [TwoToneCard].
  const TwoToneCard({super.key, required this.header, required this.footer});

  /// Widget shown in the white header area.
  final Widget header;

  /// Widget shown in the tinted footer area.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.all(12), child: header),
            const Divider(),
            ColoredBox(
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
              child: Padding(padding: const EdgeInsets.all(12), child: footer),
            ),
          ],
        ),
      ),
    );
  }
}
