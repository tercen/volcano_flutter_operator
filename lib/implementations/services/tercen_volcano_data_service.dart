import 'package:sci_tercen_client/sci_client_service_factory.dart';
import '../../domain/models/volcano_data.dart';
import '../../domain/services/volcano_data_service.dart';
import '../../utils/volcano_data_resolver.dart';
import 'mock_volcano_data_service.dart';

/// Real implementation of VolcanoDataService using Tercen platform API.
///
/// This service fetches volcano plot data from Tercen's CubeQuery projections:
/// - .x projection -> fold change
/// - .y projection -> significance (-log10 p-value)
/// - labels -> gene names
/// - .ci -> group/condition indices
///
/// Features:
/// - Automatic fallback to mock data when Tercen context unavailable
/// - Comprehensive error handling with debug logging
/// - Caching of loaded data
class TercenVolcanoDataService implements VolcanoDataService {
  final VolcanoDataResolver _resolver;
  final MockVolcanoDataService _mockService;

  VolcanoData? _cachedData;

  TercenVolcanoDataService(
    ServiceFactory serviceFactory, {
    String? taskId,
  })  : _resolver = VolcanoDataResolver(
          serviceFactory: serviceFactory,
          taskId: taskId,
        ),
        _mockService = MockVolcanoDataService();

  @override
  Future<VolcanoData> loadData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      print('TercenVolcanoDataService: Loading data from Tercen...');

      final data = await _resolver.resolveVolcanoData();

      if (data == null || data.points.isEmpty) {
        print('TercenVolcanoDataService: No data from Tercen, falling back to mock data');
        _cachedData = await _mockService.loadData();
        return _cachedData!;
      }

      print('TercenVolcanoDataService: Loaded ${data.points.length} points from Tercen');
      print('TercenVolcanoDataService: Groups: ${data.groups.join(", ")}');

      _cachedData = data;
      return _cachedData!;
    } catch (e, stackTrace) {
      print('TercenVolcanoDataService: Error loading from Tercen: $e');
      print(stackTrace);
      print('TercenVolcanoDataService: Falling back to mock data');

      try {
        _cachedData = await _mockService.loadData();
        return _cachedData!;
      } catch (mockError) {
        print('TercenVolcanoDataService: Mock data also failed: $mockError');
        // Return empty data as last resort
        _cachedData = VolcanoData(points: [], groups: [], selectedGroup: '');
        return _cachedData!;
      }
    }
  }

  @override
  Future<VolcanoData> refreshData() async {
    _cachedData = null;
    return loadData();
  }
}
