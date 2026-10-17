import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

/// استایل‌های متنی با فونت برند — برای موارد خاص خارج از textTheme.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(BuildContext c) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Theme.of(c).colorScheme.onSurface,
      );

  static TextStyle price(BuildContext c, {Color? color}) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color ?? CnColors.sky,
      );

  static TextStyle caption(BuildContext c) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        color: Theme.of(c).colorScheme.onSurface.withOpacity(.55),
      );
}
