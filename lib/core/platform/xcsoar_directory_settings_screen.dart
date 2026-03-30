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
            content: Text('XCSoar folder configured'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } else if (result == 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder selection cancelled')),
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
      const SnackBar(content: Text('Permission cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uriAsync = ref.watch(xcsoarDirectoryUriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('XCSoar Folder')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('XCSoar folder'),
            subtitle: uriAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Could not read folder'),
              data: (uri) => Text(
                uri != null && uri.isNotEmpty ? uri : 'Not configured',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 56,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _pickDirectory,
                      child: const Text(
                        'Change Directory',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton(
              onPressed: _clearDirectory,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Reset Permission'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Compman needs access to XCSoar\'s data folder to install task files. '
              'Tap Change Directory to open the folder picker and grant access. '
              'If XCSoar is not installed or the folder picker shows an unexpected '
              'location, tap Reset Permission and try again.',
            ),
          ),
        ],
      ),
    );
  }
}
