import 'package:flutter/material.dart';

/// Light theme colors following Tercen style guide
class AppColors {
  AppColors._();

  // Brand colors - Tercen design tokens
  static const Color primary = Color(0xFF1E40AF);  // primary-base
  static const Color primarySurface = Color(0xFFDBEAFE);  // primary-surface
  static const Color accent = Color(0xFF1E40AF);
  static const Color link = Color(0xFF1E40AF);  // link-base (same as primary in light mode)
  static const Color textMuted = Color(0xFF6B7280);  // neutral-500

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color panelBackground = Color(0xFFF1F3F4);

  // Text colors
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textDisabled = Color(0xFF9AA0A6);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border colors
  static const Color border = Color(0xFFDADCE0);
  static const Color divider = Color(0xFFE8EAED);

  // Volcano plot colors
  static const Color unchanged = Color(0xFF141A1F);
  static const Color increased = Color(0xFF57C981);
  static const Color decreased = Color(0xFF36A2E0);

  // Threshold line color
  static const Color thresholdLine = Color(0xFF5F6368);

  // Interactive states
  static const Color hover = Color(0x0A000000);
  static const Color focus = Color(0x1A1A73E8);

  // Status colors
  static const Color error = Color(0xFFD93025);
  static const Color warning = Color(0xFFF9AB00);
  static const Color success = Color(0xFF1E8E3E);
}
