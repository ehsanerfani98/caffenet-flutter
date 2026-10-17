import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/common_widgets.dart';

/// ورود دو مرحله‌ای: شماره موبایل → OTP ۵ خانه (T3.2).
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Obx(() => controller.step.value == 0
                ? _PhoneStep(c: controller)
                : _OtpStep(c: controller)),
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.c});

  final AuthController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: CnColors.skySoft, borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.local_cafe_rounded, size: 40, color: CnColors.sky),
        ),
        const SizedBox(height: 20),
        Text(Strings.loginTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(Strings.loginSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 28),
        Obx(() => CnTextField(
              controller: c.phoneCtrl,
              label: Strings.phoneLabel,
              hint: Strings.phoneHint,
              keyboardType: TextInputType.phone,
              errorText: c.phoneError.value,
              maxLength: 13,
              onChanged: (_) => {},
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩+\s-]')),
              ],
            )),
        const SizedBox(height: 20),
        Obx(() => CnButton(
              label: Strings.sendOtp,
              loading: c.sending.value,
              onPressed: c.sendOtp,
            )),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({required this.c});

  final AuthController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(Strings.otpTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: '${Strings.otpSentTo} ',
            children: [
              TextSpan(
                text: Formatters.digits(c.savedPhone.value),
                style: const TextStyle(fontWeight: FontWeight.w700, color: CnColors.sky),
              ),
              TextSpan(text: ' ${Strings.otpSentToSuffix}'),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 26),
        _OtpBoxes(
          controller: c.codeCtrl,
          onDone: (_) => c.verify(),
          errorText: c.codeError.value,
        ),
        const SizedBox(height: 16),
        Obx(() => c.testCode.value != null
            ? Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Chip(
                  avatar: const Icon(Icons.bug_report_outlined, size: 16, color: CnColors.amber),
                  label: Text('${Strings.testCodeChip} ${c.testCode.value}'),
                  backgroundColor: CnColors.amberSoft,
                  side: BorderSide.none,
                ),
              )
            : const SizedBox.shrink()),
        Obx(() => c.codeError.value != null
            ? Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(c.codeError.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CnColors.rose, fontSize: 13)),
              )
            : const SizedBox.shrink()),
        Obx(() => CnButton(
              label: Strings.otpVerify,
              loading: c.verifying.value,
              onPressed: c.verify,
            )),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => c.resendIn.value > 0
                ? Text(
                    '${Strings.otpResendIn} ${Formatters.num(c.resendIn.value)} ثانیه',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : TextButton(
                    onPressed: c.resend,
                    child: const Text(Strings.otpResend),
                  )),
            const SizedBox(width: 8),
            TextButton(
              onPressed: c.changePhone,
              child: const Text(Strings.otpChangePhone),
            ),
          ],
        ),
      ],
    );
  }
}

/// ۵ خانه OTP — ورودی پنهان با نمایش ارقام فارسی.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.controller, required this.onDone, this.errorText});

  final TextEditingController controller;
  final ValueChanged<String> onDone;
  final String? errorText;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = AppConstants.otpLength;
    return GestureDetector(
      onTap: () => focus.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(len, (i) {
              final text = widget.controller.text;
              final hasChar = text.length > i;
              return Container(
                width: 52,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: widget.errorText != null
                        ? CnColors.rose
                        : hasChar
                            ? CnColors.sky
                            : Theme.of(context).dividerColor,
                    width: hasChar ? 1.6 : 1,
                  ),
                ),
                child: Text(
                  hasChar ? '•' : '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CnColors.sky),
                ),
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: focus,
                keyboardType: TextInputType.number,
                maxLength: len,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  setState(() {});
                  if (v.length == len) widget.onDone(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
