import 'dart:async';

import 'package:compman_mobile/app.dart';
import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('shows loading state while package info is loading', (
    tester,
  ) async {
    final completer = Completer<PackageInfo>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AboutScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows runtime app version when package info loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) => Future.value(
              PackageInfo(
                appName: 'Compman Mobile',
                packageName: 'com.example.compman_mobile',
                version: '0.1.0',
                buildNumber: '1',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Compman Mobile'), findsOneWidget);
    expect(find.text('Version: 0.1.0'), findsOneWidget);
    expect(find.text('Data provided by SoaringSpot'), findsOneWidget);
  });

  testWidgets('shows fallback message when package info load fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) async => throw Exception('failed'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version unavailable'), findsOneWidget);
  });
}
