import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
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

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
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

    // Sync controllers
    if (_widthController.text != settings.exportWidth.toString()) {
      _widthController.text = settings.exportWidth.toString();
    }
    if (_heightController.text != settings.exportHeight.toString()) {
      _heightController.text = settings.exportHeight.toString();
    }

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
        // Dimensions
        Text('Dimensions (px)', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                controller: _widthController,
                label: 'W',
                onChanged: (v) {
                  if (v != null && v > 0) {
                    settingsProvider.setExportWidth(v);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildDimensionField(
                controller: _heightController,
                label: 'H',
                onChanged: (v) {
                  if (v != null && v > 0) {
                    settingsProvider.setExportHeight(v);
                  }
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
    required String label,
    required ValueChanged<int?> onChanged,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
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
          final parsed = int.tryParse(value);
          onChanged(parsed);
        },
      ),
    );
  }
}
