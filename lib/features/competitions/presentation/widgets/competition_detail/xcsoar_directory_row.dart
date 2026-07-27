import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/icon_meta_row.dart';
import '../../providers/competitions_providers.dart';

/// Subdued row at the bottom of Competition Detail showing the currently
/// configured XCSoar SAF directory, or a "not configured" message.
class XcsoarDirectoryRow extends ConsumerWidget {
  /// Creates a [XcsoarDirectoryRow].
  const XcsoarDirectoryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uriAsync = ref.watch(xcsoarDirectoryUriProvider);

    return uriAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (uri) {
        final color = Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.6);
        final xcsoarPath = uri != null && uri.isNotEmpty
            ? uri
            : 'XCSoar folder not configured';

        return IconMetaRow(
          icon: Icons.folder_open,
          text: xcsoarPath,
          iconSize: 14,
          color: color,
        );
      },
    );
  }
}
