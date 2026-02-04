import 'gene_data_point.dart';
import 'enums.dart';

/// Holds the complete volcano plot dataset
class VolcanoData {
  final List<GeneDataPoint> points;
  final List<String> groups;
  final String selectedGroup;

  const VolcanoData({
    required this.points,
    required this.groups,
    required this.selectedGroup,
  });

  /// Empty dataset
  factory VolcanoData.empty() => const VolcanoData(
        points: [],
        groups: [],
        selectedGroup: '',
      );

  /// Get all points for the currently selected group
  List<GeneDataPoint> get currentGroupPoints =>
      points.where((p) => p.group == selectedGroup).toList();

  /// Get all unique gene names in current group
  List<String> get geneNames =>
      currentGroupPoints.map((p) => p.name).toSet().toList()..sort();

  /// Get top N hits based on ranking criterion and filter
  List<GeneDataPoint> getTopHits({
    required int topN,
    required RankingCriterion criterion,
    required HighlightFilter filter,
    required double fcMin,
    required double fcMax,
    required double sigThreshold,
  }) {
    if (topN <= 0) return [];

    var filtered = currentGroupPoints;

    // Apply filter
    switch (filter) {
      case HighlightFilter.all:
        // No filtering
        break;
      case HighlightFilter.changed:
        filtered = filtered.where((p) {
          final status = p.getChangeStatus(
            fcMin: fcMin,
            fcMax: fcMax,
            sigThreshold: sigThreshold,
          );
          return status != ChangeStatus.unchanged;
        }).toList();
        break;
      case HighlightFilter.up:
        filtered = filtered.where((p) {
          final status = p.getChangeStatus(
            fcMin: fcMin,
            fcMax: fcMax,
            sigThreshold: sigThreshold,
          );
          return status == ChangeStatus.increased;
        }).toList();
        break;
      case HighlightFilter.down:
        filtered = filtered.where((p) {
          final status = p.getChangeStatus(
            fcMin: fcMin,
            fcMax: fcMax,
            sigThreshold: sigThreshold,
          );
          return status == ChangeStatus.decreased;
        }).toList();
        break;
    }

    // Sort by ranking criterion (descending)
    filtered.sort((a, b) =>
        b.getRankingScore(criterion).compareTo(a.getRankingScore(criterion)));

    return filtered.take(topN).toList();
  }

  /// Search for genes by name (case-insensitive partial match)
  List<GeneDataPoint> searchGenes(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return currentGroupPoints
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get data bounds for auto-scaling
  ({double minX, double maxX, double minY, double maxY}) getDataBounds() {
    if (currentGroupPoints.isEmpty) {
      return (minX: -5.0, maxX: 5.0, minY: 0.0, maxY: 5.0);
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = 0.0; // Significance is always >= 0
    double maxY = double.negativeInfinity;

    for (final point in currentGroupPoints) {
      if (point.foldChange < minX) minX = point.foldChange;
      if (point.foldChange > maxX) maxX = point.foldChange;
      if (point.significance > maxY) maxY = point.significance;
    }

    // Add padding
    final xPadding = (maxX - minX) * 0.1;
    final yPadding = maxY * 0.1;

    return (
      minX: minX - xPadding,
      maxX: maxX + xPadding,
      minY: minY,
      maxY: maxY + yPadding,
    );
  }

  /// Creates a copy with a different selected group
  VolcanoData selectGroup(String group) {
    if (!groups.contains(group)) return this;
    return VolcanoData(
      points: points,
      groups: groups,
      selectedGroup: group,
    );
  }

  @override
  String toString() {
    return 'VolcanoData(${points.length} points, ${groups.length} groups, selected: $selectedGroup)';
  }
}
