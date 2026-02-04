import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/theme_provider.dart';
import '../common/section_header.dart';

/// Info section with GitHub link and attribution
class InfoSection extends StatelessWidget {
  const InfoSection({super.key});

  static const String _commitHash = '7ac145a';
  static const String _repoUrl = 'https://github.com/tercen/volcano_flutter';
  static const String _volcanoserUrl = 'https://github.com/JoachimGoedhart/VolcaNoseR';

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    // Use link color (teal in dark mode, blue in light mode) per visual-style spec
    final linkColor = isDark ? AppColorsDark.link : AppColors.link;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Section(
      title: 'Info',
      icon: Icons.info_outline,
      children: [
        // GitHub row with icon, text, and version link
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.github,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: () => _openUrl(_repoUrl),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'volcano_flutter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: linkColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                onTap: () => _openUrl('$_repoUrl/commit/$_commitHash'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    _commitHash,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: linkColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Attribution text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            children: [
              Text(
                'Based on ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
              ),
              InkWell(
                onTap: () => _openUrl(_volcanoserUrl),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'VolcaNoseR',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: linkColor,
                    ),
                  ),
                ),
              ),
              Text(
                ' by Joachim Goedhart and Martijn Kuijsterburg.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
