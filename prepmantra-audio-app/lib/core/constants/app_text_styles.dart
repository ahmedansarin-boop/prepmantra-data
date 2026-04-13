import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Central typography constants.
/// All sizes follow an 8-pt scale.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    color: AppColors.onBackground,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    color: AppColors.onBackground,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    color: AppColors.onBackground,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    color: AppColors.onBackground,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.onBackground,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.onBackground,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.onSurface,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.primary,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const TextStyle badge = TextStyle(
    color: AppColors.onSurface,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
