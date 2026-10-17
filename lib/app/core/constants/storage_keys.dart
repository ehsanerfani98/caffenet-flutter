/// کلیدهای ذخیره‌سازی (GetStorage / secure storage) — پیشوند `cn_`.
class StorageKeys {
  StorageKeys._();

  // ── ترجیحات (با logout پاک نمی‌شود) ──
  static const String onboardingDone = 'cn_onboarding_done';
  static const String themeMode = 'cn_theme_mode'; // system|light|dark

  // ── کش L2 (GetStorage با TTL) ──
  static const String cachedUser = 'cn_cached_user';
  static const String settings = 'cn_settings';
  static const String capacity = 'cn_capacity';
  static const String categories = 'cn_categories';
  static const String slider = 'cn_slider';

  // ── draft فرم سفارش (per service) ──
  static String orderDraft(String serviceId) => 'cn_draft_$serviceId';

  // ── پرداخت در جریان (self-healing — T6.5) ──
  static const String pendingPayment = 'cn_pending_payment';

  // ── secure storage (توکن Sanctum — خارج از GetStorage) ──
  static const String token = 'cn_token';
}
