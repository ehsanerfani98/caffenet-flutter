import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../controllers/payment_pending_controller.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';

/// صفحه «پرداخت در جریان است» — انیمیشن + تایمر + دکمه بررسی فوری.
class PaymentPendingView extends GetView<PaymentPendingController> {
  const PaymentPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.paymentPendingTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                builder: (c, v, child) => Transform.scale(
                  scale: .8 + .2 * v,
                  child: child,
                ),
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: CnColors.skySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      size: 52, color: CnColors.sky),
                ),
              ),
              const SizedBox(height: 22),
              Text(Strings.paymentPendingTitle,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (controller.amount > 0)
                Text(Formatters.tomanWithUnit(controller.amount),
                    style: AppTextStyles.price(context)),
              const SizedBox(height: 10),
              Text(
                Strings.paymentPendingBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Obx(() => controller.finished.value
                  ? const SizedBox.shrink()
                  : _Elapsed(seconds: controller.elapsed.value)),
              const SizedBox(height: 22),
              Obx(() => CnButton(
                    label: Strings.paymentCheckNow,
                    icon: Icons.refresh,
                    loading: controller.checking.value,
                    onPressed: controller.checkNow,
                  )),
              const SizedBox(height: 10),
              TextButton(
                onPressed: controller.finished.value
                    ? () => Get.offNamed('/wallet')
                    : controller.checkNow,
                child: Text(
                  controller.finished.value
                      ? Strings.back
                      : Strings.paymentReturnToApp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Elapsed extends StatefulWidget {
  const _Elapsed({required this.seconds});

  final int seconds;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  Timer? _t;
  int _s = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _s++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_s ~/ 60).toString().padLeft(2, '0');
    final ss = (_s % 60).toString().padLeft(2, '0');
    final remaining = AppConstants.paymentPollTimeout.inSeconds - _s;
    return Column(
      children: [
        Text('$mm:$ss',
            style: const TextStyle(
                fontFamily: 'Peyda', fontSize: 20, fontWeight: FontWeight.w700,
                color: CnColors.sky)),
        if (remaining > 0)
          Text(
            'حداکثر ${Formatters.durationMinutes((remaining / 60).ceil())} تا بررسی بعدی',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
