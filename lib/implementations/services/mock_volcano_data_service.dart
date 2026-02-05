import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../../domain/models/gene_data_point.dart';
import '../../domain/models/volcano_data.dart';
import '../../domain/services/volcano_data_service.dart';

/// Mock implementation of VolcanoDataService that loads data from CSV assets
class MockVolcanoDataService implements VolcanoDataService {
  VolcanoData? _cachedData;

  @override
  Future<VolcanoData> loadData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      print('MockVolcanoDataService: Loading CSV files from assets...');

      // Load CSV files from assets
      final rowDataCsv = await rootBundle.loadString('assets/data/example_row_data.csv');
      final columnDataCsv = await rootBundle.loadString('assets/data/example_column_data.csv');

      print('MockVolcanoDataService: Row CSV length: ${rowDataCsv.length}');
      print('MockVolcanoDataService: Column CSV length: ${columnDataCsv.length}');

      // Parse CSVs
      const csvConverter = CsvToListConverter();
      final rowData = csvConverter.convert(rowDataCsv);
      final columnData = csvConverter.convert(columnDataCsv);

      print('MockVolcanoDataService: Row data rows: ${rowData.length}');
      print('MockVolcanoDataService: Column data rows: ${columnData.length}');

      // Build group mapping from column data
      // Column data format: .ci, UKA_app.UKA.Sgroup_contrast
      // Note: .ci in column data is 1-based, while in row data it's 0-based
      final groupMap = <int, String>{};
      for (var i = 1; i < columnData.length; i++) {
        final row = columnData[i];
        final ci = int.parse(row[0].toString());
        final groupName = row[1].toString();
        groupMap[ci - 1] = groupName; // Convert to 0-based
      }

      // Get column indices from header
      final headers = rowData[0].map((h) => h.toString()).toList();
      print('MockVolcanoDataService: Headers: $headers');

      final ciIndex = headers.indexOf('.ci');
      final xIndex = headers.indexOf('.x');
      final yIndex = headers.indexOf('.y');
      final nameIndex = headers.indexOf('UKA_app.UKA.Kinase Name');

      print('MockVolcanoDataService: Column indices - ci: $ciIndex, x: $xIndex, y: $yIndex, name: $nameIndex');

      // Parse data points
      final points = <GeneDataPoint>[];
      final groups = <String>{};

      for (var i = 1; i < rowData.length; i++) {
        final row = rowData[i];

        final ci = int.parse(row[ciIndex].toString());
        final foldChange = double.parse(row[xIndex].toString());
        final significance = double.parse(row[yIndex].toString());
        final name = row[nameIndex].toString();
        final group = groupMap[ci] ?? 'Unknown';

        groups.add(group);

        points.add(GeneDataPoint(
          name: name,
          foldChange: foldChange,
          significance: significance,
          group: group,
        ));
      }

      final sortedGroups = groups.toList()..sort();

      print('MockVolcanoDataService: Loaded ${points.length} points, ${sortedGroups.length} groups');

      _cachedData = VolcanoData(
        points: points,
        groups: sortedGroups,
        selectedGroup: sortedGroups.isNotEmpty ? sortedGroups.first : '',
      );

      return _cachedData!;
    } catch (e, stackTrace) {
      print('MockVolcanoDataService: Error loading mock data: $e');
      print(stackTrace);
      // Return empty data instead of throwing
      return VolcanoData(points: [], groups: [], selectedGroup: '');
    }
  }

  @override
  Future<VolcanoData> refreshData() async {
    _cachedData = null;
    return loadData();
  }
}
