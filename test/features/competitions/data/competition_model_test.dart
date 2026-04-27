import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:compman_mobile/features/competitions/data/models/competition_model.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition_status.dart';

void main() {
  late String fixtureHtml;
  late Document document;

  setUpAll(() {
    fixtureHtml = File(
      'test/fixtures/soaringspot_home.html',
    ).readAsStringSync();
    document = html_parser.parse(fixtureHtml);
  });

  group('CompetitionModel.fromElement', () {
    test('returns non-null model from first .contest element', () {
      final element = document.querySelector('.contest')!;
      final model = CompetitionModel.fromElement(element);
      expect(model, isNotNull);
    });

    test('id is non-empty and contains no slashes or spaces', () {
      final element = document.querySelector('.contest')!;
      final model = CompetitionModel.fromElement(element)!;
      expect(model.id, isNotEmpty);
      expect(model.id, isNot(contains('/')));
      expect(model.id, isNot(contains(' ')));
    });

    test('title is non-empty', () {
      final element = document.querySelector('.contest')!;
      final model = CompetitionModel.fromElement(element)!;
      expect(model.title, isNotEmpty);
    });

    test('url starts with https://www.soaringspot.com', () {
      final element = document.querySelector('.contest')!;
      final model = CompetitionModel.fromElement(element)!;
      expect(model.url, startsWith('https://www.soaringspot.com'));
    });

    test(
      'description has no leading/trailing whitespace or consecutive spaces',
      () {
        final element = document.querySelector('.contest')!;
        final model = CompetitionModel.fromElement(element)!;
        expect(model.description, equals(model.description.trim()));
        expect(model.description, isNot(contains('  ')));
      },
    );

    test('parses startDate and endDate from the listing info text', () {
      final element = document.querySelector('.contest')!;
      final model = CompetitionModel.fromElement(element)!;

      expect(model.startDate, DateTime(2026, 3, 21));
      expect(model.endDate, DateTime(2026, 3, 24));
    });

    test('returns null for malformed element with no <h3><a>', () {
      final malformed = Element.html(
        '<div class="contest"><p>No anchor</p></div>',
      );
      final result = CompetitionModel.fromElement(malformed);
      expect(result, isNull);
    });
  });

  group('CompetitionModel.toEntity', () {
    test('returns Competition with matching fields', () {
      final element = document.querySelector('.contest')!;
      final model = CompetitionModel.fromElement(element)!;
      final entity = model.toEntity();
      expect(entity, isA<Competition>());
      expect(entity.id, equals(model.id));
      expect(entity.title, equals(model.title));
      expect(entity.url, equals(model.url));
      expect(entity.description, equals(model.description));
      expect(entity.startDate, equals(model.startDate));
      expect(entity.endDate, equals(model.endDate));
    });

    test('competition status is computed from parsed dates', () {
      final element = document.querySelector('.contest')!;
      final entity = CompetitionModel.fromElement(element)!.toEntity();

      expect(
        CompetitionStatus.of(
          startDate: entity.startDate,
          endDate: entity.endDate,
          now: DateTime(2026, 3, 22),
        ),
        CompetitionStatus.live,
      );
      expect(
        CompetitionStatus.of(
          startDate: entity.startDate,
          endDate: entity.endDate,
          now: DateTime(2026, 3, 20),
        ),
        CompetitionStatus.upcoming,
      );
      expect(
        CompetitionStatus.of(
          startDate: entity.startDate,
          endDate: entity.endDate,
          now: DateTime(2026, 3, 25),
        ),
        CompetitionStatus.past,
      );
    });
  });
}
