import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' hide ServiceFactory;
import '../domain/models/gene_data_point.dart';
import '../domain/models/volcano_data.dart';

/// Container for resolved volcano data columns.
class ResolvedVolcanoColumns {
  final List<double> xValues;
  final List<double> yValues;
  final List<String> labels;
  final List<int> columnIndices;

  ResolvedVolcanoColumns({
    required this.xValues,
    required this.yValues,
    required this.labels,
    required this.columnIndices,
  });

  bool get hasData => xValues.isNotEmpty && yValues.isNotEmpty;
  int get length => xValues.length;
}

/// Resolves volcano plot data from Tercen CubeQueryTask projections.
///
/// This class extracts data from Tercen's query system:
/// - .x projection -> fold change
/// - .y projection -> significance (-log10 p-value)
/// - labels -> gene/kinase names
/// - .ci -> column indices for grouping
class VolcanoDataResolver {
  final ServiceFactory _serviceFactory;
  final String? _taskId;

  VolcanoDataResolver({
    required ServiceFactory serviceFactory,
    String? taskId,
  })  : _serviceFactory = serviceFactory,
        _taskId = taskId;

  /// Resolves volcano data from Tercen projections.
  Future<VolcanoData?> resolveVolcanoData() async {
    final taskId = _taskId;
    if (taskId == null || taskId.isEmpty) {
      print('VolcanoDataResolver: No taskId available');
      return null;
    }

    try {
      print('VolcanoDataResolver: Starting resolution for taskId: $taskId');

      // Get the task object
      final task = await _serviceFactory.taskService.get(taskId);
      print('VolcanoDataResolver: Retrieved task: ${task.id}');
      print('VolcanoDataResolver: Task type: ${task.runtimeType}');

      // Handle both RunWebAppTask and CubeQueryTask
      CubeQueryTask? cubeTask = await _getCubeQueryTask(task);

      if (cubeTask == null) {
        print('VolcanoDataResolver: Could not get CubeQueryTask');
        return null;
      }

      // Debug: Print query details
      final query = cubeTask.query;
      print('VolcanoDataResolver: CubeQueryTask id: ${cubeTask.id}');
      print('VolcanoDataResolver: CubeQueryTask state: ${cubeTask.state}');
      print('VolcanoDataResolver: Query rowHash: ${query.rowHash}');
      print('VolcanoDataResolver: Query columnHash: ${query.columnHash}');
      print('VolcanoDataResolver: Query qtHash: ${query.qtHash}');

      // Check if task has completed
      final taskState = cubeTask.state;
      print('VolcanoDataResolver: CubeQueryTask state object: $taskState');
      print('VolcanoDataResolver: CubeQueryTask state type: ${taskState.runtimeType}');

      // Extract projection data from task
      final columns = await _extractProjectionData(cubeTask);
      if (columns == null || !columns.hasData) {
        print('VolcanoDataResolver: Could not extract projection data');
        return null;
      }

      // Get group names from column factors
      final groupNames =
          await _extractGroupNames(cubeTask, columns.columnIndices);

      // Build GeneDataPoints
      final points = <GeneDataPoint>[];
      final groups = <String>{};

      for (var i = 0; i < columns.length; i++) {
        final group = groupNames[columns.columnIndices[i]] ?? 'Unknown';
        groups.add(group);

        points.add(GeneDataPoint(
          name: columns.labels[i],
          foldChange: columns.xValues[i],
          significance: columns.yValues[i],
          group: group,
        ));
      }

      final sortedGroups = groups.toList()..sort();

      print(
          'VolcanoDataResolver: Loaded ${points.length} points, ${sortedGroups.length} groups');

      return VolcanoData(
        points: points,
        groups: sortedGroups,
        selectedGroup: sortedGroups.isNotEmpty ? sortedGroups.first : '',
      );
    } catch (e, stackTrace) {
      print('VolcanoDataResolver: Error resolving data: $e');
      print(stackTrace);
      return null;
    }
  }

