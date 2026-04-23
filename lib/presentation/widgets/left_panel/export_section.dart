import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/enums.dart';
import '../../providers/plot_settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../common/section_header.dart';

/// Callback type for export actions
typedef ExportCallback = Future<void> Function();

/// Export section with PDF/PNG download and dimensions
class ExportSection extends StatefulWidget {
  final ExportCallback? onExportPdf;
  final ExportCallback? onExportPng;

  const ExportSection({
    super.key,
    this.onExportPdf,
    this.onExportPng,
  });

  @override
  State<ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends State<ExportSection> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final FocusNode _widthFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  ExportUnit? _lastSyncedUnit;

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _widthFocus.dispose();
    _heightFocus.dispose();
    super.dispose();
  }

  String _formatForUnit(int pixels, ExportUnit unit) {
    switch (unit) {
      case ExportUnit.px:
        return pixels.toString();
      case ExportUnit.cm:
        return (pixels * 2.54 / exportDpi).toStringAsFixed(1);
    }
  }

  int? _parseForUnit(String text, ExportUnit unit) {
    switch (unit) {
      case ExportUnit.px:
        final v = int.tryParse(text.trim());
        return (v != null && v > 0) ? v : null;
      case ExportUnit.cm:
        final v = double.tryParse(text.trim().replaceAll(',', '.'));
        if (v == null || v <= 0) return null;
        return (v * exportDpi / 2.54).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final settings = settingsProvider.settings;
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    // Button colors: white text/icon with violet border in dark mode
    final buttonForeground = isDark ? Colors.white : AppColors.primary;
    final buttonBorder = isDark ? AppColorsDark.primary : AppColors.primary;

    final unit = settings.exportUnit;
    final unitChanged = _lastSyncedUnit != unit;

    // Sync controllers. Skip if the field is focused (user typing), unless
    // the unit just changed, in which case we must re-render the value.
    final expectedWidth = _formatForUnit(settings.exportWidth, unit);
    final expectedHeight = _formatForUnit(settings.exportHeight, unit);
    if (unitChanged || !_widthFocus.hasFocus) {
      if (_widthController.text != expectedWidth) {
        _widthController.text = expectedWidth;
      }
    }
    if (unitChanged || !_heightFocus.hasFocus) {
      if (_heightController.text != expectedHeight) {
        _heightController.text = expectedHeight;
      }
    }
    _lastSyncedUnit = unit;

    // Custom button style: white text/icon, violet border in dark mode
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: buttonForeground,
      side: BorderSide(color: buttonBorder),
    );

    return Section(
      title: 'Export',
      icon: Icons.download,
      children: [
        // Download buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onExportPdf,
                style: buttonStyle,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onExportPng,
                style: buttonStyle,
                icon: const Icon(Icons.image, size: 16),
                label: const Text('PNG'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Unit toggle + dimensions label on one row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dimensions (${unit.displayName})',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(
              height: 28,
              child: SegmentedButton<ExportUnit>(
                style: SegmentedButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: theme.textTheme.bodySmall,
                ),
                segments: const [
                  ButtonSegment(
                    value: ExportUnit.cm,
                    label: Text('cm'),
                  ),
                  ButtonSegment(
                    value: ExportUnit.px,
                    label: Text('px'),
                  ),
                ],
                selected: {unit},
                showSelectedIcon: false,
                onSelectionChanged: (s) => settingsProvider.setExportUnit(s.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                controller: _widthController,
                focusNode: _widthFocus,
                label: 'W',
                unit: unit,
                onChanged: (px) {
                  if (px != null) settingsProvider.setExportWidth(px);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildDimensionField(
                controller: _heightController,
                focusNode: _heightFocus,
                label: 'H',
                unit: unit,
                onChanged: (px) {
                  if (px != null) settingsProvider.setExportHeight(px);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimensionField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required ExportUnit unit,
    required ValueChanged<int?> onChanged,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.numberWithOptions(
          decimal: unit == ExportUnit.cm,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          prefixText: '$label ',
          prefixStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        onChanged: (value) {
          onChanged(_parseForUnit(value, unit));
        },
      ),
    );
  }
}
