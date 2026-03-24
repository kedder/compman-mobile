import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../../core/error/exceptions.dart';
import '../models/competition_model.dart';

/// Abstract interface for fetching competitions from SoaringSpot.
abstract class SoaringSpotRemoteDataSource {
  /// Fetches all competitions listed on the SoaringSpot homepage.
  ///
  /// Returns an empty list if no competitions are found.
  /// Throws [ServerException] on network errors.
  Future<List<CompetitionModel>> fetchCompetitions();
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
}
