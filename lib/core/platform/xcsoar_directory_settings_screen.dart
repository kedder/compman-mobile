import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/competitions/presentation/providers/competitions_providers.dart';
import 'xcsoar_saf_service.dart';

/// Settings screen for configuring the XCSoar data directory via SAF.
///
/// Displays the current configured directory URI and lets the user
/// launch the Android folder picker to grant or change access.
class XcsoarDirectorySettingsScreen extends ConsumerStatefulWidget {
  /// Creates the [XcsoarDirectorySettingsScreen].
  const XcsoarDirectorySettingsScreen({super.key});

  @override
  ConsumerState<XcsoarDirectorySettingsScreen> createState() =>
      _XcsoarDirectorySettingsScreenState();
}

class _XcsoarDirectorySettingsScreenState
    extends ConsumerState<XcsoarDirectorySettingsScreen> {
  bool _loading = false;

  Future<void> _pickDirectory() async {
    setState(() => _loading = true);
    try {
      final result = await XcsoarSafService().tryWriteHelloFile();
      if (!mounted) return;
      if (result == 'ok') {
        ref.invalidate(xcsoarDirectoryUriProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('XCSoar folder configured successfully'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not configure folder'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearDirectory() async {
    await XcsoarSafService().clearSafPermission();
    if (!mounted) return;
    ref.invalidate(xcsoarDirectoryUriProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('XCSoar folder cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uriAsync = ref.watch(xcsoarDirectoryUriProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('XCSoar Directory')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('XCSoar data folder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            uriAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text('Could not read folder',
                  style: theme.textTheme.bodyMedium),
              data: (uri) => Text(
                uri != null && uri.isNotEmpty ? uri : 'Not configured',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _pickDirectory,
                      child: const Text(
                        'Choose XCSoar Folder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            uriAsync.maybeWhen(
              data: (uri) => uri != null && uri.isNotEmpty
                  ? TextButton(
                      onPressed: _clearDirectory,
                      child: Text(
                        'Clear configured folder',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
