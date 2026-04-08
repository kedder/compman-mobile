import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'xcsoar_saf_service.dart';

/// Screen for testing SAF-based file delivery to XCSoar's data folder.
///
/// Invokes [XcsoarSafService.tryWriteHelloFile] when the user taps the
/// action button. Shows a progress indicator while the operation is running,
/// and a [SnackBar] when it completes or fails.
class SafTestScreen extends ConsumerStatefulWidget {
  /// Creates the [SafTestScreen].
  const SafTestScreen({super.key});

  @override
  ConsumerState<SafTestScreen> createState() => _SafTestScreenState();
}

class _SafTestScreenState extends ConsumerState<SafTestScreen> {
  bool _loading = false;

  Future<void> _writeFile() async {
    setState(() => _loading = true);
    try {
      final result = await XcsoarSafService().tryWriteHelloFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: context.appColors.success,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unknown error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try SAF')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Writes hello-from-compman.txt into XCSoar's data folder."),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _writeFile,
                child: const Text('Write file to XCSoar'),
              ),
          ],
        ),
      ),
    );
  }
}
