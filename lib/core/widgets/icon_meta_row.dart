import 'package:flutter/material.dart';

/// A row pairing a small icon with a single line of metadata text.
///
/// Used for URLs, timestamps, file names, and directory paths. Defaults to
/// `colorScheme.secondary` if no [color] is provided.
class IconMetaRow extends StatelessWidget {
  /// Creates an [IconMetaRow].
  const IconMetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16.0,
    this.color,
  });

  /// Icon displayed at the start of the row.
  final IconData icon;

  /// Metadata text shown next to the icon.
  final String text;

  /// Size of the leading icon.
  final double iconSize;

  /// Icon and text color. Defaults to `colorScheme.secondary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Icon(icon, size: iconSize, color: resolvedColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: resolvedColor),
          ),
        ),
      ],
    );
  }
}
