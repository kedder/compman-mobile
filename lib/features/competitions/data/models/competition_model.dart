import 'package:html/dom.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/competition.dart';

/// Data model for a competition parsed from SoaringSpot HTML.
///
/// Use [fromElement] to construct from a `.contest` DOM element, and
/// [toEntity] to convert to the domain [Competition] type.
class CompetitionModel {
  /// URL slug used as a stable identifier, e.g. `"barron-2024"`.
  final String id;

  /// Human-readable competition name.
  final String title;

  /// Full SoaringSpot URL for this competition page.
  final String url;

  /// Dates and location as a human-readable string.
  final String description;

  /// Competition start date parsed from the listing, if available.
  final DateTime? startDate;

  /// Competition end date parsed from the listing, if available.
  final DateTime? endDate;

  /// Creates a [CompetitionModel].
  const CompetitionModel({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    this.startDate,
    this.endDate,
  });

  /// Parses a [CompetitionModel] from a `.contest` DOM [element].
  ///
  /// Returns `null` if the element is malformed (missing `<h3><a>`).
  static CompetitionModel? fromElement(Element element) {
    final anchor = element.querySelector('h3 a');
    if (anchor == null) return null;

    final title = anchor.text.trim();
    final href = anchor.attributes['href'] ?? '';
    final url = 'https://www.soaringspot.com$href';
    final id = Uri.parse(
      href,
    ).pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');

    final rawDescription = element.querySelector('.info')?.text ?? '';
    final description = rawDescription.replaceAll(RegExp(r'\s+'), ' ').trim();
    final (startDate, endDate) = _parseDateRange(
      element.querySelector('.info > span')?.text ?? '',
    );

    return CompetitionModel(
      id: id,
      title: title,
      url: url,
      description: description,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Converts this model to the domain [Competition] entity.
  Competition toEntity() => Competition(
    id: id,
    title: title,
    url: url,
    description: description,
    startDate: startDate,
    endDate: endDate,
  );

  static final RegExp _datePattern = RegExp(r'\d{1,2} [A-Za-z]+ \d{4}$');
  static final DateFormat _dateFormat = DateFormat('d MMMM yyyy', 'en_US');

  static (DateTime?, DateTime?) _parseDateRange(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return (null, null);
    }

    final separatorIndex = normalized.lastIndexOf('–');
    if (separatorIndex == -1) {
      return (null, null);
    }

    final startSegment = normalized.substring(0, separatorIndex).trim();
    final endSegment = normalized.substring(separatorIndex + 1).trim();
    final startMatch = _datePattern.firstMatch(startSegment);

    return (_parseDate(startMatch?.group(0) ?? ''), _parseDate(endSegment));
  }

  static DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return _dateFormat.parseStrict(trimmed);
    } catch (_) {
      return null;
    }
  }
}
