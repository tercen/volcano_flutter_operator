import 'dart:math';
import 'enums.dart';

/// Represents a single gene data point in the volcano plot
class GeneDataPoint {
  final String name;
  final double foldChange;
  final double significance;
  final String group;

  const GeneDataPoint({
    required this.name,
    required this.foldChange,
    required this.significance,
    required this.group,
  });

  /// Classifies the change status based on thresholds
  ChangeStatus getChangeStatus({
    required double fcMin,
    required double fcMax,
    required double sigThreshold,
  }) {
    if (significance < sigThreshold) {
      return ChangeStatus.unchanged;
    }
    if (foldChange > fcMax) {
      return ChangeStatus.increased;
    }
    if (foldChange < fcMin) {
      return ChangeStatus.decreased;
    }
    return ChangeStatus.unchanged;
  }

  /// Manhattan distance from origin (used for ranking)
  double get manhattanDistance => foldChange.abs() + significance;

  /// Euclidean distance from origin (used for ranking)
  double get euclideanDistance =>
      sqrt(pow(foldChange, 2) + pow(significance, 2));

  /// Get ranking score based on criterion
  double getRankingScore(RankingCriterion criterion) {
    switch (criterion) {
      case RankingCriterion.manhattan:
        return manhattanDistance;
      case RankingCriterion.euclidean:
        return euclideanDistance;
      case RankingCriterion.foldChange:
        return foldChange.abs();
      case RankingCriterion.significance:
        return significance;
    }
  }

  /// Creates a copy with optional field overrides
  GeneDataPoint copyWith({
    String? name,
    double? foldChange,
    double? significance,
    String? group,
  }) {
    return GeneDataPoint(
      name: name ?? this.name,
      foldChange: foldChange ?? this.foldChange,
      significance: significance ?? this.significance,
      group: group ?? this.group,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneDataPoint &&
        other.name == name &&
        other.foldChange == foldChange &&
        other.significance == significance &&
        other.group == group;
  }

  @override
  int get hashCode => Object.hash(name, foldChange, significance, group);

  @override
  String toString() {
    return 'GeneDataPoint(name: $name, fc: $foldChange, sig: $significance, group: $group)';
  }
}
