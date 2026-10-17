import 'package:get/get.dart';

import '../../../core/cache/kv_cache.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/values/strings.dart';

/// Onboarding سه‌اسلایدی — اولین اجرا (T8.1 پلن).
class OnboardingController extends GetxController {
  OnboardingController(this._kv);

  final KvCache _kv;

  final page = 0.obs;
  final controller = PageController();

  static const int pageCount = 3;

  void onPageChanged(int i) => page.value = i;

  void next() {
    if (page.value < pageCount - 1) {
      controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      finish();
    }
  }

  void finish() {
    _kv.writeJson(StorageKeys.onboardingDone, true);
    Get.offAllNamed(Routes.auth);
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}

/// آیتم‌های ثابت اسلایدها.
const List<({String title, String body, IconData icon})> onboardingItems = [
  (
    title: Strings.onb1Title,
    body: Strings.onb1Body,
    icon: Icons.receipt_long_outlined,
  ),
  (
    title: Strings.onb2Title,
    body: Strings.onb2Body,
    icon: Icons.account_balance_wallet_outlined,
  ),
  (
    title: Strings.onb3Title,
    body: Strings.onb3Body,
    icon: Icons.notifications_active_outlined,
  ),
];
