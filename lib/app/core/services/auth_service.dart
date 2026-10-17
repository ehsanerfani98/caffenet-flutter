import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';
import '../cache/kv_cache.dart';
import '../constants/storage_keys.dart';

/// سرویس احراز هویت — نگهداری توکن Sanctum (secure storage) + user کش‌شده (L2)
/// + force-logout روی 401 (T1.2 پلن). منطق شبکه در AuthRepository است تا حلقه
/// وابستگی ApiClient ↔ AuthService پیش نیاید.
class AuthService extends GetxService {
  AuthService(this._kv);

  final KvCache _kv;
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isCustomer => user.value?.role == 'customer';

  // ── Boot: بازیابی نشست ذخیره‌شده (restart اپ → کاربر برمی‌گردد — T3.4) ──
  Future<void> restore() async {
    _token = await _secure.read(key: StorageKeys.token);
    final cached = _kv.readJson(StorageKeys.cachedUser);
    if (_token != null && cached != null) {
      user.value = UserModel.fromJson(cached);
    }
  }

  Future<void> setSession(String token, UserModel u) async {
    _token = token;
    user.value = u;
    await _secure.write(key: StorageKeys.token, token);
    _kv.writeJson(StorageKeys.cachedUser, u.toJson());
  }

  /// به‌روزرسانی user کش‌شده (پس از refreshMe یا تغییر موجودی).
  Future<void> updateUser(UserModel u) async {
    user.value = u;
    _kv.writeJson(StorageKeys.cachedUser, u.toJson());
  }

  /// پاک‌سازی کامل نشست + هدایت به auth (داده کاربر L2/L3 هم پاک می‌شود).
  Future<void> forceLogout() async {
    await clear();
    if (Get.currentRoute != '/auth' && Get.currentRoute.isNotEmpty) {
      Get.offAllNamed('/auth');
    }
  }

  /// پاک‌سازی بدون ناوبری (برای logout ارادی که مسیرش را controller هدایت می‌کند).
  Future<void> clear() async {
    _token = null;
    user.value = null;
    try {
      await _secure.delete(key: StorageKeys.token);
    } catch (e) {
      debugPrint('secure storage delete failed: $e');
    }
    _kv.purgeUserData();
  }
}
