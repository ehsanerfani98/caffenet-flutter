import 'package:get/get.dart';

import '../../core/network/api_error.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../models/user_model.dart';

/// ریپوی احراز هویت — T3.1 پلن. کش نشست در AuthService انجام می‌شود.
class AuthRepository extends GetxService {
  AuthRepository(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  /// ارسال کد OTP → پیام سرور (+testCode در حالت آزمایشی).
  Future<OtpResponse> sendOtp(String phone) async {
    final res = await _api.post(
      'auth/send-otp',
      body: {'phone': phone},
      auth: false,
    );
    final m = (res as Map?)?.cast<String, dynamic>() ?? {};
    return OtpResponse(
      message: '${m['message'] ?? 'کد تایید ارسال شد.'}',
      testCode: m['testCode']?.toString(),
    );
  }

  /// تایید کد با mode:'token' (BE-1) → ذخیره توکن + user در AuthService.
  Future<UserModel> verifyOtp(String phone, String code) async {
    final res = await _api.post(
      'auth/verify-otp',
      body: {'phone': phone, 'code': code, 'mode': 'token'},
      auth: false,
    );
    final m = (res as Map?)?.cast<String, dynamic>() ?? {};
    final token = m['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiError.server('پاسخ سرور فاقد توکن بود؛ دوباره تلاش کنید.');
    }
    final user = UserModel.fromJson(m);
    await _auth.setSession(token, user);
    return user;
  }

  /// رفرش پروفایل/مجوزها (T1.2 — /auth/me).
  Future<UserModel> refreshMe() async {
    final res = await _api.get('auth/me');
    final user = UserModel.fromJson(res);
    await _auth.updateUser(user);
    return user;
  }

  /// خروج — best-effort: حتی با خطای شبکه نشست محلی پاک می‌شود (T3.5).
  Future<void> logout() async {
    try {
      await _api.post('auth/logout');
    } catch (_) {}
    await _auth.clear();
  }
}

class OtpResponse {
  const OtpResponse({required this.message, this.testCode});

  final String message;
  final String? testCode;
}
