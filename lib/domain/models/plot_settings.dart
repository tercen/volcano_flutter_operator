import 'enums.dart';

/// Holds all configurable settings for the volcano plot
class PlotSettings {
  // Thresholds
  final double fcMin;
  final double fcMax;
  final double significanceThreshold;

  // Selection
  final HighlightFilter highlightFilter;
  final RankingCriterion rankingCriterion;
  final int topN;
  final Set<String> selectedGenes;

  // Appearance
  final double pointSize;
  final double opacity;
  final double textScale;
  final bool showGridlines;
  final bool showLabels;
  final bool showLegend;

  // Axes
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  final bool yLogScale;
  final bool rotateAxes;

  // Labels
  final String? title;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final bool titleEdited;
  final bool xAxisLabelEdited;
  final bool yAxisLabelEdited;
  final bool showXAxisLabel;
  final bool showYAxisLabel;

  // Export
  final int exportWidth;
  final int exportHeight;

  // Panel state
  final bool isPanelCollapsed;

  const PlotSettings({
    this.fcMin = -1.5,
    this.fcMax = 1.5,
    this.significanceThreshold = 2.0,
    this.highlightFilter = HighlightFilter.changed,
    this.rankingCriterion = RankingCriterion.manhattan,
    this.topN = 10,
    this.selectedGenes = const {},
    this.pointSize = 4.0,
    this.opacity = 0.8,
    this.textScale = 1.0,
    this.showGridlines = false,
    this.showLabels = true,
    this.showLegend = true,
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.yLogScale = false,
    this.rotateAxes = false,
    this.title,
    this.xAxisLabel,
    this.yAxisLabel,
    this.titleEdited = false,
    this.xAxisLabelEdited = false,
    this.yAxisLabelEdited = false,
    this.showXAxisLabel = true,
    this.showYAxisLabel = true,
    this.exportWidth = 750,
    this.exportHeight = 600,
    this.isPanelCollapsed = false,
  });

  /// Default title placeholder text
  static const String defaultTitlePlaceholder = 'Click to add title';

  /// Default X-axis label
  static const String defaultXAxisLabel = 'Fold Change (Log\u2082)';

  /// Default Y-axis label
  static const String defaultYAxisLabel = 'Significance (-Log\u2081\u2080)';

  /// Effective X-axis label for display
  String get effectiveXAxisLabel => xAxisLabel ?? defaultXAxisLabel;

  /// Effective Y-axis label for display
  String get effectiveYAxisLabel => yAxisLabel ?? defaultYAxisLabel;

  /// Effective title for display
  String? get effectiveTitle => titleEdited ? title : null;

  /// X-axis label for export (returns default if not edited)
  String get exportXAxisLabel =>
      xAxisLabelEdited ? (xAxisLabel ?? defaultXAxisLabel) : defaultXAxisLabel;

  /// Y-axis label for export (returns default if not edited)
  String get exportYAxisLabel =>
      yAxisLabelEdited ? (yAxisLabel ?? defaultYAxisLabel) : defaultYAxisLabel;

  /// Title for export (returns null/empty if not edited)
  String? get exportTitle => titleEdited ? title : null;

  /// Creates a copy with optional field overrides
  PlotSettings copyWith({
    double? fcMin,
    double? fcMax,
    double? significanceThreshold,
    HighlightFilter? highlightFilter,
    RankingCriterion? rankingCriterion,
    int? topN,
    Set<String>? selectedGenes,
    double? pointSize,
    double? opacity,
    double? textScale,
    bool? showGridlines,
    bool? showLabels,
    bool? showLegend,
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    bool? yLogScale,
    bool? rotateAxes,
    String? title,
    String? xAxisLabel,
    String? yAxisLabel,
    bool? titleEdited,
    bool? xAxisLabelEdited,
    bool? yAxisLabelEdited,
    bool? showXAxisLabel,
    bool? showYAxisLabel,
    int? exportWidth,
    int? exportHeight,
    bool? isPanelCollapsed,
  }) {
    return PlotSettings(
      fcMin: fcMin ?? this.fcMin,
      fcMax: fcMax ?? this.fcMax,
      significanceThreshold: significanceThreshold ?? this.significanceThreshold,
      highlightFilter: highlightFilter ?? this.highlightFilter,
      rankingCriterion: rankingCriterion ?? this.rankingCriterion,
      topN: topN ?? this.topN,
      selectedGenes: selectedGenes ?? this.selectedGenes,
      pointSize: pointSize ?? this.pointSize,
      opacity: opacity ?? this.opacity,
      textScale: textScale ?? this.textScale,
      showGridlines: showGridlines ?? this.showGridlines,
      showLabels: showLabels ?? this.showLabels,
      showLegend: showLegend ?? this.showLegend,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
      yLogScale: yLogScale ?? this.yLogScale,
      rotateAxes: rotateAxes ?? this.rotateAxes,
      title: title ?? this.title,
      xAxisLabel: xAxisLabel ?? this.xAxisLabel,
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      titleEdited: titleEdited ?? this.titleEdited,
      xAxisLabelEdited: xAxisLabelEdited ?? this.xAxisLabelEdited,
      yAxisLabelEdited: yAxisLabelEdited ?? this.yAxisLabelEdited,
      showXAxisLabel: showXAxisLabel ?? this.showXAxisLabel,
      showYAxisLabel: showYAxisLabel ?? this.showYAxisLabel,
      exportWidth: exportWidth ?? this.exportWidth,
      exportHeight: exportHeight ?? this.exportHeight,
      isPanelCollapsed: isPanelCollapsed ?? this.isPanelCollapsed,
    );
  }

  /// Reset appearance settings to defaults
  PlotSettings resetAppearance() {
    return copyWith(
      pointSize: 4.0,
      opacity: 0.8,
      textScale: 1.0,
      showGridlines: false,
      showLabels: true,
      showLegend: true,
      showXAxisLabel: true,
      showYAxisLabel: true,
    );
  }

  /// Reset all settings to defaults
  factory PlotSettings.defaults() => const PlotSettings();
}