  Future<CubeQueryTask?> _getCubeQueryTask(Task task) async {
    if (task is CubeQueryTask) {
      print('VolcanoDataResolver: Task is already a CubeQueryTask');
      return task;
    }
    if (task is RunWebAppTask) {
      print('VolcanoDataResolver: Task is RunWebAppTask');
      print('VolcanoDataResolver: RunWebAppTask.cubeQueryTaskId: ${task.cubeQueryTaskId}');
      print('VolcanoDataResolver: RunWebAppTask.state: ${task.state}');
      print('VolcanoDataResolver: RunWebAppTask.projectId: ${task.projectId}');

      final cubeQueryTaskId = task.cubeQueryTaskId;
      if (cubeQueryTaskId.isEmpty) {
        print('VolcanoDataResolver: RunWebAppTask has empty cubeQueryTaskId');
        return null;
      }

      final cubeTaskObj =
          await _serviceFactory.taskService.get(cubeQueryTaskId);

      print('VolcanoDataResolver: Retrieved cubeTask type: ${cubeTaskObj.runtimeType}');

      if (cubeTaskObj is! CubeQueryTask) {
        print(
            'VolcanoDataResolver: Referenced task is not a CubeQueryTask: ${cubeTaskObj.runtimeType}');
        return null;
      }

      return cubeTaskObj;
    }

    print(
        'VolcanoDataResolver: Task is neither RunWebAppTask nor CubeQueryTask: ${task.runtimeType}');
    return null;
  }

  Future<ResolvedVolcanoColumns?> _extractProjectionData(
      CubeQueryTask cubeTask) async {
    final query = cubeTask.query;
    final rowHash = query.rowHash;
    if (rowHash.isEmpty) {
      print('VolcanoDataResolver: Query has no rowHash');
      return null;
    }

    try {
      // Get row schema to find column names
      print('VolcanoDataResolver: Fetching schema for rowHash: $rowHash');
      final rowSchema = await _serviceFactory.tableSchemaService.get(rowHash);

      print('VolcanoDataResolver: Row schema id: ${rowSchema.id}');
      print('VolcanoDataResolver: Row schema nRows: ${rowSchema.nRows}');
      print('VolcanoDataResolver: Row schema columns count: ${rowSchema.columns.length}');

      // Debug: Print detailed column info
      print('VolcanoDataResolver: Row schema type: ${rowSchema.runtimeType}');
      for (var i = 0; i < rowSchema.columns.length; i++) {
        final col = rowSchema.columns[i];
        print('VolcanoDataResolver: Column[$i] type: ${col.runtimeType}');
        print('VolcanoDataResolver: Column[$i] name: "${col.name}"');
        print('VolcanoDataResolver: Column[$i] nRows: ${col.nRows}');
        print('VolcanoDataResolver: Column[$i] colType: ${col.type}');
      }

      print('VolcanoDataResolver: Row schema columns: ${rowSchema.columns.map((c) => c.name).join(", ")}');

      // Check if schema has required columns
      final columnNames = rowSchema.columns.map((c) => c.name).toSet();
      final hasXColumn = columnNames.contains('.x');
      final hasYColumn = columnNames.contains('.y');

      if (!hasXColumn || !hasYColumn) {
        print('VolcanoDataResolver: Missing required columns. Has .x: $hasXColumn, Has .y: $hasYColumn');
        print('VolcanoDataResolver: Available columns: $columnNames');
        return null;
      }

      // Find the label column (first non-dot-prefixed column)
      String? labelColumnName;
      for (final col in rowSchema.columns) {
        if (!col.name.startsWith('.')) {
          labelColumnName = col.name;
          break;
        }
      }

      print('VolcanoDataResolver: Label column: $labelColumnName');

      // Build list of columns to fetch
      final columnsToFetch = <String>['.x', '.y', '.ci'];
      if (labelColumnName != null) {
        columnsToFetch.add(labelColumnName);
      }

      // Calculate appropriate limit based on nRows (max 10000 per request for safety)
      final nRows = rowSchema.nRows;
      final limit = nRows > 0 && nRows < 10000 ? nRows : 10000;
      print('VolcanoDataResolver: Fetching with limit: $limit (schema nRows: $nRows)');

      // Fetch row data
      final rowData = await _serviceFactory.tableSchemaService
          .select(rowHash, columnsToFetch, 0, limit);

      print('VolcanoDataResolver: Fetched ${rowData.nRows} rows');

      // Parse the results
      final xValues = <double>[];
      final yValues = <double>[];
      final labels = <String>[];
      final ciValues = <int>[];

      for (final col in rowData.columns) {
        final values = col.values;
        if (values == null) continue;

        switch (col.name) {
          case '.x':
            for (final v in values) {
              xValues.add(_toDouble(v));
            }
            break;
          case '.y':
            for (final v in values) {
              yValues.add(_toDouble(v));
            }
            break;
          case '.ci':
            for (final v in values) {
              ciValues.add(_toInt(v));
            }
            break;
          default:
            if (labelColumnName != null && col.name == labelColumnName) {
              for (final v in values) {
                labels.add(v?.toString() ?? '');
              }
            }
        }
      }

      // If no labels found, generate placeholder names
      if (labels.isEmpty) {
        for (var i = 0; i < xValues.length; i++) {
          labels.add('Gene_$i');
        }
      }

      // If no ci values, default to 0
      if (ciValues.isEmpty) {
        ciValues.addAll(List.filled(xValues.length, 0));
      }

      // Validate that we have matching lengths
      if (xValues.length != yValues.length) {
        print(
            'VolcanoDataResolver: Mismatched x/y lengths: ${xValues.length} vs ${yValues.length}');
        return null;
      }

      print(
          'VolcanoDataResolver: Extracted ${xValues.length} x values, ${yValues.length} y values, ${labels.length} labels');

      return ResolvedVolcanoColumns(
        xValues: xValues,
        yValues: yValues,
        labels: labels,
        columnIndices: ciValues,
      );
    } catch (e, stackTrace) {
      print('VolcanoDataResolver: Error extracting projection data: $e');
      print(stackTrace);
      return null;
    }
  }

