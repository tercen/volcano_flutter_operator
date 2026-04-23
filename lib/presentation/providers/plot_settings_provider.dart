import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/plot_settings.dart';

/// Provider for managing volcano plot settings
class PlotSettingsProvider extends ChangeNotifier {
  PlotSettings _settings = const PlotSettings();

  PlotSettings get settings => _settings;

  /// Load persisted preferences (colors, export unit) from localStorage
  Future<void> loadColorPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final inc = prefs.getInt('color_increased');
    final dec = prefs.getInt('color_decreased');
    final unc = prefs.getInt('color_unchanged');
    final unitName = prefs.getString('export_unit');
    final unit = unitName == null
        ? null
        : ExportUnit.values.firstWhere(
            (u) => u.name == unitName,
            orElse: () => _settings.exportUnit,
          );
    if (inc != null || dec != null || unc != null || unit != null) {
      _settings = _settings.copyWith(
        increasedColorValue: inc,
        decreasedColorValue: dec,
        unchangedColorValue: unc,
        exportUnit: unit,
      );
      notifyListeners();
    }
  }

  /// Save color preferences to localStorage
  Future<void> _saveColorPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_increased', _settings.increasedColorValue);
    await prefs.setInt('color_decreased', _settings.decreasedColorValue);
    await prefs.setInt('color_unchanged', _settings.unchangedColorValue);
  }

  /// Save export unit preference to localStorage
  Future<void> _saveExportUnit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('export_unit', _settings.exportUnit.name);
  }

  // Threshold controls
  void setFoldChangeRange(double min, double max) {
    _settings = _settings.copyWith(fcMin: min, fcMax: max);
    notifyListeners();
  }

  void setSignificanceThreshold(double value) {
    _settings = _settings.copyWith(significanceThreshold: value);
    notifyListeners();
  }

  void setHighlightFilter(HighlightFilter filter) {
    _settings = _settings.copyWith(highlightFilter: filter);
    notifyListeners();
  }

  // Top hits controls
  void setRankingCriterion(RankingCriterion criterion) {
    _settings = _settings.copyWith(rankingCriterion: criterion);
    notifyListeners();
  }

  void setTopN(int value) {
    _settings = _settings.copyWith(topN: value);
    notifyListeners();
  }

  void addSelectedGene(String geneName) {
    final newSet = Set<String>.from(_settings.selectedGenes)..add(geneName);
    _settings = _settings.copyWith(selectedGenes: newSet);
    notifyListeners();
  }

  void removeSelectedGene(String geneName) {
    final newSet = Set<String>.from(_settings.selectedGenes)..remove(geneName);
    _settings = _settings.copyWith(selectedGenes: newSet);
    notifyListeners();
  }

  void toggleSelectedGene(String geneName) {
    if (_settings.selectedGenes.contains(geneName)) {
      removeSelectedGene(geneName);
    } else {
      addSelectedGene(geneName);
    }
  }

  void clearSelectedGenes() {
    _settings = _settings.copyWith(selectedGenes: {});
    notifyListeners();
  }

  // Appearance controls
  void setPointSize(double value) {
    _settings = _settings.copyWith(pointSize: value);
    notifyListeners();
  }

  void setOpacity(double value) {
    _settings = _settings.copyWith(opacity: value);
    notifyListeners();
  }

  void setTextScale(double value) {
    _settings = _settings.copyWith(textScale: value);
    notifyListeners();
  }

  void setShowGridlines(bool value) {
    _settings = _settings.copyWith(showGridlines: value);
    notifyListeners();
  }

  void setShowLabels(bool value) {
    _settings = _settings.copyWith(showLabels: value);
    notifyListeners();
  }

  void setShowLegend(bool value) {
    _settings = _settings.copyWith(showLegend: value);
    notifyListeners();
  }

  void resetAppearance() {
    _settings = _settings.resetAppearance();
    _saveColorPreferences();
    notifyListeners();
  }

  // Color controls
  void setIncreasedColor(int colorValue) {
    _settings = _settings.copyWith(increasedColorValue: colorValue);
    _saveColorPreferences();
    notifyListeners();
  }

  void setDecreasedColor(int colorValue) {
    _settings = _settings.copyWith(decreasedColorValue: colorValue);
    _saveColorPreferences();
    notifyListeners();
  }

  void setUnchangedColor(int colorValue) {
    _settings = _settings.copyWith(unchangedColorValue: colorValue);
    _saveColorPreferences();
    notifyListeners();
  }

  // Axis controls - must pass all 4 values to preserve others (copyWith limitation)
  void setXMin(double? value) {
    _settings = _settings.copyWith(
      xMin: value,
      xMax: _settings.xMax,
      yMin: _settings.yMin,
      yMax: _settings.yMax,
    );
    notifyListeners();
  }

  void setXMax(double? value) {
    _settings = _settings.copyWith(
      xMin: _settings.xMin,
      xMax: value,
      yMin: _settings.yMin,
      yMax: _settings.yMax,
    );
    notifyListeners();
  }

  void setYMin(double? value) {
    _settings = _settings.copyWith(
      xMin: _settings.xMin,
      xMax: _settings.xMax,
      yMin: value,
      yMax: _settings.yMax,
    );
    notifyListeners();
  }

  void setYMax(double? value) {
    _settings = _settings.copyWith(
      xMin: _settings.xMin,
      xMax: _settings.xMax,
      yMin: _settings.yMin,
      yMax: value,
    );
    notifyListeners();
  }

  void setYLogScale(bool value) {
    _settings = _settings.copyWith(yLogScale: value);
    notifyListeners();
  }

  void setRotateAxes(bool value) {
    _settings = _settings.copyWith(rotateAxes: value);
    notifyListeners();
  }

  // Label controls - must rebuild directly to allow setting to empty string
  void setTitle(String? value) {
    _settings = PlotSettings(
      fcMin: _settings.fcMin,
      fcMax: _settings.fcMax,
      significanceThreshold: _settings.significanceThreshold,
      highlightFilter: _settings.highlightFilter,
      rankingCriterion: _settings.rankingCriterion,
      topN: _settings.topN,
      selectedGenes: _settings.selectedGenes,
      pointSize: _settings.pointSize,
      opacity: _settings.opacity,
      textScale: _settings.textScale,
      showGridlines: _settings.showGridlines,
      showLabels: _settings.showLabels,
      showLegend: _settings.showLegend,
      increasedColorValue: _settings.increasedColorValue,
      decreasedColorValue: _settings.decreasedColorValue,
      unchangedColorValue: _settings.unchangedColorValue,
      xMin: _settings.xMin,
      xMax: _settings.xMax,
      yMin: _settings.yMin,
      yMax: _settings.yMax,
      yLogScale: _settings.yLogScale,
      rotateAxes: _settings.rotateAxes,
      title: value,
      xAxisLabel: _settings.xAxisLabel,
      yAxisLabel: _settings.yAxisLabel,
      titleEdited: true,
      xAxisLabelEdited: _settings.xAxisLabelEdited,
      yAxisLabelEdited: _settings.yAxisLabelEdited,
      showXAxisLabel: _settings.showXAxisLabel,
      showYAxisLabel: _settings.showYAxisLabel,
      exportWidth: _settings.exportWidth,
      exportHeight: _settings.exportHeight,
      exportUnit: _settings.exportUnit,
      isPanelCollapsed: _settings.isPanelCollapsed,
    );
    notifyListeners();
  }

  void setXAxisLabel(String? value) {
    _settings = PlotSettings(
      fcMin: _settings.fcMin,
      fcMax: _settings.fcMax,
      significanceThreshold: _settings.significanceThreshold,
      highlightFilter: _settings.highlightFilter,
      rankingCriterion: _settings.rankingCriterion,
      topN: _settings.topN,
      selectedGenes: _settings.selectedGenes,
      pointSize: _settings.pointSize,
      opacity: _settings.opacity,
      textScale: _settings.textScale,
      showGridlines: _settings.showGridlines,
      showLabels: _settings.showLabels,
      showLegend: _settings.showLegend,
      increasedColorValue: _settings.increasedColorValue,
      decreasedColorValue: _settings.decreasedColorValue,
      unchangedColorValue: _settings.unchangedColorValue,
      xMin: _settings.xMin,
      xMax: _settings.xMax,
      yMin: _settings.yMin,
      yMax: _settings.yMax,
      yLogScale: _settings.yLogScale,
      rotateAxes: _settings.rotateAxes,
      title: _settings.title,
      xAxisLabel: value,
      yAxisLabel: _settings.yAxisLabel,
      titleEdited: _settings.titleEdited,
      xAxisLabelEdited: true,
      yAxisLabelEdited: _settings.yAxisLabelEdited,
      showXAxisLabel: _settings.showXAxisLabel,
      showYAxisLabel: _settings.showYAxisLabel,
      exportWidth: _settings.exportWidth,
      exportHeight: _settings.exportHeight,
      exportUnit: _settings.exportUnit,
      isPanelCollapsed: _settings.isPanelCollapsed,
    );
    notifyListeners();
  }

  void setYAxisLabel(String? value) {
    _settings = PlotSettings(
      fcMin: _settings.fcMin,
      fcMax: _settings.fcMax,
      significanceThreshold: _settings.significanceThreshold,
      highlightFilter: _settings.highlightFilter,
      rankingCriterion: _settings.rankingCriterion,
      topN: _settings.topN,
      selectedGenes: _settings.selectedGenes,
      pointSize: _settings.pointSize,
      opacity: _settings.opacity,
      textScale: _settings.textScale,
      showGridlines: _settings.showGridlines,
      showLabels: _settings.showLabels,
      showLegend: _settings.showLegend,
      increasedColorValue: _settings.increasedColorValue,
      decreasedColorValue: _settings.decreasedColorValue,
      unchangedColorValue: _settings.unchangedColorValue,
      xMin: _settings.xMin,
      xMax: _settings.xMax,
      yMin: _settings.yMin,
      yMax: _settings.yMax,
      yLogScale: _settings.yLogScale,
      rotateAxes: _settings.rotateAxes,
      title: _settings.title,
      xAxisLabel: _settings.xAxisLabel,
      yAxisLabel: value,
      titleEdited: _settings.titleEdited,
      xAxisLabelEdited: _settings.xAxisLabelEdited,
      yAxisLabelEdited: true,
      showXAxisLabel: _settings.showXAxisLabel,
      showYAxisLabel: _settings.showYAxisLabel,
      exportWidth: _settings.exportWidth,
      exportHeight: _settings.exportHeight,
      exportUnit: _settings.exportUnit,
      isPanelCollapsed: _settings.isPanelCollapsed,
    );
    notifyListeners();
  }

  void setShowXAxisLabel(bool value) {
    _settings = _settings.copyWith(showXAxisLabel: value);
    notifyListeners();
  }

  void setShowYAxisLabel(bool value) {
    _settings = _settings.copyWith(showYAxisLabel: value);
    notifyListeners();
  }

  // Export controls
  void setExportWidth(int value) {
    _settings = _settings.copyWith(exportWidth: value);
    notifyListeners();
  }

  void setExportHeight(int value) {
    _settings = _settings.copyWith(exportHeight: value);
    notifyListeners();
  }

  void setExportUnit(ExportUnit unit) {
    if (_settings.exportUnit == unit) return;
    _settings = _settings.copyWith(exportUnit: unit);
    _saveExportUnit();
    notifyListeners();
  }

  // Panel state
  void togglePanelCollapsed() {
    _settings = _settings.copyWith(isPanelCollapsed: !_settings.isPanelCollapsed);
    notifyListeners();
  }

  void setPanelCollapsed(bool value) {
    _settings = _settings.copyWith(isPanelCollapsed: value);
    notifyListeners();
  }

  // Reset all
  void resetAll() {
    _settings = const PlotSettings();
    notifyListeners();
  }
}
