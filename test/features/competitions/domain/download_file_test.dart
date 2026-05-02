import 'dart:typed_data';

import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late DownloadFile useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = DownloadFile(mockRepository);
    provideDummy<Either<Failure, Uint8List>>(Right(Uint8List(0)));
  });

  const tFileUrl =
      'https://archive.soaringspot.com/contest/026/2614/airspace/11439.txt';
  final tBytes = Uint8List.fromList([0x47, 0x52, 0x49, 0x44]);

  test('delegates to repository.downloadFile and returns bytes', () async {
    when(
      mockRepository.downloadFile(tFileUrl),
    ).thenAnswer((_) async => Right(tBytes));

    final result = await useCase(tFileUrl);

    expect(result, Right(tBytes));
    verify(mockRepository.downloadFile(tFileUrl));
    verifyNoMoreInteractions(mockRepository);
  });

  test('propagates Left as-is', () async {
    const failure = Failure.network('download failed');
    when(
      mockRepository.downloadFile(tFileUrl),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(tFileUrl);

    expect(result, const Left(failure));
    verify(mockRepository.downloadFile(tFileUrl));
    verifyNoMoreInteractions(mockRepository);
  });
}
