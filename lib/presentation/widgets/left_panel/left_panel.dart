import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/plot_settings_provider.dart';
import '../../providers/theme_provider.dart';
import 'data_section.dart';
import 'thresholds_section.dart';
import 'top_hits_section.dart';
import 'appearance_section.dart';
import 'axes_section.dart';
import 'export_section.dart';
import 'info_section.dart';

/// Section definition for collapsed icon strip
class _SectionDef {
  final String id;
  final IconData icon;
  final String label;
  final GlobalKey key;

  _SectionDef({
    required this.id,
    required this.icon,
    required this.label,
  }) : key = GlobalKey();
}

/// Left panel containing all control sections
/// Implements Tercen left-panel.md specification
class LeftPanel extends StatefulWidget {
  final Future<void> Function()? onExportPdf;
  final Future<void> Function()? onExportPng;

  const LeftPanel({
    super.key,
    this.onExportPdf,
    this.onExportPng,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  double _panelWidth = AppSpacing.panelWidth;
  final ScrollController _scrollController = ScrollController();

  // Section definitions for collapsed icon strip
  late final List<_SectionDef> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      _SectionDef(id: 'data', icon: Icons.storage, label: 'DATA'),
      _SectionDef(id: 'thresholds', icon: Icons.tune, label: 'THRESHOLDS'),
      _SectionDef(id: 'top_hits', icon: Icons.star, label: 'TOP HITS'),
      _SectionDef(id: 'appearance', icon: Icons.palette, label: 'APPEARANCE'),
      _SectionDef(id: 'axes', icon: Icons.straighten, label: 'AXES'),
      _SectionDef(id: 'export', icon: Icons.download, label: 'EXPORT'),
      _SectionDef(id: 'info', icon: Icons.info_outline, label: 'INFO'),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSectionIconTap(String sectionId, PlotSettingsProvider settingsProvider) {
    if (settingsProvider.settings.isPanelCollapsed) {
      // Expand panel
      settingsProvider.togglePanelCollapsed();

      // Wait for animation to complete, then scroll to section
      Future.delayed(const Duration(milliseconds: 200), () {
        final section = _sections.firstWhere((s) => s.id == sectionId);
        final context = section.key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<PlotSettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isCollapsed = settingsProvider.settings.isPanelCollapsed;
    final isDark = themeProvider.isDarkMode;

    final panelColor = isDark ? AppColorsDark.panelBackground : AppColors.panelBackground;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main panel container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isCollapsed ? AppSpacing.panelCollapsedWidth : _panelWidth,
          decoration: BoxDecoration(
            color: panelColor,
            border: Border(
              right: BorderSide(color: borderColor),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header
              _buildHeader(context, settingsProvider, themeProvider, isDark, isCollapsed),

              // Content area - use LayoutBuilder to detect actual width during animation
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Show collapsed view if actual width is less than minimum needed for expanded content
                    // This prevents overflow during expand animation
                    final showCollapsedView = constraints.maxWidth < 200;

                    if (showCollapsedView) {
                      return _buildCollapsedIconStrip(context, settingsProvider, isDark);
                    }
                    return _buildExpandedContent(context, isDark);
                  },
                ),
              ),

              // Footer with chevron (only when in collapsed view)
              // Use AnimatedSize to smoothly show/hide footer
              _ConditionalFooter(
                isCollapsed: isCollapsed,
                child: _buildCollapsedFooter(context, settingsProvider, isDark),
              ),
            ],
          ),
        ),

        // Resize handle (only when expanded)
        if (!isCollapsed)
          _buildResizeHandle(isDark),
      ],
    );
  }

  /// Header - changes layout based on actual width (not just state)
  /// This prevents overflow during expand/collapse animation
  Widget _buildHeader(
    BuildContext context,
    PlotSettingsProvider settingsProvider,
    ThemeProvider themeProvider,
    bool isDark,
    bool isCollapsed,
  ) {
    final headerColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Container(
      height: AppSpacing.headerHeight,
      color: headerColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Show collapsed header when width is too narrow for expanded content
          final showCollapsedHeader = constraints.maxWidth < 200;
          if (showCollapsedHeader) {
            return _buildCollapsedHeader(settingsProvider);
          }
          return _buildExpandedHeader(settingsProvider, themeProvider);
        },
      ),
    );
  }

  /// Collapsed header - only app icon (centered), clicking expands
  Widget _buildCollapsedHeader(PlotSettingsProvider settingsProvider) {
    return Center(
      child: GestureDetector(
        onTap: settingsProvider.togglePanelCollapsed,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.show_chart,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  /// Expanded header - icon + title + theme toggle + chevron
  Widget _buildExpandedHeader(
    PlotSettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          // App icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.show_chart,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // App title
          const Expanded(
            child: Text(
              'Volcano Plot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Theme toggle - moon (light->dark) or sun (dark->light)
          // Icon shows what you're switching TO
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.white,
              size: 20,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          // Collapse chevron
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 20,
            ),
            onPressed: settingsProvider.togglePanelCollapsed,
            tooltip: 'Collapse panel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// Collapsed icon strip - section icons vertically, clicking expands + scrolls
  Widget _buildCollapsedIconStrip(
    BuildContext context,
    PlotSettingsProvider settingsProvider,
    bool isDark,
  ) {
    final iconColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: _sections.map((section) {
        return Tooltip(
          message: section.label,
          preferBelow: false,
          child: InkWell(
            onTap: () => _onSectionIconTap(section.id, settingsProvider),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                section.icon,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Collapsed footer - chevron to expand
  Widget _buildCollapsedFooter(
    BuildContext context,
    PlotSettingsProvider settingsProvider,
    bool isDark,
  ) {
    final headerColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Container(
      height: AppSpacing.headerHeight,
      color: headerColor,
      child: Center(
        child: IconButton(
          icon: const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 24,
          ),
          onPressed: settingsProvider.togglePanelCollapsed,
          tooltip: 'Expand panel',
        ),
      ),
    );
  }

  /// Expanded content - scrollable sections
  Widget _buildExpandedContent(BuildContext context, bool isDark) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      children: [
        Container(key: _sections[0].key, child: const DataSection()),
        Container(key: _sections[1].key, child: const ThresholdsSection()),
        Container(key: _sections[2].key, child: const TopHitsSection()),
        Container(key: _sections[3].key, child: const AppearanceSection()),
        Container(key: _sections[4].key, child: const AxesSection()),
        Container(
          key: _sections[5].key,
          child: ExportSection(
            onExportPdf: widget.onExportPdf,
            onExportPng: widget.onExportPng,
          ),
        ),
        Container(key: _sections[6].key, child: const InfoSection()),
      ],
    );
  }

  /// Resize handle on right edge - drag to resize panel (280-400px)
  Widget _buildResizeHandle(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final newWidth = _panelWidth + details.delta.dx;
            _panelWidth = newWidth.clamp(
              AppSpacing.panelMinWidth,
              AppSpacing.panelMaxWidth,
            );
          });
        },
        child: Container(
          width: 4,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

/// Helper widget to conditionally show footer based on collapsed state
/// Uses LayoutBuilder internally to detect actual width during animation
class _ConditionalFooter extends StatelessWidget {
  final bool isCollapsed;
  final Widget child;

  const _ConditionalFooter({
    required this.isCollapsed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Show footer when width is collapsed (less than 200px)
        final showFooter = constraints.maxWidth < 200;
        if (showFooter) {
          return child;
        }
        return const SizedBox.shrink();
      },
    );
  }
}
