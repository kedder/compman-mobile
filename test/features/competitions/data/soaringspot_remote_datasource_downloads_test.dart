import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/exceptions.dart';
import 'package:compman_mobile/features/competitions/data/datasources/soaringspot_remote_datasource.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';

import 'mock_dio.dart';

// Minimal fixture with the real HTML structure of div+ul contest-downloads.
const _downloadsFixtureHtml = '''
<!DOCTYPE html>
<html><body>
<h3>Airspaces</h3>
<div class="contest-downloads">
  wgc2018_airspace_v5.1.cub
  <span>Updated:</span>
  <span>10/07/2018, 17:44</span>
</div>
<ul class="contest-downloads">
  <li><a href="https://archive.soaringspot.com/contest/026/2614/airspace/11438.cub"><i class="fa fa-download"></i> wgc2018_airspace_v5.1.cub</a> (34.444 kB)</li>
  <li><a href="https://archive.soaringspot.com/contest/026/2614/airspace/11439.txt"><i class="fa fa-download"></i> wgc2018_airspace_v5.1_openair.txt</a> (134.831 kB)</li>
</ul>
<h3>Waypoints</h3>
<div class="contest-downloads">
  pz_wgc_2018_v1.2.cup
  <span>Updated:</span>
  <span>04/07/2018, 13:22</span>
</div>
<ul class="contest-downloads">
  <li><a href="https://archive.soaringspot.com/contest/026/2614/waypoint/11346.cup"><i class="fa fa-download"></i> pz_wgc_2018_v1.2.cup</a> (19.831 kB)</li>
  <li><a href="https://archive.soaringspot.com/contest/026/2614/waypoint/11349.gpx"><i class="fa fa-download"></i> pz_wgc_2018_v1.2_garmin.gpx</a> (47.991 kB)</li>
</ul>
</body></html>
''';

const _noDownloadsHtml =
    '<html><body><h2>No downloads available</h2></body></html>';

// Fixture with a relative href to verify URL prefixing.
const _relativeHrefHtml = '''
<html><body>
<div class="contest-downloads">
  <span>Updated:</span>
  <span>01/01/2026, 10:00</span>
</div>
<ul class="contest-downloads">
  <li><a href="/downloads/barron-2024/airspace.txt"><i class="fa fa-download"></i> airspace.txt</a> (10 kB)</li>
</ul>
</body></html>
''';

// Fixture without a timestamp in the div.
const _noTimestampHtml = '''
<html><body>
<div class="contest-downloads">
  some text without spans
</div>
<ul class="contest-downloads">
  <li><a href="https://example.com/waypoints.cup"><i class="fa fa-download"></i> waypoints.cup</a></li>
</ul>
</body></html>
''';

void main() {
  late MockDio mockDio;
  late SoaringSpotRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = SoaringSpotRemoteDataSourceImpl(mockDio);
  });

  Response<String> okResponse(String body, String path) => Response<String>(
    data: body,
    statusCode: 200,
    requestOptions: RequestOptions(path: path),
  );

  void stubGet(
    String body, {
    String path = 'https://www.soaringspot.com/en_gb/wgc2018pl/downloads',
  }) {
    when(
      mockDio.get<String>(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      ),
    ).thenAnswer((_) async => okResponse(body, path));
  }

  group('fetchDownloads', () {
    test(
      'parses one airspace (.txt) and one waypoints (.cup) from fixture',
      () async {
        stubGet(_downloadsFixtureHtml);

        final result = await dataSource.fetchDownloads(
          'https://www.soaringspot.com/en_gb/wgc2018pl/',
        );

        final airspace = result
            .where((f) => f.kind == DownloadableFileKind.airspace)
            .toList();
        final waypoints = result
            .where((f) => f.kind == DownloadableFileKind.waypoints)
            .toList();

        expect(airspace, hasLength(1));
        expect(airspace.first.filename, 'wgc2018_airspace_v5.1_openair.txt');
        expect(
          airspace.first.downloadUrl,
          'https://archive.soaringspot.com/contest/026/2614/airspace/11439.txt',
        );
        expect(airspace.first.publishedVersion, '10/07/2018, 17:44');

        expect(waypoints, hasLength(1));
        expect(waypoints.first.filename, 'pz_wgc_2018_v1.2.cup');
        expect(
          waypoints.first.downloadUrl,
          'https://archive.soaringspot.com/contest/026/2614/waypoint/11346.cup',
        );
        expect(waypoints.first.publishedVersion, '04/07/2018, 13:22');
      },
    );

    test('returns empty list when no ul.contest-downloads found', () async {
      stubGet(_noDownloadsHtml);

      final result = await dataSource.fetchDownloads(
        'https://www.soaringspot.com/en_gb/wgc2018pl/',
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
            path: 'https://www.soaringspot.com/en_gb/wgc2018pl/downloads',
          ),
          message: 'Connection refused',
        ),
      );

      expect(
        () => dataSource.fetchDownloads(
          'https://www.soaringspot.com/en_gb/wgc2018pl/',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('extracts publishedVersion as raw string', () async {
      stubGet(_downloadsFixtureHtml);

      final result = await dataSource.fetchDownloads(
        'https://www.soaringspot.com/en_gb/wgc2018pl/',
      );

      final txt = result.firstWhere(
        (f) => f.kind == DownloadableFileKind.airspace,
      );
      expect(txt.publishedVersion, isA<String>());
      expect(txt.publishedVersion, '10/07/2018, 17:44');
    });

    test(
      'sets publishedVersion to null when no timestamp span present',
      () async {
        stubGet(_noTimestampHtml);

        final result = await dataSource.fetchDownloads(
          'https://www.soaringspot.com/en_gb/wgc2018pl/',
        );

        expect(result, hasLength(1));
        expect(result.first.publishedVersion, isNull);
      },
    );

    test('prefixes relative href with https://www.soaringspot.com', () async {
      stubGet(_relativeHrefHtml);

      final result = await dataSource.fetchDownloads(
        'https://www.soaringspot.com/en_gb/barron-2024/',
      );

      expect(result, hasLength(1));
      expect(
        result.first.downloadUrl,
        'https://www.soaringspot.com/downloads/barron-2024/airspace.txt',
      );
    });

    test('parses real downloads fixture without throwing', () async {
      final html = File(
        'test/fixtures/soaringspot_downloads.html',
      ).readAsStringSync();
      stubGet(html);

      final result = await dataSource.fetchDownloads(
        'https://www.soaringspot.com/en_gb/wgc2018pl/',
      );

      expect(result, isNotEmpty);
      expect(result.every((f) => f.filename.isNotEmpty), isTrue);
      expect(result.every((f) => f.downloadUrl.startsWith('http')), isTrue);
    });
  });
}
