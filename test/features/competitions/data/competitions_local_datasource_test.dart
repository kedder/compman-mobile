import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:compman_mobile/features/competitions/data/datasources/competitions_local_datasource.dart';
import 'package:compman_mobile/features/competitions/data/models/bookmarked_competition_model.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';

void main() {
  late Directory tempDir;
  late Box<BookmarkedCompetitionModel> box;
  late HiveCompetitionsLocalDataSource dataSource;

  final tModel = BookmarkedCompetitionModel(
    id: 'barron-2024',
    title: 'Barron 2024',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/barron-2024/',
    bookmarkedAt: DateTime(2024, 1, 1),
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(BookmarkedCompetitionModelAdapter());
  });

  setUp(() async {
    box = await Hive.openBox<BookmarkedCompetitionModel>('bookmarks');
    dataSource = HiveCompetitionsLocalDataSource(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('bookmarks');
    await tempDir.delete(recursive: true);
  });

  group('getAll', () {
    test('returns empty list when box is empty', () async {
      final result = await dataSource.getAll();
      expect(result, isEmpty);
    });

    test('returns all saved models', () async {
      await box.put(tModel.id, tModel);

      final result = await dataSource.getAll();

      expect(result, hasLength(1));
      expect(result.first.id, tModel.id);
      expect(result.first.title, tModel.title);
    });
  });

  group('save', () {
    test('persists model so that getAll returns it', () async {
      await dataSource.save(tModel);

      final result = await dataSource.getAll();

      expect(result, hasLength(1));
      expect(result.first.id, tModel.id);
      expect(result.first.soaringspotUrl, tModel.soaringspotUrl);
    });

    test('overwrites existing entry with same id', () async {
      await dataSource.save(tModel);

      final updated = BookmarkedCompetitionModel(
        id: tModel.id,
        title: 'Updated Title',
        soaringspotUrl: tModel.soaringspotUrl,
        bookmarkedAt: tModel.bookmarkedAt,
      );
      await dataSource.save(updated);

      final result = await dataSource.getAll();
      expect(result, hasLength(1));
      expect(result.first.title, 'Updated Title');
    });
  });

  group('delete', () {
    test('removes model by id', () async {
      await dataSource.save(tModel);
      await dataSource.delete(tModel.id);

      final result = await dataSource.getAll();
      expect(result, isEmpty);
    });

    test('is a no-op when id does not exist', () async {
      await dataSource.save(tModel);
      await dataSource.delete('nonexistent-id');

      final result = await dataSource.getAll();
      expect(result, hasLength(1));
    });
  });

  group('BookmarkedCompetitionModel.toEntity', () {
    test('returns a correct BookmarkedCompetition', () {
      final entity = tModel.toEntity();

      expect(entity, isA<BookmarkedCompetition>());
      expect(entity.id, tModel.id);
      expect(entity.title, tModel.title);
      expect(entity.soaringspotUrl, tModel.soaringspotUrl);
      expect(entity.bookmarkedAt, tModel.bookmarkedAt);
    });
  });

  group('BookmarkedCompetitionModel.fromEntity', () {
    test('creates model that round-trips back to an equal entity', () {
      final entity = BookmarkedCompetition(
        id: 'test-id',
        title: 'Test Competition',
        soaringspotUrl: 'https://www.soaringspot.com/en_gb/test-id/',
        bookmarkedAt: DateTime(2025, 6, 15),
      );

      final model = BookmarkedCompetitionModel.fromEntity(entity);
      final roundTripped = model.toEntity();

      expect(roundTripped, entity);
    });
  });
}
