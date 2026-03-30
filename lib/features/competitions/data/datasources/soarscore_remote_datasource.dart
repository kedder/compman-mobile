import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/task_info.dart';

/// Abstract interface for fetching task files from SoarScore.
abstract class SoarScoreRemoteDataSource {
  /// Fetches the list of available task files for the competition at [competitionId].
  ///
  /// Returns an empty list if the competition has no tasks.
  /// Throws [ServerException] on network or HTTP errors.
  Future<List<TaskInfo>> fetchLatestTasks(String competitionId);

  /// Downloads the raw bytes of the `.tsk` file at [taskUrl].
  ///
  /// Throws [ServerException] on network or HTTP errors.
  Future<Uint8List> downloadTask(String taskUrl);
}

/// HTTP + HTML scraping implementation of [SoarScoreRemoteDataSource].
///
/// Fetches the `#Downloads` tab on
/// `https://soarscore.com/competitions/{competitionId}/` and parses
/// `<a download href="...">` links to extract task metadata.
class DioSoarScoreRemoteDataSource implements SoarScoreRemoteDataSource {
  static const _baseUrl = 'https://soarscore.com';

  /// Regular expression matching the structured task description text.
  ///
  /// Groups: (class) Day(day) Task(task) (title) .tsk generated: (timestamp)
  static final _descRegex = RegExp(
    r'^(.*)\s+Day(\d+)\s+Task(\d+)\s+(.*)\s+\.tsk generated:\s+(.*)$',
    dotAll: true,
  );

  /// The [Dio] HTTP client used to perform requests.
  final Dio _dio;

  /// Creates a [DioSoarScoreRemoteDataSource] with the given [dio] client.
  const DioSoarScoreRemoteDataSource(this._dio);

  @override
  Future<List<TaskInfo>> fetchLatestTasks(String competitionId) async {
    final url = '$_baseUrl/competitions/$competitionId/';
    try {
      final response = await _dio.get<String>(url);
      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw ServerException('HTTP ${response.statusCode}');
      }
      final document = html_parser.parse(response.data ?? '');
      final links = document.querySelectorAll('#Downloads a[download]');
      final tasks = <TaskInfo>[];
      for (final link in links) {
        final href = link.attributes['href'] ?? '';
        final absoluteHref = href.startsWith('http') ? href : '$_baseUrl$href';
        final description = _elementText(link);
        final info = _parseTaskInfo(absoluteHref, description);
        if (info != null) tasks.add(info);
      }
      return tasks;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<Uint8List> downloadTask(String taskUrl) async {
    try {
      final response = await _dio.get<List<int>>(
        taskUrl,
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

  /// Parses a [TaskInfo] from a link [href] and its [description] text.
  ///
  /// Returns `null` if [description] does not match the expected format.
  static TaskInfo? _parseTaskInfo(String href, String description) {
    final match = _descRegex.firstMatch(description);
    if (match == null) return null;
    return TaskInfo(
      compClass: match.group(1)!.trim(),
      dayNo: int.parse(match.group(2)!),
      taskNo: int.parse(match.group(3)!),
      title: match.group(4)!.trim(),
      timestamp: match.group(5)!.trim(),
      taskUrl: href,
    );
  }

  /// Recursively collects text from all [node] text nodes, joined by spaces.
  ///
  /// Mirrors Python's `" ".join(link.itertext()).strip()` behaviour so that
  /// text fragments separated by inline elements (e.g. `<strong>`, `<br>`)
  /// are correctly separated when concatenated.
  static String _elementText(dom.Element element) {
    final parts = <String>[];
    for (final node in element.nodes) {
      if (node is dom.Text) {
        final t = node.text.trim();
        if (t.isNotEmpty) parts.add(t);
      } else if (node is dom.Element) {
        final nested = _elementText(node);
        if (nested.isNotEmpty) parts.add(nested);
      }
    }
    return parts.join(' ');
  }
}
