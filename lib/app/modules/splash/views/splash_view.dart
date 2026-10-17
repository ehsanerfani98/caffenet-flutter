import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../controllers/splash_controller.dart';

/// Splash — پورت دقیق .splash از CSS پله:
/// پس‌زمینه --bg، لوگوی سفید 96 (radius 26، سایه sky) با انیمیشن floatUp،
/// نام سایت 15/800 با رنگ ink، و اسپینر آبی زیر آن.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SplashController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : CnColors.bg,
      body: Center(
        child: Obx(() => AnimatedOpacity(
              opacity: c.opacity.value,
              duration: const Duration(milliseconds: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // floatUp — نوسان عمودی ۲ ثانیه‌ای (مطابق keyframes پله)
                  const _FloatUp(
                    child: _SplashLogo(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    Strings.appName,
                    style: TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : CnColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const CnSpinner(size: 34),
                ],
              ),
            )),
      ),
    );
  }
}

/// لوگوی اسپلش — سفید 96×96، radius 26، سایه sky 35%.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: CnColors.sky.withOpacity(.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.local_cafe_rounded, size: 52, color: CnColors.sky),
    );
  }
}

/// انیمیشن floatUp — translateY بین 0 و -9 در چرخه ۲ثانیه‌ای.
class _FloatUp extends StatefulWidget {
  const _FloatUp({required this.child});

  final Widget child;

  @override
  State<_FloatUp> createState() => _FloatUpState();
}

class _FloatUpState extends State<_FloatUp> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (c, child) {
        final dy = -9 * math.sin(math.pi * _ctrl.value);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}
