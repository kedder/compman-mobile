import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../competitions/presentation/providers/competitions_providers.dart';
import '../../domain/xcsoar_flavor.dart';

/// Tracks the installation and writability state of a single XCSoar flavor.
enum _FlavorState {
  /// XCSoar is installed and its media directory is writable.
  ready,

  /// XCSoar is installed but its directory is not writable (e.g. uses Android/data).
  warning,

  /// XCSoar is not installed on this device.
  notInstalled;

  /// Sort order: ready tiles first, not-installed tiles last.
  int get order => switch (this) {
    _FlavorState.ready => 0,
    _FlavorState.warning => 1,
    _FlavorState.notInstalled => 2,
  };
}

/// Settings screen for configuring the XCSoar data directory via SAF.
///
/// Shows a flavor-picker list of known XCSoar variants with per-flavor
/// writability badges. Tapping a ready flavor opens the SAF folder picker
/// pre-navigated to that flavor's media directory.
class XcsoarDirectorySettingsScreen extends ConsumerStatefulWidget {
  /// Creates the [XcsoarDirectorySettingsScreen].
  ///
  /// Set [fromDownloadFlow] to `true` when navigating here from a pending
  /// download so the AppBar title reflects the contextual action.
  const XcsoarDirectorySettingsScreen({
    super.key,
    this.fromDownloadFlow = false,
  });

  /// When true, the AppBar title reads "Set Up XCSoar Folder" instead of
  /// "XCSoar Folder".
  final bool fromDownloadFlow;

  @override
  ConsumerState<XcsoarDirectorySettingsScreen> createState() =>
      _XcsoarDirectorySettingsScreenState();
}

