import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/exceptions.dart';
import 'package:compman_mobile/features/competitions/data/datasources/soarscore_remote_datasource.dart';

import 'mock_dio.dart';

void main() {
  late MockDio mockDio;
  late DioSoarScoreRemoteDataSource dataSource;
  late String twoClassesHtml;
  late String noTasksHtml;

  setUpAll(() {
    twoClassesHtml = File(
      'test/fixtures/soarscore_competition.html',
    ).readAsStringSync();
    noTasksHtml = File(
      'test/fixtures/soarscore_no_tasks.html',
    ).readAsStringSync();
  });

  setUp(() {
    mockDio = MockDio();
    dataSource = DioSoarScoreRemoteDataSource(mockDio);
  });

  const tCompetitionId =
      'celje-cup-2020-drzavno-prvenstvo-slovenije-v-jadralnem-letenju';
  const tUrl = 'https://soarscore.com/competitions/$tCompetitionId/';

  void mockGet(String html, {int statusCode = 200}) {
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
        data: html,
        statusCode: statusCode,
        requestOptions: RequestOptions(path: tUrl),
      ),
    );
  }

  group('fetchLatestTasks', () {
    test('parses 2 tasks from two-classes fixture', () async {
      mockGet(twoClassesHtml);

      final result = await dataSource.fetchLatestTasks(tCompetitionId);

      expect(result, hasLength(2));

      final club = result.firstWhere((t) => t.compClass == 'Club');
      expect(club.compClass, equals('Club'));
      expect(club.dayNo, equals(6));
      expect(club.taskNo, equals(5));
      expect(club.timestamp, equals('01-07-2020 21:35:04'));
      expect(club.taskUrl, startsWith('http'));

      final open = result.firstWhere((t) => t.compClass == 'Open');
      expect(open.compClass, equals('Open'));
    });

    test('returns empty list from no-tasks fixture', () async {
      mockGet(noTasksHtml);

      final result = await dataSource.fetchLatestTasks(tCompetitionId);

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
          requestOptions: RequestOptions(path: tUrl),
          message: 'Connection refused',
        ),
      );

      expect(
        () => dataSource.fetchLatestTasks(tCompetitionId),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException on HTTP 500', () async {
      mockGet('<html></html>', statusCode: 500);

      expect(
        () => dataSource.fetchLatestTasks(tCompetitionId),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('downloadTask', () {
    const tTaskUrl =
        'http://soarscore.com/competitions/$tCompetitionId/club-task5-2020-07-01.tsk';
    final tBytes = Uint8List.fromList([0x3C, 0x3F, 0x78, 0x6D, 0x6C]);

    test('returns bytes on success', () async {
      when(
        mockDio.get<List<int>>(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: tBytes,
          statusCode: 200,
          requestOptions: RequestOptions(path: tTaskUrl),
        ),
      );

      final result = await dataSource.downloadTask(tTaskUrl);

      expect(result, equals(tBytes));
    });

    test('throws ServerException on DioException', () async {
      when(
        mockDio.get<List<int>>(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: tTaskUrl),
          message: 'timeout',
        ),
      );

      expect(
        () => dataSource.downloadTask(tTaskUrl),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
