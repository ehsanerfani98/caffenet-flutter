import 'package:get/get.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Profile — نمایش کاربر + خروج (T8.2 پلن).
class ProfileController extends GetxController {
  ProfileController(this._auth, this._repo, this._launcher);

  final AuthService _auth;
  final AuthRepository _repo;
  final LauncherService _launcher;

  final refreshing = false.obs;

  Rx<UserModel?> get user => _auth.user;

  @override
  void onInit() {
    super.onInit();
    refreshMe();
  }

  Future<void> refreshMe() async {
    refreshing.value = true;
    try {
      await _repo.refreshMe();
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      // بی‌صدا — کش قبلی نمایش داده می‌شود
    } finally {
      refreshing.value = false;
    }
  }

  Future<void> logout() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text(Strings.logoutConfirmTitle),
      content: const Text(Strings.logoutConfirmBody),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text(Strings.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: CnColors.rose),
          onPressed: () => Get.back(result: true),
          child: const Text(Strings.yes),
        ),
      ],
    ));
    if (ok != true) return;
    await _repo.logout(); // best-effort + پاک‌سازی L2/L3 (T3.5)
    CnSnack.info(Strings.logoutDone);
    Get.offAllNamed(Routes.auth);
  }

  String roleTitle(String role) => switch (role) {
        'admin' => Strings.roleAdmin,
        'operator' => Strings.roleOperator,
        _ => Strings.roleCustomer,
      };
}
