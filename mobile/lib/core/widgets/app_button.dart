import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final _Variant _variant;

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  }) : _variant = _Variant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  }) : _variant = _Variant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  }) : _variant = _Variant.ghost;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: switch (_variant) {
        _Variant.primary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: _child(AppColors.onPrimary),
          ),
        _Variant.secondary => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outline),
              shape: const StadiumBorder(),
            ),
            child: _child(AppColors.primary),
          ),
        _Variant.ghost => TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              shape: const StadiumBorder(),
            ),
            child: _child(AppColors.onSurfaceVariant),
          ),
      },
    );
  }

  Widget _child(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

enum _Variant { primary, secondary, ghost }
