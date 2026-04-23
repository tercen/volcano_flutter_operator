/// Change status classification for gene data points
enum ChangeStatus {
  unchanged,
  increased,
  decreased;

  String get displayName {
    switch (this) {
      case ChangeStatus.unchanged:
        return 'Unchanged';
      case ChangeStatus.increased:
        return 'Increased';
      case ChangeStatus.decreased:
        return 'Decreased';
    }
  }
}

/// Direction filter for highlighting points
enum HighlightFilter {
  all,
  changed,
  up,
  down;

  String get displayName {
    switch (this) {
      case HighlightFilter.all:
        return 'All';
      case HighlightFilter.changed:
        return 'Changed';
      case HighlightFilter.up:
        return 'Up';
      case HighlightFilter.down:
        return 'Down';
    }
  }
}

/// Unit used for displaying/editing export dimensions
enum ExportUnit {
  px,
  cm;

  String get displayName {
    switch (this) {
      case ExportUnit.px:
        return 'px';
      case ExportUnit.cm:
        return 'cm';
    }
  }
}

/// DPI used to convert between pixels and centimetres for export dimensions
const double exportDpi = 300.0;

/// Ranking criterion for top hits
enum RankingCriterion {
  manhattan,
  euclidean,
  foldChange,
  significance;

  String get displayName {
    switch (this) {
      case RankingCriterion.manhattan:
        return 'Manhattan';
      case RankingCriterion.euclidean:
        return 'Euclidean';
      case RankingCriterion.foldChange:
        return 'Fold Change';
      case RankingCriterion.significance:
        return 'Significance';
    }
  }
}
