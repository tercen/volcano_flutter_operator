import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/plot_settings_provider.dart';
import '../common/section_header.dart';
import '../common/labeled_checkbox.dart';

/// Scaling section with custom range and log scale controls
class AxesSection extends StatefulWidget {
  const AxesSection({super.key});

  @override
  State<AxesSection> createState() => _AxesSectionState();
}

class _AxesSectionState extends State<AxesSection> {
  final TextEditingController _xMinController = TextEditingController();
  final TextEditingController _xMaxController = TextEditingController();
  final TextEditingController _yMinController = TextEditingController();
  final TextEditingController _yMaxController = TextEditingController();

  @override
  void dispose() {
    _xMinController.dispose();
    _xMaxController.dispose();
    _yMinController.dispose();
    _yMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final settings = settingsProvider.settings;
    final theme = Theme.of(context);

    // Sync controllers
    _syncController(_xMinController, settings.xMin);
    _syncController(_xMaxController, settings.xMax);
    _syncController(_yMinController, settings.yMin);
    _syncController(_yMaxController, settings.yMax);

    return Section(
      title: 'Scaling',
      icon: Icons.zoom_out_map,
      children: [
        // Custom Range header
        Text(
          'Custom Range',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // X axis: label and min/max on same line
        _buildRangeRow(
          label: 'X axis',
          minController: _xMinController,
          maxController: _xMaxController,
          onMinChanged: settingsProvider.setXMin,
          onMaxChanged: settingsProvider.setXMax,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Y axis: label and min/max on same line
        _buildRangeRow(
          label: 'Y axis',
          minController: _yMinController,
          maxController: _yMaxController,
          onMinChanged: settingsProvider.setYMin,
          onMaxChanged: settingsProvider.setYMax,
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Y log scale toggle - compresses high significance values
        LabeledCheckbox(
          label: 'Compress Y (Log scale Y)',
          value: settings.yLogScale,
          onChanged: settingsProvider.setYLogScale,
        ),
      ],
    );
  }

  void _syncController(TextEditingController controller, double? value) {
    final stringValue = value?.toString() ?? '';
    if (controller.text != stringValue && !controller.text.endsWith('.')) {
      // Don't sync while user is typing a decimal
      controller.text = stringValue;
    }
  }

  Widget _buildRangeRow({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
    required ValueChanged<double?> onMinChanged,
    required ValueChanged<double?> onMaxChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildCompactNumberField(
            controller: minController,
            hint: 'min',
            onChanged: onMinChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildCompactNumberField(
            controller: maxController,
            hint: 'max',
            onChanged: onMaxChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNumberField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<double?> onChanged,
  }) {
    return SizedBox(
      height: 28,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            onChanged(null);
          } else {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              onChanged(parsed);
            }
          }
        },
      ),
    );
  }
}
