import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../../domain/models/gene_data_point.dart';
import '../../domain/models/volcano_data.dart';
import '../../domain/services/volcano_data_service.dart';

/// Mock implementation of VolcanoDataService that loads data from CSV assets.
///
/// Uses the same data model as Tercen production:
/// - qt.csv: Main data with .ci, .x, .y, labels (like qtHash)
/// - column.csv: Group names in row order (like columnHash)
class MockVolcanoDataService implements VolcanoDataService {
  VolcanoData? _cachedData;

  @override
  Future<VolcanoData> loadData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      print('MockVolcanoDataService: Loading CSV files from assets...');

      // Load CSV files from assets (matching Tercen production model)
      final qtCsv = await rootBundle.loadString('assets/data/Production/qt.csv');
      final columnCsv = await rootBundle.loadString('assets/data/Production/column.csv');

      print('MockVolcanoDataService: QT CSV length: ${qtCsv.length}');
      print('MockVolcanoDataService: Column CSV length: ${columnCsv.length}');

      // Normalize line endings (handles \r\n, \r, or \n)
      final normalizedQtCsv = qtCsv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final normalizedColumnCsv = columnCsv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // Parse CSVs with explicit newline character
      const csvConverter = CsvToListConverter(eol: '\n');
      final qtData = csvConverter.convert(normalizedQtCsv);
      final columnData = csvConverter.convert(normalizedColumnCsv);

      print('MockVolcanoDataService: QT data rows: ${qtData.length}');
      print('MockVolcanoDataService: Column data rows: ${columnData.length}');

      // Build group mapping from column data
      // Column data has NO .ci column - groups are in row order (row index = group index)
      // First row is header, subsequent rows are group names
      final groupMap = <int, String>{};
      for (var i = 1; i < columnData.length; i++) {
        final row = columnData[i];
        // Row index (0-based after skipping header) = group index
        final groupName = row[0].toString();
        groupMap[i - 1] = groupName;
      }

      print('MockVolcanoDataService: Group map: $groupMap');

      // Get column indices from QT header
      final headers = qtData[0].map((h) => h.toString()).toList();
      print('MockVolcanoDataService: QT Headers: $headers');

      final ciIndex = headers.indexOf('.ci');
      final xIndex = headers.indexOf('.x');
      final yIndex = headers.indexOf('.y');

      // Find label column (prefer "Name" columns)
      int nameIndex = -1;
      for (var i = 0; i < headers.length; i++) {
        final h = headers[i].toLowerCase();
        if (!headers[i].startsWith('.') &&
            (h.contains('name') || h.contains('label') || h.contains('gene'))) {
          nameIndex = i;
          break;
        }
      }
      // Fallback to first non-dot column
      if (nameIndex == -1) {
        for (var i = 0; i < headers.length; i++) {
          if (!headers[i].startsWith('.')) {
            nameIndex = i;
            break;
          }
        }
      }

      print('MockVolcanoDataService: Column indices - ci: $ciIndex, x: $xIndex, y: $yIndex, name: $nameIndex');

      if (ciIndex == -1 || xIndex == -1 || yIndex == -1) {
        print('MockVolcanoDataService: Missing required columns');
        return VolcanoData(points: [], groups: [], selectedGroup: '');
      }

      // Parse data points
      final points = <GeneDataPoint>[];
      final groups = <String>{};

      for (var i = 1; i < qtData.length; i++) {
        final row = qtData[i];

        final ci = int.parse(row[ciIndex].toString());
        final foldChange = double.parse(row[xIndex].toString());
        final significance = double.parse(row[yIndex].toString());
        final name = nameIndex >= 0 ? row[nameIndex].toString() : 'Gene_$i';
        final group = groupMap[ci] ?? 'Group_$ci';

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
