import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/plot_settings.dart';
import '../../providers/plot_settings_provider.dart';
import '../common/section_header.dart';
import '../common/labeled_slider.dart';
import '../common/labeled_checkbox.dart';

/// Predefined color palette for the color picker
const _colorPresets = <Color>[
  Color(0xFFD32F2F), // red
  Color(0xFFE53935), // red lighter
  Color(0xFFC62828), // red darker
  Color(0xFFFF5722), // deep orange
  Color(0xFFFF9800), // orange
  Color(0xFF388E3C), // green
  Color(0xFF4CAF50), // green lighter
  Color(0xFF2E7D32), // green darker
  Color(0xFF00897B), // teal
  Color(0xFF1E40AF), // blue
  Color(0xFF2563EB), // blue lighter
  Color(0xFF1565C0), // blue darker
  Color(0xFF7B1FA2), // purple
  Color(0xFF6B7280), // grey
  Color(0xFF9E9E9E), // grey lighter
  Color(0xFF424242), // grey darker
  Color(0xFF000000), // black
];

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
        const SizedBox(height: AppSpacing.md),
        // Plot Colors sub-section
        Text(
          'Plot Colors',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildColorRow(
          label: 'Increased',
          color: Color(settings.increasedColorValue),
          onColorChanged: (color) =>
              settingsProvider.setIncreasedColor(color.toARGB32()),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildColorRow(
          label: 'Decreased',
          color: Color(settings.decreasedColorValue),
          onColorChanged: (color) =>
              settingsProvider.setDecreasedColor(color.toARGB32()),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildColorRow(
          label: 'Unchanged',
          color: Color(settings.unchangedColorValue),
          onColorChanged: (color) =>
              settingsProvider.setUnchangedColor(color.toARGB32()),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Reset button (resets sliders and colors above)
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

  Widget _buildColorRow({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorChanged,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        GestureDetector(
          onTap: () => _showColorPickerDialog(color, onColorChanged),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Show hex value
        Text(
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showColorPickerDialog(Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => _ColorPickerDialog(
        currentColor: currentColor,
        presets: _colorPresets,
        onColorSelected: onColorChanged,
      ),
    );
  }
}

/// Simple color picker dialog with preset swatches and hex input
class _ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final List<Color> presets;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.currentColor,
    required this.presets,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selected;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentColor;
    _hexController = TextEditingController(
      text: _colorToHex(_selected),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).substring(2).toUpperCase();
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 6) {
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Color'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selected,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      prefixText: '#',
                      labelText: 'Hex color',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final color = _hexToColor(value);
                      if (color != null) {
                        setState(() => _selected = color);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Preset swatches
            const Text('Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.presets.map((color) {
                final isSelected = color.toARGB32() == _selected.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selected = color;
                      _hexController.text = _colorToHex(color);
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(_selected);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
