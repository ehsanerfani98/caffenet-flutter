/// خواندن تنظیمات زمان کامپایل از `--dart-define`.
///
/// اجرای توسعه:
/// ```
/// flutter run --dart-define=CAFFENET_API_BASE_URL=http://10.0.2.2:8000
/// ```
class Env {
  Env._();

  static const String _baseUrl = String.fromEnvironment('CAFFENET_API_BASE_URL');

  /// لاگ دیباگ شبکه (هرگز توکن لاگ نمی‌شود).
  static const bool debugLog = bool.fromEnvironment('CAFFENET_DEBUG', defaultValue: false);

  /// آدرس پایه سرور — بدون اسلش انتهایی.
  static String get baseUrl {
    final v = _baseUrl.trim();
    if (v.isNotEmpty) {
      return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
    }
    // بدون dart-define: توسعه روی امولاتور اندروید به localhost هاست می‌رود.
    return 'http://10.0.2.2:8000';
  }

  /// آدرس API — همه endpointها زیر همین پیشوند هستند (قرارداد §4 پلن).
  static String get apiBase => '$baseUrl/api';

  /// آدرس وب‌اپ PWA — برای قوانین/حریم خصوصی و لینک اشتراکی پیگیری.
  static String get appUrl => baseUrl;
}
