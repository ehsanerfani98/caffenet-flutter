import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// پالت برند — استخراج‌شده از CSS پله PWA (`--sky #1559de` …).
class CnColors {
  CnColors._();

  static const Color sky = Color(0xFF1559DE);
  static const Color skyDeep = Color(0xFF1147B2);
  static const Color skySoft = Color(0xFFE3EAFC);
  static const Color emerald = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFD1FAE5);
  static const Color amber = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoSoft = Color(0xFFE0E7FF);
  static const Color rose = Color(0xFFE11D48);
  static const Color roseSoft = Color(0xFFFFE4E6);
  static const Color slate = Color(0xFF475569);
  static const Color slateSoft = Color(0xFFF1F5F9);
  static const Color dark = Color(0xFF0F172A);
  static const Color ink = Color(0xFF1E293B);
  static const Color inkSoft = Color(0xFF64748B);
  static const Color line = Color(0xFFE2E8F0);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
}

/// Theme اپ — Material 3، RTL، فونت Peyda، دارک‌مود کامل.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Peyda';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: CnColors.sky,
      brightness: b,
      primary: CnColors.sky,
      secondary: CnColors.indigo,
      error: CnColors.rose,
      surface: isDark ? CnColors.dark : CnColors.card,
    );

    final bg = isDark ? const Color(0xFF0B1220) : CnColors.bg;
    final card = isDark ? const Color(0xFF141E33) : CnColors.card;
    final text = isDark ? Colors.white : CnColors.ink;
    final textSoft = isDark ? const Color(0xFF94A3B8) : CnColors.inkSoft;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      // RTL کل اپ در main.dart تنظیم می‌شود.
      textTheme: TextTheme(
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: text),
        headlineMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: text),
        headlineSmall: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: text),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: text),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
        bodyLarge: TextStyle(fontSize: 15, height: 1.7, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.7, color: text),
        bodySmall: TextStyle(fontSize: 12.5, height: 1.6, color: textSoft),
        labelLarge: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF24324E) : CnColors.line),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF24324E) : CnColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: TextStyle(color: textSoft, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF24324E) : CnColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF24324E) : CnColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CnColors.sky, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CnColors.rose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CnColors.rose, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CnColors.sky,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xFF24324E) : CnColors.skySoft,
          disabledForegroundColor: textSoft,
          minimumSize: const Size.fromHeight(46),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          // web .btn → 13.5px/700 — نزدیک‌ترین معادل فلاتر
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CnColors.sky,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: CnColors.sky),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CnColors.sky,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        // web .chip → پس‌زمینه سفید + حاشیه 1.5px + radius 22 (قرصی)
        backgroundColor: isDark ? const Color(0xFF141E33) : CnColors.card,
        selectedColor: CnColors.skySoft,
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSoft, fontFamily: fontFamily),
        secondaryLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CnColors.skyDeep, fontFamily: fontFamily),
        side: BorderSide(color: isDark ? const Color(0xFF24324E) : CnColors.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      ),
      snackBarTheme: SnackBarThemeData(
        // web .toast → پس‌زمینه --dark، radius 14، پایین صفحه
        behavior: SnackBarBehavior.floating,
        backgroundColor: CnColors.dark,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 16.5, fontWeight: FontWeight.w700, color: text),
        contentTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, height: 1.7, color: text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        // web .sheet → radius 22 بالای شیت + دستگیره 42×4 با رنگ #CBD5E1
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        showDragHandle: true,
        dragHandleColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        dragHandleSize: const Size(42, 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: CnColors.skySoft,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
          fontFamily: fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: text,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? CnColors.sky : textSoft,
        )),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: CnColors.sky),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// توست‌های یکدست اپ — بازسازی دقیق .toast پله:
/// پس‌زمینه --dark، radius 14، آیکون رنگی، پایین صفحه.
class CnSnack {
  CnSnack._();

  static Color _iconColor(String type) => switch (type) {
        'success' => const Color(0xFF34D399), // emerald-400
        'error' => const Color(0xFFFB7185), // rose-400
        'warning' => const Color(0xFFFBBF24), // amber-400
        _ => const Color(0xFF38BDF8), // sky-400
      };

  static IconData _icon(String type) => switch (type) {
        'success' => Icons.check_circle_rounded,
        'error' => Icons.cancel_rounded,
        'warning' => Icons.warning_amber_rounded,
        _ => Icons.info_rounded,
      };

  static void _show(String message, String type, {int seconds = 3}) {
    Get.closeAllSnackbars();
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Icon(_icon(type), size: 17, color: _iconColor(type)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF8FAFC))),
          ),
        ],
      ),
      backgroundColor: CnColors.dark,
      borderRadius: 14,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      duration: Duration(seconds: seconds),
      animationDuration: const Duration(milliseconds: 250),
      snackPosition: SnackPosition.BOTTOM,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }

  static void info(String message) => _show(message, 'info');
  static void success(String message) => _show(message, 'success');
  static void error(String message) => _show(message, 'error', seconds: 4);
  static void warning(String message) => _show(message, 'warning');
}
