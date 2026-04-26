import 'package:html/dom.dart';

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

  /// Creates a [CompetitionModel].
  const CompetitionModel({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
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

    return CompetitionModel(
      id: id,
      title: title,
      url: url,
      description: description,
    );
  }

  /// Converts this model to the domain [Competition] entity.
  Competition toEntity() =>
      Competition(id: id, title: title, url: url, description: description);
}
