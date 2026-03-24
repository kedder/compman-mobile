import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Entry point. Wraps the app in a [ProviderScope] to enable Riverpod throughout.
void main() {
  runApp(const ProviderScope(child: CompmanApp()));
}
