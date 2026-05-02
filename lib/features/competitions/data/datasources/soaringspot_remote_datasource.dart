import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/downloadable_file_info.dart';
import '../models/competition_model.dart';

/// Abstract interface for fetching competitions from SoaringSpot.
abstract class SoaringSpotRemoteDataSource {
  /// Fetches all competitions listed on the SoaringSpot homepage.
  ///
  /// Returns an empty list if no competitions are found.
  /// Throws [ServerException] on network errors.
  Future<List<CompetitionModel>> fetchCompetitions();

  /// Fetches the competition class names from the SoaringSpot results page.
  ///
  /// Scrapes `{competitionUrl}/results` for `table.result-overview thead th`
  /// elements. Returns an empty list if no table is found.
  /// Throws [ServerException] on network errors.
  Future<List<String>> fetchClasses(String competitionUrl);

  /// Fetches downloadable files listed on `{competitionUrl}/downloads`.
  ///
  /// Returns only `.txt` (airspace) and `.cup` (waypoints) entries.
  /// Throws [ServerException] on network errors.
  Future<List<DownloadableFileInfo>> fetchDownloads(String competitionUrl);

  /// Downloads the raw bytes of the file at [fileUrl].
  ///
  /// Throws [ServerException] on network errors.
  Future<Uint8List> downloadFile(String fileUrl);
}

/// HTTP + HTML scraping implementation of [SoaringSpotRemoteDataSource].
///
/// Fetches `https://www.soaringspot.com` and parses all `.contest` elements.
class SoaringSpotRemoteDataSourceImpl implements SoaringSpotRemoteDataSource {
  /// The [Dio] HTTP client used to perform the request.
  final Dio dio;

  /// Creates a [SoaringSpotRemoteDataSourceImpl] with the given [dio] client.
  SoaringSpotRemoteDataSourceImpl(this.dio);

  @override
  Future<List<CompetitionModel>> fetchCompetitions() async {
    try {
      final response = await dio.get<String>('https://www.soaringspot.com');
      final body = response.data ?? '';
      final document = html_parser.parse(body);
      final elements = document.querySelectorAll('.contest');
      return elements
          .map(CompetitionModel.fromElement)
          .whereType<CompetitionModel>()
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<String>> fetchClasses(String competitionUrl) async {
    final url =
        '${competitionUrl.endsWith('/') ? competitionUrl.substring(0, competitionUrl.length - 1) : competitionUrl}/results';
    try {
      final response = await dio.get<String>(url);
      final document = html_parser.parse(response.data ?? '');
      return document
          .querySelectorAll('table.result-overview thead th')
          .map((e) => e.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<DownloadableFileInfo>> fetchDownloads(
    String competitionUrl,
  ) async {
    final normalized = competitionUrl.endsWith('/')
        ? competitionUrl.substring(0, competitionUrl.length - 1)
        : competitionUrl;
    try {
      final response = await dio.get<String>('$normalized/downloads');
      final document = html_parser.parse(response.data ?? '');
      final results = <DownloadableFileInfo>[];

      // The downloads page alternates div.contest-downloads (timestamp info)
      // and ul.contest-downloads (file list). Iterate all and track the last
      // seen timestamp so each file group inherits the correct version token.
      String? currentTimestamp;
      for (final element in document.querySelectorAll('.contest-downloads')) {
        if (element.localName == 'div') {
          final spans = element.querySelectorAll('span');
          if (spans.length >= 2) {
            final ts = spans[1].text.trim();
            currentTimestamp = ts.isNotEmpty ? ts : null;
          } else {
            currentTimestamp = null;
          }
        } else if (element.localName == 'ul') {
          for (final li in element.querySelectorAll('li')) {
            final anchor = li.querySelector('a');
            if (anchor == null) continue;

            final filename = anchor.text.trim();
            final href = anchor.attributes['href'] ?? '';
            if (href.isEmpty) continue;

            final downloadUrl = href.startsWith('http')
                ? href
                : 'https://www.soaringspot.com$href';

            final kind = _kindFromFilename(filename);
            if (kind == null) continue;

            results.add(
              DownloadableFileInfo(
                filename: filename,
                downloadUrl: downloadUrl,
                kind: kind,
                fileSize: _parseFileSize(li.text),
                publishedVersion: currentTimestamp,
              ),
            );
          }
        }
      }

      return results;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<Uint8List> downloadFile(String fileUrl) async {
    try {
      final response = await dio.get<List<int>>(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw ServerException('HTTP ${response.statusCode}');
      }
      return Uint8List.fromList(response.data ?? []);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  /// Maps a filename extension to a [DownloadableFileKind], or null to skip.
  static DownloadableFileKind? _kindFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.txt')) return DownloadableFileKind.airspace;
    if (lower.endsWith('.cup')) return DownloadableFileKind.waypoints;
    return null;
  }

  /// Parses a file size in bytes from text like `"(134.831 kB)"`.
  ///
  /// Returns null if no size pattern is found or parsing fails.
  static int? _parseFileSize(String text) {
    final match = RegExp(r'\(([\d.,]+)\s*([kKmM][bB])\)').firstMatch(text);
    if (match == null) return null;
    final numStr = match.group(1)!.replaceAll(',', '');
    final unit = match.group(2)!.toLowerCase();
    final value = double.tryParse(numStr);
    if (value == null) return null;
    if (unit == 'kb') return (value * 1000).round();
    if (unit == 'mb') return (value * 1000000).round();
    return null;
  }
}
