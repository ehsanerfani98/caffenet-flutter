import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../controllers/onboarding_controller.dart';
import '../../../core/widgets/common_widgets.dart';

/// Onboarding سه‌اسلایدی (T8.1).
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: controller.finish,
                  child: const Text(Strings.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.controller,
                onPageChanged: controller.onPageChanged,
                itemCount: OnboardingController.pageCount,
                itemBuilder: (c, i) {
                  final item = onboardingItems[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: CnColors.skySoft,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(item.icon, size: 56, color: CnColors.sky),
                        ),
                        const SizedBox(height: 32),
                        Text(item.title, style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(item.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                },
              ),
            ),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    OnboardingController.pageCount,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: controller.page.value == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.page.value == i ? CnColors.sky : CnColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Obx(() => CnButton(
                    label: controller.page.value == OnboardingController.pageCount - 1
                        ? Strings.continueLabel
                        : Strings.next,
                    onPressed: controller.next,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
