import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Section header widget with icon - sections do NOT collapse internally per Tercen spec
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Container for a section with header and content
class Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const Section({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          icon: icon,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
