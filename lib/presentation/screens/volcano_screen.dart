import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../providers/plot_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/volcano_data_provider.dart';
import '../widgets/left_panel/left_panel.dart';
import '../widgets/volcano_plot/volcano_chart.dart';

/// Main screen containing the volcano plot app
class VolcanoScreen extends StatefulWidget {
  const VolcanoScreen({super.key});

  @override
  State<VolcanoScreen> createState() => _VolcanoScreenState();
}

class _VolcanoScreenState extends State<VolcanoScreen> {
  final GlobalKey _chartKey = GlobalKey();
  bool _showTopBar = false;

  @override
  void initState() {
    super.initState();
    _detectContext();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoDataProvider>().loadData();
    });
  }

  void _detectContext() {
    // Show top bar when NOT embedded (no taskId in URL = full screen mode)
    if (kIsWeb) {
      final uri = Uri.base;
      _showTopBar = !uri.queryParameters.containsKey('taskId');
    } else {
      // Not web, show top bar
      _showTopBar = true;
    }
  }

  void _closeApp() {
    // In web, close the window/tab
    // For now, just show a message since window.close() may be blocked
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Close action triggered'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final settings = context.read<PlotSettingsProvider>().settings;
    final image = await _captureChart();
    if (image == null) return;

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(image);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          settings.exportWidth.toDouble(),
          settings.exportHeight.toDouble(),
        ),
        build: (context) => pw.Center(
          child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'volcano_plot.pdf',
    );
  }

  Future<void> _exportPng() async {
    final image = await _captureChart();
    if (image == null) return;

    await Printing.sharePdf(
      bytes: image,
      filename: 'volcano_plot.png',
    );
  }

  Future<Uint8List?> _captureChart() async {
    try {
      final boundary = _chartKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final settings = context.read<PlotSettingsProvider>().settings;
      final pixelRatio = settings.exportWidth / boundary.size.width;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing chart: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          // Left panel
          LeftPanel(
            onExportPdf: _exportPdf,
            onExportPng: _exportPng,
          ),
          // Main panel (top bar + content)
          Expanded(
            child: Column(
              children: [
                // Top bar - only when NOT embedded (full screen mode)
                if (_showTopBar) _buildTopBar(context, isDark),
                // Main content area - volcano plot with margins
                Expanded(
                  child: Container(
                    color: isDark ? AppColorsDark.background : AppColors.background,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: RepaintBoundary(
                        key: _chartKey,
                        child: Container(
                          color: Colors.white,
                          child: VolcanoChart(
                            onPointTap: (point) {
                              settingsProvider.toggleSelectedGene(point.name);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top bar per Tercen app-frame.md spec:
  /// - Position: Top of main panel (NOT spanning full width)
  /// - Height: 48px (topBarHeight)
  /// - Background: surface color with bottom border
  /// - Content: "FULL SCREEN MODE" badge left, close button right
  Widget _buildTopBar(BuildContext context, bool isDark) {
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final primarySurfaceColor = isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;
    final textMutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    // Badge text color: white on primary-dark-surface (dark), primary-base on primary-surface (light)
    // Per visual-style-dark.md: "Text on Primary Backgrounds" section
    final badgeTextColor = isDark ? Colors.white : AppColors.primary;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Context badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primarySurfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'FULL SCREEN MODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: badgeTextColor,
              ),
            ),
          ),
          const Spacer(),
          // Close button
          IconButton(
            icon: Icon(Icons.close, color: textMutedColor),
            onPressed: _closeApp,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

}
