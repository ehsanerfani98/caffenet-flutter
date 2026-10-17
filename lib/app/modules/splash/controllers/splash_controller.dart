import 'package:get/get.dart';

import '../../../core/cache/kv_cache.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/values/strings.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// Splash — تصمیم اولین مسیر (onboarding? auth? home) + self-healing پرداخت (T1.7/T6.5).
class SplashController extends GetxController {
  SplashController(this._auth, this._kv, this._wallet);

  final AuthService _auth;
  final KvCache _kv;
  final WalletRepository _wallet;

  final scale = 0.7.obs;
  final opacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _animate();
  }

  Future<void> _animate() async {
    await Future.delayed(const Duration(milliseconds: 60));
    scale.value = 1.0;
    opacity.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 900));
    await _decide();
  }

  Future<void> _decide() async {
    // بازیابی نشست ذخیره‌شده (restart → کاربر برمی‌گردد — T3.4).
    await _auth.restore();

    final onboardingDone = _kv.readRaw(StorageKeys.onboardingDone) == true;
    if (!onboardingDone) {
      Get.offAllNamed(Routes.onboarding);
      return;
    }
    if (!_auth.isAuthenticated) {
      Get.offAllNamed(Routes.auth);
      return;
    }

    Get.offAllNamed(Routes.home);

    // پس‌زمینه: رفرش پروفایل + چک پرداخت ناتمام (T6.5 — self-healing بک‌اند).
    Future(() async {
      final authRepo = Get.find<AuthRepository>();
      try {
        await authRepo.refreshMe();
      } catch (_) {
        // 401 ⇒ forceLogout در ApiClient انجام شده؛ بقیه را رد کن.
        if (!_auth.isAuthenticated) return;
      }

      try {
        final pending = await _wallet.checkPendingPayment();
        if (pending == null) return;
        if (pending.isPaid) {
          try {
            await authRepo.refreshMe(); // موجودی تازه
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 700));
          Get.snackbar(Strings.appName, Strings.paymentSuccess,
              snackPosition: SnackPosition.TOP);
        } else if (pending.isFailed) {
          await Future.delayed(const Duration(milliseconds: 700));
          Get.snackbar(Strings.appName, Strings.paymentFailed,
              snackPosition: SnackPosition.TOP);
        }
      } catch (_) {}
    });
  }
}
