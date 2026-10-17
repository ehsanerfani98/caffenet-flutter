/// ثابت‌های عمومی اپ — نام، ابعاد، سقف‌ها.
class AppConstants {
  AppConstants._();

  static const String appName = 'کافی‌نت احسان';
  static const String appNameShort = 'CaffeNet';

  /// اندازه سقف فایل مشتری — مطابق UploadController بک‌اند (۳۰ مگابایت).
  static const int maxUploadBytes = 30 * 1024 * 1024;

  /// پریود Poller وضعیت سفارش فعال (سقف سرور ۱۲/min — ۱۵ثانیه = ۴req/min).
  static const Duration orderPollPeriod = Duration(seconds: 15);

  /// پریود Poller نتیجه پرداخت (بخش 4.4 پلن — هر ۳ ثانیه).
  static const Duration paymentPollPeriod = Duration(seconds: 3);

  /// سقف انتظار نتیجه پرداخت.
  static const Duration paymentPollTimeout = Duration(minutes: 10);

  /// پریود رفرش نشانگر ظرفیت در Home.
  static const Duration capacityPollPeriod = Duration(seconds: 60);

  /// زمان شمارش معکوس کد OTP — مطابق AuthService بک‌اند (TTL دو دقیقه).
  static const int otpCountdownSeconds = 120;

  /// طول کد OTP.
  static const int otpLength = 5;
}
