import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';

/// Auth دو مرحله‌ای: شماره موبایل → OTP (T3.2/T3.3 پلن).
class AuthController extends GetxController {
  AuthController(this._repo, this._auth);

  final AuthRepository _repo;
  final AuthService _auth;

  // ── مرحله ۱: شماره ──
  final phoneCtrl = TextEditingController();
  final phoneError = Rxn<String>();
  final sending = false.obs;

  // ── مرحله ۲: OTP ──
  final step = 0.obs; // 0 = phone, 1 = otp
  final codeCtrl = TextEditingController();
  final codeError = Rxn<String>();
  final verifying = false.obs;
  final resendIn = 0.obs;
  final savedPhone = ''.obs;
  final testCode = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    phoneCtrl.addListener(() {
      if (phoneError.value != null) phoneError.value = null;
    });
    codeCtrl.addListener(() {
      if (codeError.value != null) codeError.value = null;
    });
  }

  // ── مرحله ۱ ──
  Future<void> sendOtp() async {
    final phone = Validators.normalizePhone(phoneCtrl.text);
    final err = Validators.phone(phone);
    if (err != null) {
      phoneError.value = err;
      return;
    }
    sending.value = true;
    try {
      final res = await _repo.sendOtp(phone);
      savedPhone.value = phone;
      testCode.value = res.testCode; // حالت آزمایشی بک‌اند (smsTestMode)
      step.value = 1;
      _startCountdown();
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.validation) phoneError.value = e.message;
      CnSnack.error(e.message);
    } finally {
      sending.value = false;
    }
  }

  void _startCountdown() {
    resendIn.value = 120;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!Get.isRegistered<AuthController>() || resendIn.value <= 0) return false;
      resendIn.value = resendIn.value - 1;
      return resendIn.value > 0;
    });
  }

  Future<void> resend() async {
    if (resendIn.value > 0) return;
    codeError.value = null;
    codeCtrl.clear();
    await sendOtp();
  }

  void changePhone() {
    step.value = 0;
    codeCtrl.clear();
    testCode.value = null;
  }

  // ── مرحله ۲ ──
  Future<void> verify() async {
    final code = Validators.toLatinDigits(codeCtrl.text.trim());
    final err = Validators.otp(code);
    if (err != null) {
      codeError.value = err;
      return;
    }
    verifying.value = true;
    try {
      await _repo.verifyOtp(savedPhone.value, code);
      Get.offAllNamed(Routes.home); // کش user در ریپو ذخیره شد (T3.4)
    } on ApiError catch (e) {
      codeError.value = e.kind == ApiErrorKind.validation ? e.message : null;
      CnSnack.error(e.message); // 429/403/503 → پیام فارسی سرور عیناً (T3.3)
    } finally {
      verifying.value = false;
    }
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    codeCtrl.dispose();
    super.onClose();
  }
}
