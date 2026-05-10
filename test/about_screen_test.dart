import 'dart:async';

import 'package:compman_mobile/app.dart';
import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

final _fakeInfo = PackageInfo(
  appName: 'Compman Mobile',
  packageName: 'com.example.compman_mobile',
  version: '1.0.0',
  buildNumber: '1',
);

Widget _buildScreen({required AsyncValue<PackageInfo> override}) {
  return ProviderScope(
    overrides: [
      packageInfoProvider.overrideWith((ref) {
        switch (override) {
          case AsyncData(:final value):
            return Future.value(value);
          case AsyncError(:final error):
            return Future.error(error);
          case AsyncLoading():
            return Completer<PackageInfo>().future;
        }
      }),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const AboutScreen()),
  );
}

void main() {
  testWidgets('renders identity block', (tester) async {
    await tester.pumpWidget(_buildScreen(override: AsyncData(_fakeInfo)));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/icon/app_icon.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Competition Manager'), findsOneWidget);
    expect(
      find.textContaining('An Android app for glider pilots'),
      findsOneWidget,
    );
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });

  testWidgets('renders author row', (tester) async {
    await tester.pumpWidget(_buildScreen(override: AsyncData(_fakeInfo)));
    await tester.pump();

    expect(find.text('Written by Andrey Lebedev'), findsOneWidget);
  });

  testWidgets('renders source code row with open_in_new icon', (tester) async {
    await tester.pumpWidget(_buildScreen(override: AsyncData(_fakeInfo)));
    await tester.pump();

    expect(find.text('Source & bug reports'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.open_in_new),
      findsWidgets,
    );
  });

  testWidgets('renders data source rows', (tester) async {
    await tester.pumpWidget(_buildScreen(override: AsyncData(_fakeInfo)));
    await tester.pump();

    expect(find.text('Competition data'), findsOneWidget);
    expect(find.text('XCSoar tasks'), findsOneWidget);
  });

  testWidgets('shows loading state and hides identity block', (tester) async {
    await tester.pumpWidget(_buildScreen(override: const AsyncLoading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Competition Manager Mobile'), findsNothing);
  });
}
