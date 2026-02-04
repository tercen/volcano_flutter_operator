import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/plot_settings.dart';
import '../../providers/plot_settings_provider.dart';
import '../common/section_header.dart';
import '../common/labeled_slider.dart';
import '../common/labeled_checkbox.dart';

/// Appearance section with point size, opacity, text scale, etc.
class AppearanceSection extends StatefulWidget {
  const AppearanceSection({super.key});

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _xAxisController = TextEditingController();
  final TextEditingController _yAxisController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _xAxisFocus = FocusNode();
  final FocusNode _yAxisFocus = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _xAxisController.dispose();
    _yAxisController.dispose();
    _titleFocus.dispose();
    _xAxisFocus.dispose();
    _yAxisFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final settings = settingsProvider.settings;
    final theme = Theme.of(context);

    // Sync controllers with settings - only when not actively editing (no focus)
    // Three states:
    // - null: default state (title=empty, axes=default text)
    // - '': user cleared (show placeholder)
    // - text: user's custom value
    if (!_titleFocus.hasFocus) {
      _syncController(_titleController, settings.title ?? '');
    }
    if (!_xAxisFocus.hasFocus) {
      // null = default (show default text), '' = cleared (show placeholder)
      final xText = settings.xAxisLabel == null
          ? PlotSettings.defaultXAxisLabel
          : settings.xAxisLabel!;
      _syncController(_xAxisController, xText);
    }
    if (!_yAxisFocus.hasFocus) {
      // null = default (show default text), '' = cleared (show placeholder)
      final yText = settings.yAxisLabel == null
          ? PlotSettings.defaultYAxisLabel
          : settings.yAxisLabel!;
      _syncController(_yAxisController, yText);
    }

    return Section(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        // Point size slider
        LabeledSlider(
          label: 'Point size',
          value: settings.pointSize,
          min: 1.0,
          max: 10.0,
          divisions: 18,
          onChanged: settingsProvider.setPointSize,
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Opacity slider
        LabeledSlider(
          label: 'Opacity',
          value: settings.opacity,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: settingsProvider.setOpacity,
          valueFormatter: (v) => '${(v * 100).round()}%',
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Text scale slider
        LabeledSlider(
          label: 'Text scale',
          value: settings.textScale,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: settingsProvider.setTextScale,
          valueFormatter: (v) => '${(v * 100).round()}%',
        ),
        const SizedBox(height: AppSpacing.sm),
        // Reset button (resets sliders above)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: settingsProvider.resetAppearance,
            child: Text(
              'Reset',
              style: theme.textTheme.labelMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Plot Labels sub-section
        Text(
          'Plot Labels',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Title - empty string means no title
        _buildLabelRow(
          label: 'Title',
          controller: _titleController,
          focusNode: _titleFocus,
          hint: 'Enter title...',
          onChanged: (value) => settingsProvider.setTitle(value.isEmpty ? '' : value),
          isEmptyState: settings.title != null && settings.title!.isEmpty,
        ),
        const SizedBox(height: AppSpacing.xs),
        // X axis - empty string means hide label, value means custom label
        _buildLabelRow(
          label: 'X axis',
          controller: _xAxisController,
          focusNode: _xAxisFocus,
          hint: 'Enter X axis...',
          onChanged: (value) => settingsProvider.setXAxisLabel(value.isEmpty ? '' : value),
          isEmptyState: settings.xAxisLabel != null && settings.xAxisLabel!.isEmpty,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Y axis - empty string means hide label, value means custom label
        _buildLabelRow(
          label: 'Y axis',
          controller: _yAxisController,
          focusNode: _yAxisFocus,
          hint: 'Enter Y axis...',
          onChanged: (value) => settingsProvider.setYAxisLabel(value.isEmpty ? '' : value),
          isEmptyState: settings.yAxisLabel != null && settings.yAxisLabel!.isEmpty,
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Gridlines and Data Labels toggles on same row
        Row(
          children: [
            Expanded(
              child: LabeledCheckbox(
                label: 'Gridlines',
                value: settings.showGridlines,
                onChanged: settingsProvider.setShowGridlines,
              ),
            ),
            Expanded(
              child: LabeledCheckbox(
                label: 'Data Labels',
                value: settings.showLabels,
                onChanged: settingsProvider.setShowLabels,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Rotate axes toggle
        LabeledCheckbox(
          label: 'Rotate axes',
          value: settings.rotateAxes,
          onChanged: settingsProvider.setRotateAxes,
        ),
      ],
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  Widget _buildLabelRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required ValueChanged<String> onChanged,
    bool isEmptyState = false,
  }) {
    final theme = Theme.of(context);

    // When empty state (user cleared), show placeholder in light grey
    // Otherwise show text in normal color (black/dark)
    final textStyle = isEmptyState
        ? TextStyle(fontSize: 12, color: Colors.grey[400])
        : const TextStyle(fontSize: 12);

    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: SizedBox(
            height: 28,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                hintText: hint,
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
