import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/enums.dart';
import '../../providers/plot_settings_provider.dart';
import '../common/section_header.dart';
import '../common/labeled_slider.dart';
import '../common/labeled_dropdown.dart';

/// Thresholds section with fold change and significance controls
class ThresholdsSection extends StatelessWidget {
  const ThresholdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final settings = settingsProvider.settings;

    return Section(
      title: 'Thresholds',
      icon: Icons.tune,
      children: [
        // Fold Change Range Slider
        LabeledRangeSlider(
          label: 'Fold Change',
          startValue: settings.fcMin,
          endValue: settings.fcMax,
          min: -5.0,
          max: 5.0,
          divisions: 100,
          onChanged: (values) {
            settingsProvider.setFoldChangeRange(
              values.start,
              values.end,
            );
          },
          valueFormatter: (start, end) =>
              '${start.toStringAsFixed(1)} to ${end.toStringAsFixed(1)}',
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Significance Slider
        LabeledSlider(
          label: 'Significance',
          value: settings.significanceThreshold,
          min: 0.0,
          max: 5.0,
          divisions: 50,
          onChanged: settingsProvider.setSignificanceThreshold,
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Highlight Filter Dropdown
        LabeledDropdown<HighlightFilter>(
          label: 'Highlight',
          value: settings.highlightFilter,
          items: HighlightFilter.values,
          itemLabel: (f) => f.displayName,
          onChanged: settingsProvider.setHighlightFilter,
        ),
      ],
    );
  }
}
