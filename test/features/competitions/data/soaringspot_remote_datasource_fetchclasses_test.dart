import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/exceptions.dart';
import 'package:compman_mobile/features/competitions/data/datasources/soaringspot_remote_datasource.dart';

import 'mock_dio.dart';

const _classesFixtureHtml = '''
<html><body>
<table class="result-overview">
  <thead><tr><th>Standard</th><th>Club</th></tr></thead>
</table>
</body></html>
''';

const _noTableHtml = '<html><body><p>No results yet</p></body></html>';

void main() {
  late MockDio mockDio;
  late SoaringSpotRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = SoaringSpotRemoteDataSourceImpl(mockDio);
  });

  group('fetchClasses', () {
    test('parses two class names from valid fixture HTML', () async {
      when(
        mockDio.get<String>(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<String>(
          data: _classesFixtureHtml,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: 'https://www.soaringspot.com/en_gb/barron-2024/results',
          ),
        ),
      );

      final result = await dataSource.fetchClasses(
        'https://www.soaringspot.com/en_gb/barron-2024/',
      );

      expect(result, ['Standard', 'Club']);
    });

    test('returns empty list when result-overview table is absent', () async {
      when(
        mockDio.get<String>(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<String>(
          data: _noTableHtml,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: 'https://www.soaringspot.com/en_gb/barron-2024/results',
          ),
        ),
      );

      final result = await dataSource.fetchClasses(
        'https://www.soaringspot.com/en_gb/barron-2024/',
      );

      expect(result, isEmpty);
    });

    test('throws ServerException on DioException', () async {
      when(
        mockDio.get<String>(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: 'https://www.soaringspot.com/en_gb/barron-2024/results',
          ),
          message: 'Connection refused',
        ),
      );

      expect(
        () => dataSource.fetchClasses(
          'https://www.soaringspot.com/en_gb/barron-2024/',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
