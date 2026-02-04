import '../models/volcano_data.dart';

/// Abstract service for loading volcano plot data
abstract class VolcanoDataService {
  /// Loads the volcano plot data
  Future<VolcanoData> loadData();

  /// Refreshes the data from source
  Future<VolcanoData> refreshData();
}
