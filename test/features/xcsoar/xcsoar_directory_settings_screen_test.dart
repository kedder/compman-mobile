import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/features/xcsoar/domain/xcsoar_flavor.dart';
import 'package:compman_mobile/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mock_xcsoar_saf_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late MockXcsoarSafService _mockService;

/// Builds the screen under test with the mock SAF service injected.
///
/// [installedPackages] and [writablePackages] control the flavor state
/// returned by the mock. All packages default to not-installed / not-writable.
Widget _buildScreen({
  bool fromDownloadFlow = false,
  Set<String> installedPackages = const {},
  Set<String> writablePackages = const {},
}) {
  when(_mockService.isPackageInstalled(any)).thenAnswer((invocation) async {
    final pkg = invocation.positionalArguments[0] as String;
    return installedPackages.contains(pkg);
  });
  when(_mockService.canWriteToMediaDir(any)).thenAnswer((invocation) async {
    final pkg = invocation.positionalArguments[0] as String;
    return writablePackages.contains(pkg);
  });
  when(_mockService.getSafDirectoryUri()).thenAnswer((_) async => null);
  when(_mockService.pickDirectory()).thenAnswer((_) async => 'cancelled');
  when(_mockService.pickDirectoryForPackage(any)).thenAnswer((_) async => 'ok');

  return ProviderScope(
    overrides: [xcsoarSafServiceProvider.overrideWithValue(_mockService)],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: XcsoarDirectorySettingsScreen(fromDownloadFlow: fromDownloadFlow),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    _mockService = MockXcsoarSafService();
  });

  testWidgets('all flavors show Not installed badge when none are installed', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    for (final flavor in kKnownXcsoarFlavors) {
      expect(find.text(flavor.displayName), findsOneWidget);
    }
    // AppBadge uppercases the label
    expect(find.text('NOT INSTALLED'), findsNWidgets(4));
  });

  testWidgets(
    'ready flavor shows Ready badge and tap calls pickDirectoryForPackage',
    (tester) async {
      const readyPkg = 'org.xcsoar';
      await tester.pumpWidget(
        _buildScreen(
          installedPackages: {readyPkg},
          writablePackages: {readyPkg},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('READY'), findsOneWidget);

      await tester.tap(find.text('XCSoar'));
      await tester.pumpAndSettle();

      verify(_mockService.pickDirectoryForPackage(readyPkg)).called(1);
    },
  );

  testWidgets(
    'warning flavor tap does not call pickDirectoryForPackage and marks tile selected',
    (tester) async {
      const warningPkg = 'org.xcsoar';
      await tester.pumpWidget(_buildScreen(installedPackages: {warningPkg}));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS SETUP'), findsOneWidget);

      await tester.tap(find.text('XCSoar'));
      await tester.pump();

      verifyNever(_mockService.pickDirectoryForPackage(any));
      // The tapped tile should now be selected
      expect(
        find.byWidgetPredicate((w) => w is ListTile && w.selected),
        findsOneWidget,
      );
    },
  );

  testWidgets('Advanced row is visible and calls pickDirectory on tap', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Choose custom folder'), findsOneWidget);

    await tester.tap(find.text('Choose custom folder'));
    await tester.pumpAndSettle();

    verify(_mockService.pickDirectory()).called(1);
  });

  testWidgets(
    'fromDownloadFlow true renders Set Up XCSoar Folder app bar title',
    (tester) async {
      await tester.pumpWidget(_buildScreen(fromDownloadFlow: true));
      await tester.pumpAndSettle();

      expect(find.text('Set Up XCSoar Folder'), findsOneWidget);
    },
  );

  testWidgets('fromDownloadFlow false renders XCSoar Folder app bar title', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('XCSoar Folder'), findsOneWidget);
  });
}
