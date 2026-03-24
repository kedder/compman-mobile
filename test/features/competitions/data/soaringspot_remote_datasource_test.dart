import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/exceptions.dart';
import 'package:compman_mobile/features/competitions/data/datasources/soaringspot_remote_datasource.dart';

import 'mock_dio.dart';

void main() {
  late MockDio mockDio;
  late SoaringSpotRemoteDataSourceImpl dataSource;
  late String fixtureHtml;

  setUpAll(() {
    fixtureHtml =
        File('test/fixtures/soaringspot_home.html').readAsStringSync();
  });

  setUp(() {
    mockDio = MockDio();
    dataSource = SoaringSpotRemoteDataSourceImpl(mockDio);
  });

  group('fetchCompetitions', () {
    test('returns non-empty list when response contains .contest elements',
        () async {
      when(mockDio.get<String>(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer(
        (_) async => Response<String>(
          data: fixtureHtml,
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://www.soaringspot.com'),
        ),
      );

      final result = await dataSource.fetchCompetitions();

      expect(result, isNotEmpty);
      for (final model in result) {
        expect(model.id, isNotEmpty);
        expect(model.title, isNotEmpty);
        expect(model.url, startsWith('https://www.soaringspot.com'));
      }
    });

    // Snapshot test — update manually when refreshing test/fixtures/soaringspot_home.html.
    test(
        'snapshot: fixture contains 24 competitions and last entry matches known values',
        () async {
      when(mockDio.get<String>(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer(
        (_) async => Response<String>(
          data: fixtureHtml,
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://www.soaringspot.com'),
        ),
      );

      final result = await dataSource.fetchCompetitions();

      expect(result, hasLength(24));

      final last = result.last;
      expect(last.id, 'kitzbuhler-alpen-pokal-2026');
      expect(last.title, 'Kitzbühler-Alpen-Pokal 2026');
      expect(last.url,
          'https://www.soaringspot.com/en_gb/kitzbuhler-alpen-pokal-2026/');
      expect(
        last.description,
        'St. Johann In Tirol, Austria, 1 May 2026 – 9 May 2026 45 competitors in 2 classes',
      );
    });

    test('throws ServerException on DioException', () async {
      when(mockDio.get<String>(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'https://www.soaringspot.com'),
          message: 'Connection refused',
        ),
      );

      expect(
        () => dataSource.fetchCompetitions(),
        throwsA(isA<ServerException>()),
      );
    });

    test('returns empty list when page has no .contest elements', () async {
      const minimalHtml =
          '<html><body><div class="other">No competitions here</div></body></html>';

      when(mockDio.get<String>(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer(
        (_) async => Response<String>(
          data: minimalHtml,
          statusCode: 200,
          requestOptions: RequestOptions(path: 'https://www.soaringspot.com'),
        ),
      );

      final result = await dataSource.fetchCompetitions();

      expect(result, isEmpty);
    });
  });
}
