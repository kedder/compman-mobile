import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Creates and configures the [Dio] HTTP client used throughout the app.
///
/// - Base URL: `https://www.soaringspot.com`
/// - Connect timeout: 10 seconds
/// - Receive timeout: 15 seconds
/// - [LogInterceptor] added in debug mode only
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.soaringspot.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  return dio;
}
