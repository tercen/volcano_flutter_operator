import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/gene_data_point.dart';
import '../../../domain/models/plot_settings.dart';
import '../../../domain/models/volcano_data.dart';
import '../../providers/plot_settings_provider.dart';
import '../../providers/volcano_data_provider.dart';

/// Main volcano plot chart widget
class VolcanoChart extends StatefulWidget {
  final Function(GeneDataPoint)? onPointTap;
  final Function(GeneDataPoint?)? onPointHover;

  const VolcanoChart({
    super.key,
    this.onPointTap,
    this.onPointHover,
  });

  @override
  State<VolcanoChart> createState() => _VolcanoChartState();
}

class _VolcanoChartState extends State<VolcanoChart> {
  GeneDataPoint? _hoveredPoint;
  Offset? _hoverPosition;

  /// Transform Y value for log scale (applies log10 when enabled)
  /// Returns the original value if log scale is disabled or value <= 0
  double _transformY(double y, bool useLogScale) {
    if (!useLogScale || y <= 0) return y;
    return math.log(y) / math.ln10; // log10(y)
  }

  /// Calculate Y bounds from transformed data points (for log scale)
  ({double min, double max}) _calculateTransformedYBounds(
      List<GeneDataPoint> points) {
    if (points.isEmpty) {
      return (min: 0.0, max: 1.0);
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final point in points) {
      if (point.significance > 0) {
        final transformedY = math.log(point.significance) / math.ln10;
        if (transformedY < minY) minY = transformedY;
        if (transformedY > maxY) maxY = transformedY;
      }
    }

    // Handle edge case where no valid points
    if (minY == double.infinity) {
      return (min: 0.0, max: 1.0);
    }

    // Add padding
    final yPadding = (maxY - minY) * 0.1;
    return (min: minY - yPadding, max: maxY + yPadding);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<VolcanoDataProvider>();
    final settingsProvider = context.watch<PlotSettingsProvider>();

    final data = dataProvider.data;
    final settings = settingsProvider.settings;
    // Chart always uses light mode colors regardless of app theme
    // This ensures the chart looks the same as the exported PNG/PDF
    const isDark = false;

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dataProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColorsDark.error : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(dataProvider.error!),
          ],
        ),
      );
    }

    if (!dataProvider.hasData) {
      return const Center(child: Text('No data available'));
    }

    // Get data bounds - for Y axis with log scale, we need to calculate
    // bounds from transformed data since raw minY=0 doesn't transform well
    final bounds = data.getDataBounds();
    final minX = settings.xMin ?? bounds.minX;
    final maxX = settings.xMax ?? bounds.maxX;

    double minY;
    double maxY;
    if (settings.yLogScale && settings.yMin == null && settings.yMax == null) {
      // Calculate bounds from transformed data
      final yBounds = _calculateTransformedYBounds(data.currentGroupPoints);
      minY = yBounds.min;
      maxY = yBounds.max;
    } else {
      // Use raw bounds with transformation
      final rawMinY = settings.yMin ?? bounds.minY;
      final rawMaxY = settings.yMax ?? bounds.maxY;
      minY = _transformY(rawMinY, settings.yLogScale);
      maxY = _transformY(rawMaxY, settings.yLogScale);
    }

    // Get top hits and selected genes
    final topHits = data.getTopHits(
      topN: settings.topN,
      criterion: settings.rankingCriterion,
      filter: settings.highlightFilter,
      fcMin: settings.fcMin,
      fcMax: settings.fcMax,
      sigThreshold: settings.significanceThreshold,
    );
    final topHitNames = topHits.map((p) => p.name).toSet();
    final labeledGenes = {...topHitNames, ...settings.selectedGenes};

    // Build scatter spots
    final spots = _buildScatterSpots(
      data: data,
      settings: settings,
      isDark: isDark,
      labeledGenes: labeledGenes,
    );

    // Colors
    final gridColor = isDark ? AppColorsDark.border : AppColors.border;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    // Legend width when shown
    const legendWidth = 100.0;

    // Calculate aspect ratio from export dimensions
    final aspectRatio = settings.exportWidth / settings.exportHeight;

    // Check if title should be shown
    final hasTitle = settings.title != null && settings.title!.isNotEmpty;
    final titleHeight = hasTitle ? 32.0 : 0.0;

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Column(
          children: [
            // Title at top of chart
            if (hasTitle)
              SizedBox(
                height: titleHeight,
                child: Center(
                  child: Text(
                    settings.title!,
                    style: TextStyle(
                      fontSize: 16 * settings.textScale,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            // Chart area with legend
            Expanded(
              child: Row(
                children: [
                  // Chart
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 60,   // Space for Y-axis label and ticks
                            right: 16,
                            top: 16,
                            bottom: 56, // Space for X-axis label and ticks
                          ),
                          child: CustomPaint(
                            painter: ThresholdLinesPainter(
                              settings: settings,
                              minX: settings.rotateAxes ? minY : minX,
                              maxX: settings.rotateAxes ? maxY : maxX,
                              minY: settings.rotateAxes ? minX : minY,
                              maxY: settings.rotateAxes ? maxX : maxY,
                              isDark: isDark,
                            ),
                            child: ScatterChart(
                              ScatterChartData(
                                minX: settings.rotateAxes ? minY : minX,
                                maxX: settings.rotateAxes ? maxY : maxX,
                                minY: settings.rotateAxes ? minX : minY,
                                maxY: settings.rotateAxes ? maxX : maxY,
                                scatterSpots: spots,
                                gridData: FlGridData(
                                  show: settings.showGridlines,
                                  drawHorizontalLine: settings.showGridlines,
                                  drawVerticalLine: settings.showGridlines,
                                  horizontalInterval: _calculateInterval(
                                    settings.rotateAxes ? minX : minY,
                                    settings.rotateAxes ? maxX : maxY,
                                  ),
                                  verticalInterval: _calculateInterval(
                                    settings.rotateAxes ? minY : minX,
                                    settings.rotateAxes ? maxY : maxX,
                                  ),
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: gridColor.withValues(alpha: 0.3),
                                    strokeWidth: 1,
                                  ),
                                  getDrawingVerticalLine: (value) => FlLine(
                                    color: gridColor.withValues(alpha: 0.3),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: _buildTitlesData(settings, textColor),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: gridColor),
                                ),
                                scatterTouchData: ScatterTouchData(
                                  enabled: true,
                                  touchTooltipData: ScatterTouchTooltipData(
                                    getTooltipColor: (spot) => Colors.transparent,
                                    getTooltipItems: (_) => null,
                                  ),
                                  handleBuiltInTouches: false,
                                  touchCallback: (event, response) {
                                    _handleTouch(event, response, data, settings);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Gene labels overlay (only if showLabels is enabled)
                        if (settings.showLabels && labeledGenes.isNotEmpty)
                          _buildLabelsOverlay(data, settings, labeledGenes, isDark),
                        // Hover tooltip
                        if (_hoveredPoint != null && _hoverPosition != null)
                          _buildTooltip(_hoveredPoint!, _hoverPosition!, isDark),
                      ],
                    ),
                  ),
                  // Legend - with padding matching chart's top/bottom to center on Y-axis
                  if (settings.showLegend)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 16,    // Match chart top padding
                        bottom: 56, // Match chart bottom padding
                      ),
                      child: SizedBox(
                        width: legendWidth,
                        child: Center(
                          child: _buildLegendPanel(context, settingsProvider, isDark),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ScatterSpot> _buildScatterSpots({
    required VolcanoData data,
    required PlotSettings settings,
    required bool isDark,
    required Set<String> labeledGenes,
  }) {
    final points = data.currentGroupPoints;
    final spots = <ScatterSpot>[];

    for (final point in points) {
      final status = point.getChangeStatus(
        fcMin: settings.fcMin,
        fcMax: settings.fcMax,
        sigThreshold: settings.significanceThreshold,
      );

      // Determine effective status based on highlight filter
      // Filter affects coloring: non-matching significant points show as grey
      final effectiveStatus = _getEffectiveStatus(status, settings.highlightFilter);

      // Determine color based on effective status
      Color color;
      switch (effectiveStatus) {
        case ChangeStatus.increased:
          color = isDark ? AppColorsDark.increased : AppColors.increased;
          break;
        case ChangeStatus.decreased:
          color = isDark ? AppColorsDark.decreased : AppColors.decreased;
          break;
        case ChangeStatus.unchanged:
          color = isDark ? AppColorsDark.unchanged : AppColors.unchanged;
          break;
      }

      // Get raw coordinates based on axis rotation
      final rawX = settings.rotateAxes ? point.significance : point.foldChange;
      final rawY = settings.rotateAxes ? point.foldChange : point.significance;
      // Apply log scale to Y axis if enabled (or X if rotated)
      final x = settings.rotateAxes ? _transformY(rawX, settings.yLogScale) : rawX;
      final y = settings.rotateAxes ? rawY : _transformY(rawY, settings.yLogScale);

      spots.add(ScatterSpot(
        x,
        y,
        dotPainter: FlDotCirclePainter(
          radius: settings.pointSize,
          color: color.withValues(alpha: settings.opacity),
          strokeWidth: labeledGenes.contains(point.name) ? 1.5 : 0,
          strokeColor: isDark ? Colors.white : Colors.black,
        ),
      ));
    }

    return spots;
  }

  /// Get effective change status based on highlight filter
  /// Filter affects coloring: non-matching significant points show as grey (unchanged)
  /// All points remain visible, but their color changes based on filter
  ChangeStatus _getEffectiveStatus(ChangeStatus status, HighlightFilter filter) {
    switch (filter) {
      case HighlightFilter.all:
        // Show all points with their true colors
        return status;
      case HighlightFilter.changed:
        // Show increased/decreased with colors, unchanged stays grey
        return status;
      case HighlightFilter.up:
        // Only increased points get color, others show as grey
        return status == ChangeStatus.increased ? status : ChangeStatus.unchanged;
      case HighlightFilter.down:
        // Only decreased points get color, others show as grey
        return status == ChangeStatus.decreased ? status : ChangeStatus.unchanged;
    }
  }

  FlTitlesData _buildTitlesData(PlotSettings settings, Color textColor) {
    final textScale = settings.textScale;
    final baseFontSize = 12.0 * textScale;
    final tickFontSize = (10 * textScale).toDouble();

    // Helper to check if a tick value should be skipped (at exact min/max boundary)
    bool shouldSkipBoundaryTick(double value, TitleMeta meta) {
      final range = meta.max - meta.min;
      final tolerance = range * 0.01; // 1% tolerance
      return (value - meta.min).abs() < tolerance ||
          (value - meta.max).abs() < tolerance;
    }

    // Get axis labels - show if not empty (controlled via left panel)
    // When rotated: left shows X label, bottom shows Y label
    final leftAxisLabel = settings.rotateAxes
        ? settings.effectiveXAxisLabel
        : settings.effectiveYAxisLabel;
    final bottomAxisLabel = settings.rotateAxes
        ? settings.effectiveYAxisLabel
        : settings.effectiveXAxisLabel;

    // Check if labels should be shown (based on whether xAxisLabel/yAxisLabel is set)
    // If null, use default. If empty string, hide.
    final showLeftLabel = settings.rotateAxes
        ? (settings.xAxisLabel == null || settings.xAxisLabel!.isNotEmpty)
        : (settings.yAxisLabel == null || settings.yAxisLabel!.isNotEmpty);
    final showBottomLabel = settings.rotateAxes
        ? (settings.yAxisLabel == null || settings.yAxisLabel!.isNotEmpty)
        : (settings.xAxisLabel == null || settings.xAxisLabel!.isNotEmpty);

    return FlTitlesData(
      leftTitles: AxisTitles(
        axisNameSize: 24,  // Space for axis label text
        axisNameWidget: showLeftLabel
            ? Text(
                leftAxisLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: baseFontSize,
                ),
              )
            : const SizedBox.shrink(),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,  // Space for tick labels
          getTitlesWidget: (value, meta) {
            // Skip ticks at exact boundaries to avoid duplication
            if (shouldSkipBoundaryTick(value, meta)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: textColor,
                  fontSize: tickFontSize,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        axisNameSize: 24,  // Space for axis label text
        axisNameWidget: showBottomLabel
            ? Text(
                bottomAxisLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: baseFontSize,
                ),
              )
            : const SizedBox.shrink(),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,  // Space for tick labels
          getTitlesWidget: (value, meta) {
            // Skip ticks at exact boundaries to avoid duplication
            if (shouldSkipBoundaryTick(value, meta)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: textColor,
                  fontSize: tickFontSize,
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildLabelsOverlay(
    VolcanoData data,
    PlotSettings settings,
    Set<String> labeledGenes,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final points = data.currentGroupPoints
            .where((p) => labeledGenes.contains(p.name))
            .toList();

        if (points.isEmpty) return const SizedBox.shrink();

        final bounds = data.getDataBounds();
        final minX = settings.xMin ?? bounds.minX;
        final maxX = settings.xMax ?? bounds.maxX;

        // Calculate Y bounds - use transformed bounds for log scale
        double minY;
        double maxY;
        if (settings.yLogScale && settings.yMin == null && settings.yMax == null) {
          final yBounds = _calculateTransformedYBounds(data.currentGroupPoints);
          minY = yBounds.min;
          maxY = yBounds.max;
        } else {
          final rawMinY = settings.yMin ?? bounds.minY;
          final rawMaxY = settings.yMax ?? bounds.maxY;
          minY = _transformY(rawMinY, settings.yLogScale);
          maxY = _transformY(rawMaxY, settings.yLogScale);
        }

        // External Padding around the fl_chart widget
        const leftPadding = 60.0;
        const rightPadding = 16.0;
        const topPadding = 16.0;
        const bottomPadding = 56.0;

        // fl_chart's internal margins for axis titles and tick labels
        // These must match the values in _buildTitlesData:
        // - leftTitles: axisNameSize (24) + reservedSize (36) = 60
        // - bottomTitles: axisNameSize (24) + reservedSize (24) = 48
        const flChartLeftMargin = 60.0;
        const flChartBottomMargin = 48.0;

        // Calculate the actual plotting area in global coordinates
        final chartLeft = leftPadding + flChartLeftMargin;
        final chartTop = topPadding;
        final chartRight = constraints.maxWidth - rightPadding;
        final chartBottom = constraints.maxHeight - bottomPadding - flChartBottomMargin;
        final chartWidth = chartRight - chartLeft;
        final chartHeight = chartBottom - chartTop;

        final rangeX = settings.rotateAxes ? (maxY - minY) : (maxX - minX);
        final rangeY = settings.rotateAxes ? (maxX - minX) : (maxY - minY);
        final chartMinX = settings.rotateAxes ? minY : minX;
        final chartMinY = settings.rotateAxes ? minX : minY;

        // Calculate positions for ALL data points (for label-point collision)
        final allPoints = data.currentGroupPoints;
        final allPointPositions = <Offset>[];
        for (final point in allPoints) {
          // Get raw coordinates and apply log scale transformation to significance
          final rawPx = settings.rotateAxes ? point.significance : point.foldChange;
          final rawPy = settings.rotateAxes ? point.foldChange : point.significance;
          final px = settings.rotateAxes ? _transformY(rawPx, settings.yLogScale) : rawPx;
          final py = settings.rotateAxes ? rawPy : _transformY(rawPy, settings.yLogScale);
          final pointX = chartLeft + ((px - chartMinX) / rangeX) * chartWidth;
          final pointY = chartTop + chartHeight - ((py - chartMinY) / rangeY) * chartHeight;
          allPointPositions.add(Offset(pointX, pointY));
        }

        // Calculate label positions for labeled genes
        final labelData = <_LabelData>[];
        final fontSize = (10 * settings.textScale).toDouble();

        for (final point in points) {
          // Get raw coordinates and apply log scale transformation to significance
          final rawPx = settings.rotateAxes ? point.significance : point.foldChange;
          final rawPy = settings.rotateAxes ? point.foldChange : point.significance;
          final px = settings.rotateAxes ? _transformY(rawPx, settings.yLogScale) : rawPx;
          final py = settings.rotateAxes ? rawPy : _transformY(rawPy, settings.yLogScale);

          final pointX = chartLeft + ((px - chartMinX) / rangeX) * chartWidth;
          final pointY = chartTop + chartHeight - ((py - chartMinY) / rangeY) * chartHeight;

          // Estimate label size
          final labelWidth = point.name.length * fontSize * 0.6 + 8;
          final labelHeight = fontSize + 4;

          // Initial nudge (like ggrepel's nudge_x and nudge_y)
          const nudgeX = 12.0;
          const nudgeY = -12.0;

          labelData.add(_LabelData(
            name: point.name,
            pointX: pointX,
            pointY: pointY,
            labelX: pointX + nudgeX,
            labelY: pointY + nudgeY,
            width: labelWidth,
            height: labelHeight,
          ));
        }

        // Apply label repulsion algorithm with all point positions
        _repelLabels(
          labelData,
          allPointPositions,
          chartLeft - 20,  // Allow labels to extend slightly into margin
          chartTop,
          chartRight + 10,
          chartBottom,
        );

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LabelsPainter(
            labels: labelData,
            fontSize: fontSize,
            isDark: isDark,
          ),
        );
      },
    );
  }

  /// Label repulsion algorithm inspired by ggrepel
  /// Repels labels from each other AND from all data points
  void _repelLabels(
    List<_LabelData> labels,
    List<Offset> allPoints,
    double minX,
    double minY,
    double maxX,
    double maxY,
  ) {
    const iterations = 100;  // More iterations for better convergence
    const padding = 4.0;     // box.padding equivalent
    const pointPadding = 12.0;  // point.padding - distance to keep from data points
    const pointRadius = 6.0;    // Approximate radius of data points

    for (var iter = 0; iter < iterations; iter++) {
      var moved = false;

      for (var i = 0; i < labels.length; i++) {
        var dx = 0.0;
        var dy = 0.0;

        final labelI = labels[i];
        final rectI = Rect.fromLTWH(
          labelI.labelX - padding,
          labelI.labelY - padding,
          labelI.width + padding * 2,
          labelI.height + padding * 2,
        );

        // Repel from other labels
        for (var j = 0; j < labels.length; j++) {
          if (i == j) continue;

          final labelJ = labels[j];
          final rectJ = Rect.fromLTWH(
            labelJ.labelX - padding,
            labelJ.labelY - padding,
            labelJ.width + padding * 2,
            labelJ.height + padding * 2,
          );

          if (rectI.overlaps(rectJ)) {
            final overlapX = _overlapAmount(
              rectI.left, rectI.right,
              rectJ.left, rectJ.right,
            );
            final overlapY = _overlapAmount(
              rectI.top, rectI.bottom,
              rectJ.top, rectJ.bottom,
            );

            if (overlapX.abs() < overlapY.abs()) {
              dx += overlapX * 0.5;
            } else {
              dy += overlapY * 0.5;
            }
          }
        }

        // Repel from ALL data points (not just own point)
        for (final point in allPoints) {
          // Check if label rectangle overlaps with or is too close to this point
          final expandedRect = Rect.fromLTWH(
            labelI.labelX - pointPadding,
            labelI.labelY - pointPadding,
            labelI.width + pointPadding * 2,
            labelI.height + pointPadding * 2,
          );

          if (expandedRect.contains(point)) {
            // Calculate push direction from point to label center
            final labelCenterX = labelI.labelX + labelI.width / 2;
            final labelCenterY = labelI.labelY + labelI.height / 2;

            final dirX = labelCenterX - point.dx;
            final dirY = labelCenterY - point.dy;
            final dist = math.sqrt(dirX * dirX + dirY * dirY);

            if (dist > 0.1) {
              // Normalize and apply push force
              final force = (pointPadding + pointRadius) / math.max(dist, 1.0);
              dx += (dirX / dist) * force * 2;
              dy += (dirY / dist) * force * 2;
            } else {
              // Point is at label center, push in initial nudge direction
              dx += 8.0;
              dy -= 8.0;
            }
          }
        }

        // Apply movement with damping
        if (dx.abs() > 0.3 || dy.abs() > 0.3) {
          labels[i] = _LabelData(
            name: labelI.name,
            pointX: labelI.pointX,
            pointY: labelI.pointY,
            labelX: (labelI.labelX + dx * 0.8).clamp(minX, maxX - labelI.width),
            labelY: (labelI.labelY + dy * 0.8).clamp(minY, maxY - labelI.height),
            width: labelI.width,
            height: labelI.height,
          );
          moved = true;
        }
      }

      if (!moved) break;
    }
  }

  double _overlapAmount(double min1, double max1, double min2, double max2) {
    if (max1 < min2 || max2 < min1) return 0;
    final center1 = (min1 + max1) / 2;
    final center2 = (min2 + max2) / 2;
    final overlap = math.min(max1, max2) - math.max(min1, min2);
    return center1 < center2 ? -overlap : overlap;
  }

  Widget _buildTooltip(GeneDataPoint point, Offset position, bool isDark) {
    return Positioned(
      left: position.dx + 16,
      top: position.dy - 40,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gene: ${point.name}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fold Change: ${point.foldChange.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              'Significance: ${point.significance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Legend panel positioned in the right margin area (outside the chart grid)
  Widget _buildLegendPanel(
    BuildContext context,
    PlotSettingsProvider settingsProvider,
    bool isDark,
  ) {
    final unchangedColor = isDark ? AppColorsDark.unchanged : AppColors.unchanged;
    final increasedColor = isDark ? AppColorsDark.increased : AppColors.increased;
    final decreasedColor = isDark ? AppColorsDark.decreased : AppColors.decreased;
    final textColor = isDark ? Colors.white : Colors.black;
    final filter = settingsProvider.settings.highlightFilter;

    // Build legend items based on current filter
    final legendItems = <Widget>[];

    switch (filter) {
      case HighlightFilter.all:
      case HighlightFilter.changed:
        // Show all three categories
        legendItems.add(_legendItem('Unchanged', unchangedColor, textColor));
        legendItems.add(_legendItem('Increased', increasedColor, textColor));
        legendItems.add(_legendItem('Decreased', decreasedColor, textColor));
        break;
      case HighlightFilter.up:
        // Only increased is colored, rest are "Other"
        legendItems.add(_legendItem('Other', unchangedColor, textColor));
        legendItems.add(_legendItem('Increased', increasedColor, textColor));
        break;
      case HighlightFilter.down:
        // Only decreased is colored, rest are "Other"
        legendItems.add(_legendItem('Other', unchangedColor, textColor));
        legendItems.add(_legendItem('Decreased', decreasedColor, textColor));
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Legend',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: textColor,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => settingsProvider.setShowLegend(false),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...legendItems,
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(
    FlTouchEvent event,
    ScatterTouchResponse? response,
    VolcanoData data,
    PlotSettings settings,
  ) {
    if (event is FlPointerHoverEvent || event is FlPanUpdateEvent) {
      if (response?.touchedSpot != null) {
        final spotIndex = response!.touchedSpot!.spotIndex;
        final points = data.currentGroupPoints;
        if (spotIndex >= 0 && spotIndex < points.length) {
          setState(() {
            _hoveredPoint = points[spotIndex];
            _hoverPosition = event.localPosition;
          });
          widget.onPointHover?.call(_hoveredPoint);
          return;
        }
      }
    }

    if (event is FlPointerExitEvent || event is FlPanEndEvent) {
      setState(() {
        _hoveredPoint = null;
        _hoverPosition = null;
      });
      widget.onPointHover?.call(null);
      return;
    }

    if (event is FlTapUpEvent) {
      if (response?.touchedSpot != null) {
        final spotIndex = response!.touchedSpot!.spotIndex;
        final points = data.currentGroupPoints;
        if (spotIndex >= 0 && spotIndex < points.length) {
          widget.onPointTap?.call(points[spotIndex]);
        }
      }
    }
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1.0;

    final magnitude = math.pow(10, (math.log(range) / math.ln10).floor()).toDouble();
    final normalized = range / magnitude;

    if (normalized <= 2) return magnitude / 4;
    if (normalized <= 5) return magnitude / 2;
    return magnitude;
  }
}

/// Custom painter for drawing threshold lines
class ThresholdLinesPainter extends CustomPainter {
  final PlotSettings settings;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final bool isDark;

  ThresholdLinesPainter({
    required this.settings,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final thresholdColor = isDark ? AppColorsDark.thresholdLine : AppColors.thresholdLine;
    final paint = Paint()
      ..color = thresholdColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Chart area (fl_chart uses axisNameSize + reservedSize for margins)
    // Left: axisNameSize (24) + reservedSize (36) = 60
    // Bottom: axisNameSize (24) + reservedSize (24) = 48
    const leftAxisWidth = 60.0;
    const bottomAxisHeight = 48.0;
    final chartLeft = leftAxisWidth;
    final chartRight = size.width;
    final chartTop = 0.0;
    final chartBottom = size.height - bottomAxisHeight;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;

    // Helper to convert data coordinates to canvas coordinates
    double xToCanvas(double x) => chartLeft + ((x - minX) / rangeX) * chartWidth;
    double yToCanvas(double y) => chartBottom - ((y - minY) / rangeY) * chartHeight;

    // Create dashed path
    Path createDashedPath(Offset start, Offset end) {
      final path = Path();
      const dashWidth = 5.0;
      const dashSpace = 5.0;
      final distance = (end - start).distance;
      final direction = (end - start) / distance;

      var current = 0.0;
      var isDrawing = true;

      path.moveTo(start.dx, start.dy);

      while (current < distance) {
        final segmentLength = isDrawing ? dashWidth : dashSpace;
        final nextCurrent = math.min(current + segmentLength, distance);
        final point = start + direction * nextCurrent;

        if (isDrawing) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
        }

        current = nextCurrent;
        isDrawing = !isDrawing;
      }

      return path;
    }

    // Helper to apply log scale transformation
    double transformY(double y) {
      if (!settings.yLogScale || y <= 0) return y;
      return math.log(y) / math.ln10;
    }

    if (!settings.rotateAxes) {
      // Draw horizontal significance threshold line
      final sigY = yToCanvas(transformY(settings.significanceThreshold));
      if (sigY >= chartTop && sigY <= chartBottom) {
        canvas.drawPath(
          createDashedPath(
            Offset(chartLeft, sigY),
            Offset(chartRight, sigY),
          ),
          paint,
        );
      }

      // Draw vertical fold change threshold lines
      final fcMinX = xToCanvas(settings.fcMin);
      if (fcMinX >= chartLeft && fcMinX <= chartRight) {
        canvas.drawPath(
          createDashedPath(
            Offset(fcMinX, chartTop),
            Offset(fcMinX, chartBottom),
          ),
          paint,
        );
      }

      final fcMaxX = xToCanvas(settings.fcMax);
      if (fcMaxX >= chartLeft && fcMaxX <= chartRight) {
        canvas.drawPath(
          createDashedPath(
            Offset(fcMaxX, chartTop),
            Offset(fcMaxX, chartBottom),
          ),
          paint,
        );
      }
    } else {
      // Rotated axes - significance becomes vertical, fold change becomes horizontal
      final sigX = xToCanvas(transformY(settings.significanceThreshold));
      if (sigX >= chartLeft && sigX <= chartRight) {
        canvas.drawPath(
          createDashedPath(
            Offset(sigX, chartTop),
            Offset(sigX, chartBottom),
          ),
          paint,
        );
      }

      final fcMinY = yToCanvas(settings.fcMin);
      if (fcMinY >= chartTop && fcMinY <= chartBottom) {
        canvas.drawPath(
          createDashedPath(
            Offset(chartLeft, fcMinY),
            Offset(chartRight, fcMinY),
          ),
          paint,
        );
      }

      final fcMaxY = yToCanvas(settings.fcMax);
      if (fcMaxY >= chartTop && fcMaxY <= chartBottom) {
        canvas.drawPath(
          createDashedPath(
            Offset(chartLeft, fcMaxY),
            Offset(chartRight, fcMaxY),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ThresholdLinesPainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.minX != minX ||
        oldDelegate.maxX != maxX ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.isDark != isDark;
  }
}

/// Data class for label positioning
class _LabelData {
  final String name;
  final double pointX;
  final double pointY;
  final double labelX;
  final double labelY;
  final double width;
  final double height;

  const _LabelData({
    required this.name,
    required this.pointX,
    required this.pointY,
    required this.labelX,
    required this.labelY,
    required this.width,
    required this.height,
  });
}

/// Custom painter for drawing labels with connector lines (ggrepel-style)
class _LabelsPainter extends CustomPainter {
  final List<_LabelData> labels;
  final double fontSize;
  final bool isDark;

  _LabelsPainter({
    required this.labels,
    required this.fontSize,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final bgColor = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85);
    final lineColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      fontSize: fontSize,
      color: textColor,
    );

    for (final label in labels) {
      // Calculate label center
      final labelCenterX = label.labelX + label.width / 2;
      final labelCenterY = label.labelY + label.height / 2;

      // Calculate distance from point to label
      final distance = math.sqrt(
        math.pow(labelCenterX - label.pointX, 2) +
        math.pow(labelCenterY - label.pointY, 2),
      );

      // Only draw connector line if label is far enough from point
      if (distance > 15) {
        // Find the edge of the label box closest to the point
        final labelRect = Rect.fromLTWH(
          label.labelX,
          label.labelY,
          label.width,
          label.height,
        );

        final lineEnd = _getLineEndPoint(label.pointX, label.pointY, labelRect);

        canvas.drawLine(
          Offset(label.pointX, label.pointY),
          lineEnd,
          linePaint,
        );
      }

      // Draw label background
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(label.labelX, label.labelY, label.width, label.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, bgPaint);

      // Draw label text
      final textSpan = TextSpan(text: label.name, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(label.labelX + 4, label.labelY + 2),
      );
    }
  }

  /// Find the point on the label rectangle edge closest to the data point
  Offset _getLineEndPoint(double pointX, double pointY, Rect labelRect) {
    final centerX = labelRect.center.dx;
    final centerY = labelRect.center.dy;

    // Direction from label center to point
    final dx = pointX - centerX;
    final dy = pointY - centerY;

    if (dx == 0 && dy == 0) {
      return labelRect.center;
    }

    // Find intersection with rectangle edges
    double t = double.infinity;

    // Check intersection with each edge
    if (dx != 0) {
      // Left edge
      final tLeft = (labelRect.left - centerX) / dx;
      if (tLeft > 0 && tLeft < t) {
        final y = centerY + tLeft * dy;
        if (y >= labelRect.top && y <= labelRect.bottom) t = tLeft;
      }
      // Right edge
      final tRight = (labelRect.right - centerX) / dx;
      if (tRight > 0 && tRight < t) {
        final y = centerY + tRight * dy;
        if (y >= labelRect.top && y <= labelRect.bottom) t = tRight;
      }
    }

    if (dy != 0) {
      // Top edge
      final tTop = (labelRect.top - centerY) / dy;
      if (tTop > 0 && tTop < t) {
        final x = centerX + tTop * dx;
        if (x >= labelRect.left && x <= labelRect.right) t = tTop;
      }
      // Bottom edge
      final tBottom = (labelRect.bottom - centerY) / dy;
      if (tBottom > 0 && tBottom < t) {
        final x = centerX + tBottom * dx;
        if (x >= labelRect.left && x <= labelRect.right) t = tBottom;
      }
    }

    if (t == double.infinity) {
      return labelRect.center;
    }

    return Offset(centerX + t * dx, centerY + t * dy);
  }

  @override
  bool shouldRepaint(covariant _LabelsPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.isDark != isDark;
  }
}