class _XcsoarDirectorySettingsScreenState
    extends ConsumerState<XcsoarDirectorySettingsScreen> {
  /// True while the initial per-flavor state is being loaded.
  bool _loading = true;

  /// True while the SAF folder picker is active (Advanced row).
  bool _pickerLoading = false;

  /// Installation and writability state keyed by [XcsoarFlavor.packageId].
  Map<String, _FlavorState> _flavorStates = {};

  /// Package ID of the currently selected warning-state tile, or null.
  String? _selectedBlockedPackage;

  /// Active flavor resolved from the stored URI; null until loaded or if unrecognised.
  XcsoarFlavor? _activeFlavor;

  @override
  void initState() {
    super.initState();
    _loadFlavorStates();
    _resolveActiveFlavor();
  }

  /// Resolves [_activeFlavor] by comparing the stored SAF URI against each known
  /// flavor's canonical media-directory tree URI via the Kotlin bridge.
  Future<void> _resolveActiveFlavor() async {
    final uri = await ref.read(xcsoarDirectoryUriProvider.future);
    if (uri == null || uri.isEmpty) {
      if (mounted) setState(() => _activeFlavor = null);
      return;
    }
    final packageId = await ref
        .read(xcsoarSafServiceProvider)
        .resolveFlavorPackageId(
          uri,
          kKnownXcsoarFlavors.map((f) => f.packageId).toList(),
        );
    if (mounted) {
      setState(() {
        _activeFlavor = packageId == null
            ? null
            : kKnownXcsoarFlavors.firstWhereOrNull(
                (f) => f.packageId == packageId,
              );
      });
    }
  }

  Future<void> _loadFlavorStates() async {
    final service = ref.read(xcsoarSafServiceProvider);

    // Check all installations in parallel, then all writable checks in parallel.
    final installed = await Future.wait(
      kKnownXcsoarFlavors.map((f) => service.isPackageInstalled(f.packageId)),
    );
    final writable = await Future.wait(
      List.generate(
        kKnownXcsoarFlavors.length,
        (i) => installed[i]
            ? service.canWriteToMediaDir(kKnownXcsoarFlavors[i].packageId)
            : Future.value(false),
      ),
    );

    if (!mounted) return;
    final states = <String, _FlavorState>{
      for (var i = 0; i < kKnownXcsoarFlavors.length; i++)
        kKnownXcsoarFlavors[i].packageId: !installed[i]
            ? _FlavorState.notInstalled
            : writable[i]
            ? _FlavorState.ready
            : _FlavorState.warning,
    };
    setState(() {
      _flavorStates = states;
      _loading = false;
    });
  }

  List<XcsoarFlavor> get _sortedFlavors {
    return List<XcsoarFlavor>.from(kKnownXcsoarFlavors)..sort(
      (a, b) => (_flavorStates[a.packageId] ?? _FlavorState.notInstalled).order
          .compareTo(
            (_flavorStates[b.packageId] ?? _FlavorState.notInstalled).order,
          ),
    );
  }

  void _showPickerSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('XCSoar folder configured'),
        backgroundColor: context.appColors.success,
      ),
    );
  }

  void _showPickerError(PlatformException error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message ?? 'Could not configure folder'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickDirectory() async {
    setState(() => _pickerLoading = true);
    try {
      final result = await ref.read(xcsoarSafServiceProvider).pickDirectory();
      if (!mounted) return;
      if (result == 'ok') {
        ref.invalidate(xcsoarDirectoryUriProvider);
        _resolveActiveFlavor();
        if (widget.fromDownloadFlow) {
          context.pop();
        } else {
          _showPickerSuccess();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder selection cancelled')),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPickerError(e);
    } finally {
      if (mounted) setState(() => _pickerLoading = false);
    }
  }

  Future<void> _clearDirectory() async {
    await ref.read(xcsoarSafServiceProvider).clearSafPermission();
    if (!mounted) return;
    ref.invalidate(xcsoarDirectoryUriProvider);
    _resolveActiveFlavor();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Permission cleared')));
  }

  Future<void> _pickDirectoryForPackage(XcsoarFlavor flavor) async {
    setState(() => _selectedBlockedPackage = null);
    try {
      final result = await ref
          .read(xcsoarSafServiceProvider)
          .pickDirectoryForPackage(flavor.packageId);
      if (!mounted) return;
      if (result == 'ok') {
        ref.invalidate(xcsoarDirectoryUriProvider);
        _resolveActiveFlavor();
        if (widget.fromDownloadFlow) {
          context.pop();
        } else {
          _showPickerSuccess();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder selection cancelled')),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPickerError(e);
    }
  }

  bool _isGuidanceCardVisible(XcsoarFlavor flavor) =>
      _selectedBlockedPackage == flavor.packageId &&
      _flavorStates[flavor.packageId] == _FlavorState.warning;

  Widget _buildFlavorTile(XcsoarFlavor flavor) {
    final state = _flavorStates[flavor.packageId] ?? _FlavorState.notInstalled;
    return _FlavorTile(
      flavor: flavor,
      state: state,
      isSelected: _selectedBlockedPackage == flavor.packageId,
      isActiveFlavor: _activeFlavor?.packageId == flavor.packageId,
      onTap: switch (state) {
        _FlavorState.ready => () => _pickDirectoryForPackage(flavor),
        _FlavorState.warning => () => setState(() {
          _selectedBlockedPackage = _selectedBlockedPackage == flavor.packageId
              ? null
              : flavor.packageId;
        }),
        _FlavorState.notInstalled => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uriAsync = ref.watch(xcsoarDirectoryUriProvider);
    final theme = Theme.of(context);

    final statusText = _activeFlavor != null
        ? '${_activeFlavor!.displayName} selected'
        : (uriAsync.value?.isNotEmpty == true
              ? 'Custom folder'
              : 'Not configured');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fromDownloadFlow ? 'Set Up XCSoar Folder' : 'XCSoar Folder',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const _SectionLabel('XCSOAR APP'),
                for (final flavor in _sortedFlavors) ...[
                  _buildFlavorTile(flavor),
                  if (_isGuidanceCardVisible(flavor))
                    _BlockedFlavorGuidanceCard(flavor: flavor),
                ],
                const Divider(),
                const _SectionLabel('ADVANCED'),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('XCSoar folder'),
                  subtitle: uriAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Could not read folder'),
                    data: (uri) => Text(
                      uri != null && uri.isNotEmpty ? uri : 'Not configured',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Choose custom folder'),
                  subtitle: const Text('Use any folder on your device'),
                  trailing: _pickerLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _pickerLoading ? null : _pickDirectory,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: OutlinedButton(
                    onPressed: _clearDirectory,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Reset Permission'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Compman needs access to XCSoar\'s data folder to install task files. '
                    'Select your XCSoar variant above to open the folder picker. '
                    'If XCSoar is not installed or the folder picker shows an unexpected '
                    'location, tap Reset Permission and try again.',
                  ),
                ),
              ],
            ),
    );
  }
}

/// A list tile representing a single XCSoar flavor with its installation badge.
class _FlavorTile extends StatelessWidget {
  const _FlavorTile({
    required this.flavor,
    required this.state,
    required this.isSelected,
    required this.isActiveFlavor,
    required this.onTap,
  });

  final XcsoarFlavor flavor;
  final _FlavorState state;

  /// True when the user tapped a warning-state tile to reveal the recovery
  /// guidance card. Controls the [ListTile.selected] background tint.
  final bool isSelected;

  /// True when this flavor's canonical media-directory tree URI matches the
  /// currently stored SAF URI, i.e. this is the active flavor.
  final bool isActiveFlavor;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;

    final (badgeBg, badgeFg, badgeLabel) = switch (state) {
      _FlavorState.ready => (
        appColors.badgeLive,
        appColors.badgeLiveText,
        'Ready',
      ),
      _FlavorState.warning => (
        theme.colorScheme.error,
        theme.colorScheme.onError,
        'Needs setup',
      ),
      _FlavorState.notInstalled => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        'Not installed',
      ),
    };

    return ListTile(
      leading: Icon(
        isActiveFlavor ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isActiveFlavor
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      title: Text(flavor.displayName),
      subtitle: Text(
        flavor.packageId,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.secondary,
        ),
      ),
      trailing: AppBadge(
        label: badgeLabel,
        backgroundColor: badgeBg,
        foregroundColor: badgeFg,
      ),
      enabled: state != _FlavorState.notInstalled,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

/// An all-caps section label with standard list padding.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Inline recovery guidance shown below a warning-state XCSoar flavor tile.
///
/// Non-dismissible. Lists three numbered options for moving XCSoar out of
/// the restricted `Android/data` path so Compman can write files to it.
class _BlockedFlavorGuidanceCard extends StatelessWidget {
  /// Creates a [_BlockedFlavorGuidanceCard] for [flavor].
  const _BlockedFlavorGuidanceCard({required this.flavor});

  /// The warning-state XCSoar flavor this card describes.
  final XcsoarFlavor flavor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final flavorName = flavor.displayName;
    final packageId = flavor.packageId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "XCSoar can't be reached in its current location",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '$flavorName is installed, but it\'s storing its files in a folder '
              'that Android no longer allows other apps to access (Android/data). '
              'This happens with older XCSoar installations — XCSoar automatically '
              'keeps using the original folder as long as files are found there, '
              'and there\'s no option inside XCSoar to change this.',
              style: body,
            ),
            const SizedBox(height: 12),
            Text(
              'To use Compman with $flavorName, you\'ll need to free it from that folder:',
              style: body,
            ),
            const SizedBox(height: 12),
            _buildOptionHeader(
              context,
              '1. Back up, uninstall, and reinstall',
              'preserves files if backed up',
            ),
            Text(
              'Copy your XCSoarData folder from Android/data/$packageId/files/ '
              'somewhere safe first. Then uninstall $flavorName — this deletes '
              'Android/data/$packageId — reinstall, and restore your backup.',
              style: body,
            ),
            const SizedBox(height: 12),
            _buildOptionHeader(
              context,
              "2. Clear XCSoar's app data",
              'settings and data lost',
            ),
            Text(
              'Settings → Apps → $flavorName → Storage & Cache → Clear Storage. '
              'XCSoar will create a new accessible folder on next launch. '
              'Warning: all profiles, settings, and logbook entries are permanently deleted.',
              style: body,
            ),
            const SizedBox(height: 12),
            _buildOptionHeader(
              context,
              '3. Uninstall and reinstall',
              'simplest, data lost',
            ),
            Text(
              'Uninstall and reinstall $flavorName. '
              'Warning: all settings and data are permanently deleted.',
              style: body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionHeader(BuildContext context, String header, String risk) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: header,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: ' ($risk)',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
