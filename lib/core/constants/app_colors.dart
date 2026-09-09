// app_colors.dart — shared color palette & theme design tokens
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand
  static const Color maroon = Color(0xFF6B2737);
  static const Color terracotta = Color(0xFFC1652F);
  static const Color gold = Color(0xFFD4A24E);
  static const Color sandstone = Color(0xFFF5EFE6);

  // Modern Dark Mode Palette (Obsidian & Wine Glass)
  static const Color darkBgTop = Color(0xFF22171B);
  static const Color darkBgMid = Color(0xFF161417);
  static const Color darkBgBottom = Color(0xFF100F12);
  static const Color darkSurface = Color(0xFF231D21);
  static const Color darkSurfaceElevated = Color(0xFF2C2228);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color copperGlow = Color(0xFFE5A17D);
  static const Color crimsonAction = Color(0xFF752433);

  // Modern Light Mode Palette (Warm Pearl & Terracotta)
  static const Color lightBgTop = Color(0xFFFDFBF9);
  static const Color lightBgMid = Color(0xFFF7F1EB);
  static const Color lightBgBottom = Color(0xFFEFE6DE);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFFAF4EE);
  static const Color lightBorder = Color(0xFFE5D8CF);
  static const Color lightTextPrimary = Color(0xFF2B1E22);
  static const Color lightTextSecondary = Color(0xFF706368);
}
