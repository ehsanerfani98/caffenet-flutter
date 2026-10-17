import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../controllers/splash_controller.dart';

/// Splash view — انیمیشن لوگو + tagline (T1.7).
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SplashController>();
    return Scaffold(
      backgroundColor: CnColors.sky,
      body: Center(
        child: Obx(() => AnimatedOpacity(
              opacity: c.opacity.value,
              duration: const Duration(milliseconds: 700),
              child: AnimatedScale(
                scale: c.scale.value,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: CnColors.dark.withOpacity(.25),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_cafe_rounded,
                          size: 52, color: CnColors.sky),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      Strings.appName,
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        Strings.splashTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 13,
                          height: 1.8,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}
