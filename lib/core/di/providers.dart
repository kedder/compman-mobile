import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/http_client.dart';

/// Provides the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) => createDioClient());

/// Provides the Hive [Box] used to persist bookmarked competitions.
///
/// Initialises Hive if it has not been initialised yet, then opens the box.
final bookmarksBoxProvider = FutureProvider<Box>((ref) async {
  await Hive.initFlutter();
  return Hive.openBox('bookmarks');
});
