import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/common_widgets.dart';

/// ورود دو مرحله‌ای — پورت دقیق Screens.openAuth از auth.js پله:
/// گام ۱: فیلد شماره وسط‌چین + پذیرش صریح قوانین + دریافت کد.
/// گام ۲: info-box + کد ۵رقمی وسط‌چین + تایید سبز + ارسال مجدد با شمارش معکوس.
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
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: CnColors.skySoft, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.person_rounded, size: 36, color: CnColors.skyDeep),
        ),
        const SizedBox(height: 14),
        Text(Strings.loginTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Peyda', fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        Text(Strings.loginSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),

        // هشدار سامانه پیامک غیرفعال (مطابق وب)
        Obx(() => c.smsOff.value
            ? Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CnWarnBox(text: Strings.authSmsOff),
              )
            : const SizedBox.shrink()),

        CnTextField(
          controller: c.phoneCtrl,
          label: Strings.phoneLabel,
          requiredMark: true,
          hint: Strings.phoneHint,
          errorText: c.phoneError.value,
          keyboardType: TextInputType.phone,
          maxLength: 13,
          textAlign: TextAlign.center,
          fontSize: 16,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩+\s-]')),
          ],
        ),
        const SizedBox(height: 12),

        // .terms-consent — پذیرش صریح با لینک زیرخط‌دار آبی
        Obx(() => InkWell(
              onTap: () => c.toggleTerms(!c.termsAccepted.value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: c.termsAccepted.value,
                        onChanged: c.toggleTerms,
                        activeColor: CnColors.sky,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 12,
                              fontWeight: FontWeight.w600, height: 1.85,
                              color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: Strings.authTermsLink,
                              style: const TextStyle(
                                  color: CnColors.sky,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // باز شدن قوانین بدون بستن فرم (مطابق وب)
                                  Get.find<LauncherService>()
                                      .openExternal('${Env.appUrl}/terms');
                                },
                            ),
                            TextSpan(text: Strings.authTermsConsentSuffix),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 14),
        Obx(() => CnButton(
              label: Strings.sendOtp,
              icon: Icons.send_rounded,
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
        // .info-box — «کد تایید به شماره X ارسال شد.»
        CnInfoBox(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                  fontFamily: 'Peyda', fontSize: 12,
                  height: 1.9, color: CnColors.skyDeep),
              children: [
                const TextSpan(text: 'کد تایید به شماره '),
                TextSpan(
                  text: Formatters.digits(c.savedPhone.value),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' ارسال شد.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // کد ۵رقمی — وسط‌چین، ۲۲px، حروف‌چینی گسترده (مطابق وب)
        TextFormField(
          controller: c.codeCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 5,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Peyda', fontSize: 22, letterSpacing: 8),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]')),
          ],
          decoration: InputDecoration(
            hintText: Strings.otpHint,
            errorText: c.codeError.value,
            counterText: '',
          ),
        ),

        // حالت آزمایشی — warn-box + درج خودکار (مطابق وب)
        Obx(() => c.testCode.value != null
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CnWarnBox(
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              fontFamily: 'Peyda', fontSize: 12,
                              height: 1.9,
                              color: Color(0xFF92400E)),
                          children: [
                            const TextSpan(text: '${Strings.authTestCodeBody} '),
                            TextSpan(
                              text: Formatters.digits(c.testCode.value!),
                              style: const TextStyle(
                                  fontSize: 16, letterSpacing: 3,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      CnButtonSm(
                        label: Strings.authTestAutofill,
                        icon: Icons.auto_fix_high_rounded,
                        onPressed: () => c.codeCtrl.text = c.testCode.value!,
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink()),

        const SizedBox(height: 14),
        Obx(() => CnButton(
              label: Strings.otpVerify,
              icon: Icons.check_rounded,
              emerald: true,
              loading: c.verifying.value,
              onPressed: c.verify,
            )),
        const SizedBox(height: 9),

        // ارسال مجدد — ghost با شمارش معکوس ۱۲۰ ثانیه (مطابق وب)
        Obx(() {
          final left = c.resendIn.value;
          return CnButton(
            label: left > 0
                ? '${Strings.otpResend} ${Strings.otpResendIn.split(' ').last} ${Formatters.num(left)}${Strings.otpResendCountdownSuffix}'
                : Strings.otpResend,
            ghost: true,
            onPressed: left > 0 ? null : c.resend,
          );
        }),
        const SizedBox(height: 9),
        CnButton(
          label: Strings.otpChangePhone,
          ghost: true,
          onPressed: c.changePhone,
        ),
      ],
    );
  }
}
