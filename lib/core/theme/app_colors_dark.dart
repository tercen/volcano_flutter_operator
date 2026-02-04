import 'package:flutter/material.dart';

/// Dark theme colors following Tercen style guide
class AppColorsDark {
  AppColorsDark._();

  // Brand colors - Tercen design tokens (violet for dark mode)
  static const Color primary = Color(0xFF6D28D9);  // primary-dark-base
  static const Color primarySurface = Color(0x266D28D9);  // primary-dark-surface (15% opacity)
  static const Color accent = Color(0xFF6D28D9);
  static const Color link = Color(0xFF2DD4BF);  // link-dark-base (teal for better contrast)
  static const Color textMuted = Color(0xFF9CA3AF);  // neutral-400

  // Background colors
  static const Color background = Color(0xFF202124);
  static const Color surface = Color(0xFF292A2D);
  static const Color panelBackground = Color(0xFF35363A);

  // Text colors
  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF9AA0A6);
  static const Color textDisabled = Color(0xFF5F6368);
  static const Color textOnPrimary = Color(0xFF202124);

  // Border colors
  static const Color border = Color(0xFF5F6368);
  static const Color divider = Color(0xFF3C4043);

  // Volcano plot colors (same as light for visibility)
  static const Color unchanged = Color(0xFF5F6368);
  static const Color increased = Color(0xFF57C981);
  static const Color decreased = Color(0xFF36A2E0);

  // Threshold line color
  static const Color thresholdLine = Color(0xFF9AA0A6);

  // Interactive states
  static const Color hover = Color(0x0AFFFFFF);
  static const Color focus = Color(0x1A8AB4F8);

  // Status colors
  static const Color error = Color(0xFFF28B82);
  static const Color warning = Color(0xFFFDD663);
  static const Color success = Color(0xFF81C995);
}
