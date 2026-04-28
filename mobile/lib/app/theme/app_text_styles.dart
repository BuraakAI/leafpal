import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Manrope font — matches Stitch LeafPal design exactly
class AppTextStyles {
  static TextStyle get display => GoogleFonts.manrope(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 41 / 34,
        letterSpacing: -0.02 * 34,
      );

  static TextStyle get headline1 => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 34 / 28,
        letterSpacing: -0.01 * 28,
      );

  static TextStyle get headline2 => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 28 / 22,
        letterSpacing: -0.01 * 22,
      );

  static TextStyle get bodyLg => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 24 / 17,
        letterSpacing: -0.01 * 17,
      );

  static TextStyle get bodyMd => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 21 / 15,
      );

  static TextStyle get button => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        height: 22 / 17,
      );

  static TextStyle get labelCaps => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
      );
}
