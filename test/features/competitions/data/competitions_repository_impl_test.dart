import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/exceptions.dart';
import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/data/models/bookmarked_competition_model.dart';
import 'package:compman_mobile/features/competitions/data/models/competition_model.dart';
import 'package:compman_mobile/features/competitions/data/repositories/competitions_repository_impl.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition.dart';

import 'mock_datasources.dart';

void main() {
  late MockSoaringSpotRemoteDataSource mockRemote;
  late MockCompetitionsLocalDataSource mockLocal;
  late MockSoarScoreRemoteDataSource mockSoarScore;
  late CompetitionsRepositoryImpl repository;

  setUp(() {
    mockRemote = MockSoaringSpotRemoteDataSource();
    mockLocal = MockCompetitionsLocalDataSource();
    mockSoarScore = MockSoarScoreRemoteDataSource();
    repository = CompetitionsRepositoryImpl(
      remote: mockRemote,
      local: mockLocal,
      soarScore: mockSoarScore,
    );
  });

  final tCompetitionModel = CompetitionModel(
    id: 'barron-2024',
    title: 'Barron 2024',
    url: 'https://www.soaringspot.com/en_gb/barron-2024/',
    description: '1 Jan – 5 Jan 2024, Australia',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 5),
  );

  final tCompetition = Competition(
    id: 'barron-2024',
    title: 'Barron 2024',
    url: 'https://www.soaringspot.com/en_gb/barron-2024/',
    description: '1 Jan – 5 Jan 2024, Australia',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 5),
  );

  final tBookmarkedModel = BookmarkedCompetitionModel(
    id: 'barron-2024',
    title: 'Barron 2024',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/barron-2024/',
    bookmarkedAt: DateTime(2024, 1, 1),
    description: '1 Jan – 5 Jan 2024, Australia',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 5),
  );

  final tBookmarkedCompetition = BookmarkedCompetition(
    id: 'barron-2024',
    title: 'Barron 2024',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/barron-2024/',
    bookmarkedAt: DateTime(2024, 1, 1),
    description: '1 Jan – 5 Jan 2024, Australia',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 5),
  );

  group('fetchCompetitions', () {
    test('returns Right(List<Competition>) on success', () async {
      when(
        mockRemote.fetchCompetitions(),
      ).thenAnswer((_) async => [tCompetitionModel]);

      final result = await repository.fetchCompetitions();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (competitions) {
        expect(competitions, hasLength(1));
        expect(competitions.first, equals(tCompetition));
      });
    });

    test('returns Left(NetworkFailure) on ServerException', () async {
      when(
        mockRemote.fetchCompetitions(),
      ).thenThrow(const ServerException('connection refused'));

      final result = await repository.fetchCompetitions();

      expect(
        result,
        equals(
          const Left<Failure, List<Competition>>(
            NetworkFailure('connection refused'),
          ),
        ),
      );
    });

    test('returns Left(ParseFailure) on ParseException', () async {
      when(
        mockRemote.fetchCompetitions(),
      ).thenThrow(const ParseException('unexpected HTML'));

      final result = await repository.fetchCompetitions();

      expect(
        result,
        equals(
          const Left<Failure, List<Competition>>(
            ParseFailure('unexpected HTML'),
          ),
        ),
      );
    });
  });

  group('getBookmarkedCompetitions', () {
    test('returns Right(List<BookmarkedCompetition>) on success', () async {
      when(mockLocal.getAll()).thenAnswer((_) async => [tBookmarkedModel]);

      final result = await repository.getBookmarkedCompetitions();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (bookmarks) {
        expect(bookmarks, hasLength(1));
        expect(bookmarks.first, equals(tBookmarkedCompetition));
      });
    });

    test('returns Left(StorageFailure) on exception', () async {
      when(mockLocal.getAll()).thenThrow(Exception('disk full'));

      final result = await repository.getBookmarkedCompetitions();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('bookmarkCompetition', () {
    test('calls local.save and returns Right(unit) on success', () async {
      when(mockLocal.save(any)).thenAnswer((_) async {});

      final result = await repository.bookmarkCompetition(tCompetition);

      expect(result, equals(const Right<Failure, Unit>(unit)));
      verify(
        mockLocal.save(
          argThat(
            predicate<BookmarkedCompetitionModel>(
              (model) =>
                  model.id == tCompetition.id &&
                  model.title == tCompetition.title &&
                  model.soaringspotUrl == tCompetition.url &&
                  model.description == tCompetition.description &&
                  model.startDate == tCompetition.startDate &&
                  model.endDate == tCompetition.endDate,
            ),
          ),
        ),
      ).called(1);
    });

    test('returns Left(StorageFailure) on exception', () async {
      when(mockLocal.save(any)).thenThrow(Exception('write error'));

      final result = await repository.bookmarkCompetition(tCompetition);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('removeBookmark', () {
    test(
      'calls local.delete with correct id and returns Right(unit)',
      () async {
        when(mockLocal.delete(any)).thenAnswer((_) async {});

        final result = await repository.removeBookmark('barron-2024');

        expect(result, equals(const Right<Failure, Unit>(unit)));
        verify(mockLocal.delete('barron-2024')).called(1);
      },
    );

    test('returns Left(StorageFailure) on exception', () async {
      when(mockLocal.delete(any)).thenThrow(Exception('delete error'));

      final result = await repository.removeBookmark('barron-2024');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('setCompetitionClass', () {
    test('updates model with new class and returns Right(unit)', () async {
      when(
        mockLocal.getById('barron-2024'),
      ).thenAnswer((_) async => tBookmarkedModel);
      when(mockLocal.save(any)).thenAnswer((_) async {});

      final result = await repository.setCompetitionClass(
        'barron-2024',
        'Club',
      );

      expect(result, equals(const Right<Failure, Unit>(unit)));
      verify(mockLocal.getById('barron-2024')).called(1);
      verify(mockLocal.save(any)).called(1);
    });

    test('clears class when null is passed', () async {
      when(
        mockLocal.getById('barron-2024'),
      ).thenAnswer((_) async => tBookmarkedModel);
      when(mockLocal.save(any)).thenAnswer((_) async {});

      final result = await repository.setCompetitionClass('barron-2024', null);

      expect(result, equals(const Right<Failure, Unit>(unit)));
    });

    test('returns Left(StorageFailure) when competition not found', () async {
      when(mockLocal.getById('missing')).thenAnswer((_) async => null);

      final result = await repository.setCompetitionClass('missing', 'Club');

      expect(
        result,
        equals(
          const Left<Failure, Unit>(StorageFailure('Competition not found')),
        ),
      );
    });

    test('returns Left(StorageFailure) on save exception', () async {
      when(
        mockLocal.getById('barron-2024'),
      ).thenAnswer((_) async => tBookmarkedModel);
      when(mockLocal.save(any)).thenThrow(Exception('disk full'));

      final result = await repository.setCompetitionClass(
        'barron-2024',
        'Club',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('fetchCompetitionClasses', () {
    test('calls remote.fetchClasses with the correct URL', () async {
      when(mockLocal.getAll()).thenAnswer((_) async => [tBookmarkedModel]);
      when(
        mockRemote.fetchClasses(any),
      ).thenAnswer((_) async => ['Standard', 'Club']);

      final result = await repository.fetchCompetitionClasses('barron-2024');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (classes) => expect(classes, ['Standard', 'Club']),
      );
      verify(
        mockRemote.fetchClasses(
          'https://www.soaringspot.com/en_gb/barron-2024/',
        ),
      );
    });

    test('returns Right([]) when competition ID is not bookmarked', () async {
      when(mockLocal.getAll()).thenAnswer((_) async => []);

      final result = await repository.fetchCompetitionClasses('unknown-id');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (classes) => expect(classes, isEmpty),
      );
      verifyNever(mockRemote.fetchClasses(any));
    });
  });
}
