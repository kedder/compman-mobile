import 'package:mockito/annotations.dart';

import 'package:compman_mobile/features/competitions/data/datasources/competitions_local_datasource.dart';
import 'package:compman_mobile/features/competitions/data/datasources/soaringspot_remote_datasource.dart';

@GenerateMocks([SoaringSpotRemoteDataSource, CompetitionsLocalDataSource])
// ignore: unused_import
export 'mock_datasources.mocks.dart';
