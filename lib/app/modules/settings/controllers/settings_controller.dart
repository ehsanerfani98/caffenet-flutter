import 'package:get/get.dart';

import '../../../core/cache/kv_cache.dart';
import '../../../core/constants/storage_keys.dart';

/// Settings — تم + لینک‌ها + درباره (T8.2 پلن).
class SettingsController extends GetxController {
  SettingsController(this._kv);

  final KvCache _kv;

  final themeMode = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = '${_kv.readRaw(StorageKeys.themeMode) ?? 'system'}';
  }

  /// تغییر تم فوری با Get.changeThemeMode.
  void setTheme(String mode) {
    themeMode.value = mode;
    _kv.writeJson(StorageKeys.themeMode, mode);
    Get.changeThemeMode(switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    });
  }
}
