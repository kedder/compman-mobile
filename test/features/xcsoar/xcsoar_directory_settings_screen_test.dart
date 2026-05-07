import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/features/xcsoar/domain/xcsoar_flavor.dart';
import 'package:compman_mobile/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mock_xcsoar_saf_service.dart';

/// Returns true when a [RichText] widget's plain text contains [substring].
bool _richTextContains(Widget w, String substring) =>
    w is RichText && w.text.toPlainText().contains(substring);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late MockXcsoarSafService _mockService;

/// Builds the screen under test with the mock SAF service injected.
///
/// [installedPackages] and [writablePackages] control the flavor state
/// returned by the mock. All packages default to not-installed / not-writable.
/// [storedUri] is what [getSafDirectoryUri] returns (null means not configured).
/// [activePackageId] is what [resolveFlavorPackageId] returns (null means no
/// known flavor matched, i.e. custom folder or not configured).
Widget _buildScreen({
  bool fromDownloadFlow = false,
  Set<String> installedPackages = const {},
  Set<String> writablePackages = const {},
  String? storedUri,
  String? activePackageId,
}) {
  when(_mockService.isPackageInstalled(any)).thenAnswer((invocation) async {
    final pkg = invocation.positionalArguments[0] as String;
    return installedPackages.contains(pkg);
  });
  when(_mockService.canWriteToMediaDir(any)).thenAnswer((invocation) async {
    final pkg = invocation.positionalArguments[0] as String;
    return writablePackages.contains(pkg);
  });
  when(_mockService.getSafDirectoryUri()).thenAnswer((_) async => storedUri);
  when(_mockService.pickDirectory()).thenAnswer((_) async => 'cancelled');
  when(_mockService.pickDirectoryForPackage(any)).thenAnswer((_) async => 'ok');
  when(
    _mockService.resolveFlavorPackageId(any, any),
  ).thenAnswer((_) async => activePackageId);

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

  testWidgets(
    'Test 7: tapping warning tile shows guidance card with flavor name and card title',
    (tester) async {
      const warningPkg = 'org.xcsoar';
      await tester.pumpWidget(_buildScreen(installedPackages: {warningPkg}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('XCSoar'));
      await tester.pump();

      expect(
        find.text("XCSoar can't be reached in its current location"),
        findsOneWidget,
      );
      expect(find.textContaining('XCSoar is installed'), findsOneWidget);
      expect(find.textContaining(warningPkg), findsWidgets);
    },
  );

  testWidgets('Test 8: guidance card contains exact numbered option headers', (
    tester,
  ) async {
    const warningPkg = 'org.xcsoar';
    await tester.pumpWidget(_buildScreen(installedPackages: {warningPkg}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('XCSoar'));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => _richTextContains(w, '1. Back up, uninstall, and reinstall'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => _richTextContains(w, "2. Clear XCSoar's app data"),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => _richTextContains(w, '3. Uninstall and reinstall'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Test 9: tapping same warning tile again collapses the guidance card',
    (tester) async {
      const warningPkg = 'org.xcsoar';
      await tester.pumpWidget(_buildScreen(installedPackages: {warningPkg}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('XCSoar'));
      await tester.pump();
      expect(
        find.text("XCSoar can't be reached in its current location"),
        findsOneWidget,
      );

      await tester.tap(find.text('XCSoar'));
      await tester.pump();
      expect(
        find.text("XCSoar can't be reached in its current location"),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Test 11: tapping ready tile while guidance card open dismisses card and opens picker',
    (tester) async {
      const warningPkg = 'org.xcsoar';
      const readyPkg = 'com.zinuzoid.xcsoar_jet';
      await tester.pumpWidget(
        _buildScreen(
          installedPackages: {warningPkg, readyPkg},
          writablePackages: {readyPkg},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('XCSoar'));
      await tester.pump();
      expect(
        find.text("XCSoar can't be reached in its current location"),
        findsOneWidget,
      );

      await tester.tap(find.text('XCSoar Jet'));
      await tester.pumpAndSettle();

      expect(
        find.text("XCSoar can't be reached in its current location"),
        findsNothing,
      );
      verify(_mockService.pickDirectoryForPackage(readyPkg)).called(1);
    },
  );

  testWidgets('status line shows Not configured when no URI is stored', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    // Appears in the status line (bodyMedium) and in the raw URI tile subtitle (bodySmall).
    expect(find.text('Not configured'), findsNWidgets(2));
  });

  testWidgets(
    'status line shows flavor display name when resolver returns a known packageId',
    (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          storedUri: 'content://any',
          activePackageId: 'org.xcsoar',
          installedPackages: {'org.xcsoar'},
          writablePackages: {'org.xcsoar'},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('XCSoar selected'), findsOneWidget);
    },
  );

  testWidgets(
    'status line shows Custom folder when resolver returns null for non-empty URI',
    (tester) async {
      await tester.pumpWidget(
        _buildScreen(storedUri: 'content://custom', activePackageId: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom folder'), findsOneWidget);
    },
  );

  testWidgets('selected flavor tile shows check_circle icon', (tester) async {
    await tester.pumpWidget(
      _buildScreen(
        storedUri: 'content://any',
        activePackageId: 'org.xcsoar',
        installedPackages: {'org.xcsoar'},
        writablePackages: {'org.xcsoar'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('unselected flavor tiles show radio_button_unchecked icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(
        storedUri: 'content://any',
        activePackageId: 'org.xcsoar',
        installedPackages: {'org.xcsoar'},
        writablePackages: {'org.xcsoar'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
  });

  testWidgets('raw URI tile appears in the ADVANCED section', (tester) async {
    await tester.pumpWidget(_buildScreen(storedUri: 'content://example'));
    await tester.pumpAndSettle();

    expect(find.text('XCSoar folder'), findsOneWidget);
    expect(find.text('content://example'), findsOneWidget);
  });

  testWidgets('no flavor tile shows check_circle when no URI is stored', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