  Future<Map<int, String>> _extractGroupNames(
    CubeQueryTask cubeTask,
    List<int> columnIndices,
  ) async {
    final uniqueIndices = columnIndices.toSet();
    final groupMap = <int, String>{};

    try {
      final columnHash = cubeTask.query.columnHash;
      if (columnHash.isEmpty) {
        // Default group names
        for (final ci in uniqueIndices) {
          groupMap[ci] = 'Group_$ci';
        }
        return groupMap;
      }

      // Get column schema
      final columnSchema =
          await _serviceFactory.tableSchemaService.get(columnHash);

      print('VolcanoDataResolver: Column schema columns: ${columnSchema.columns.map((c) => c.name).join(", ")}');

      // Find the group column (often named with a pattern like "*.group" or "contrast")
      String? groupColumnName;
      for (final col in columnSchema.columns) {
        if (!col.name.startsWith('.')) {
          final lowerName = col.name.toLowerCase();
          if (lowerName.contains('group') ||
              lowerName.contains('contrast') ||
              lowerName.contains('condition')) {
            groupColumnName = col.name;
            break;
          }
        }
      }

      // Fall back to first non-dot column if no group column found
      if (groupColumnName == null) {
        for (final col in columnSchema.columns) {
          if (!col.name.startsWith('.')) {
            groupColumnName = col.name;
            break;
          }
        }
      }

      if (groupColumnName == null) {
        for (final ci in uniqueIndices) {
          groupMap[ci] = 'Group_$ci';
        }
        return groupMap;
      }

      print('VolcanoDataResolver: Group column: $groupColumnName');

      // Fetch column data
      final columnData = await _serviceFactory.tableSchemaService
          .select(columnHash, ['.ci', groupColumnName], 0, 1000);

      Column? ciCol;
      Column? nameCol;

      for (final col in columnData.columns) {
        if (col.name == '.ci') {
          ciCol = col;
        } else if (col.name == groupColumnName) {
          nameCol = col;
        }
      }

      if (ciCol?.values != null && nameCol?.values != null) {
        final ciValues = ciCol!.values!;
        final nameValues = nameCol!.values!;
        final length =
            ciValues.length < nameValues.length ? ciValues.length : nameValues.length;

        for (var i = 0; i < length; i++) {
          final ci = _toInt(ciValues[i]);
          final name = nameValues[i]?.toString() ?? 'Group_$ci';
          groupMap[ci] = name;
        }
      }

      print('VolcanoDataResolver: Group map: $groupMap');
    } catch (e) {
      print('VolcanoDataResolver: Error extracting group names: $e');
      for (final ci in uniqueIndices) {
        groupMap[ci] = 'Group_$ci';
      }
    }

    return groupMap;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
