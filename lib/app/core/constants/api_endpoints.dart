/// تک‌منبع حقیقت مسیرهای API — بخش 4.1 پلن (نگاشت ۱:۱ از routes/api.php).
///
/// همه مسیرها نسبی به `{BASE_URL}/api/` هستند.
class ApiEndpoints {
  ApiEndpoints._();

  static const String health = 'health';

  // ── Auth ──
  static const String sendOtp = 'auth/send-otp';
  static const String verifyOtp = 'auth/verify-otp';
  static const String logout = 'auth/logout';
  static const String me = 'auth/me';

  // ── Catalog / settings / slider (public) ──
  static const String settings = 'settings';
  static const String categories = 'categories';
  static const String services = 'services';
  static const String slider = 'slider';

  // ── Capacity ──
  static const String capacityCurrent = 'capacity/current';
  static const String capacitySlots = 'capacity/slots';

  // ── Orders ──
  static const String orders = 'orders';
  static String order(String id) => 'orders/$id';
  static String orderUpdates(String id) => 'orders/$id/updates';
  static String orderPayWallet(String id) => 'orders/$id/pay-wallet';
  static String orderReserve(String id) => 'orders/$id/reserve';
  static String orderNotifyMe(String id) => 'orders/$id/notify-me';
  static String orderCancel(String id) => 'orders/$id/cancel';
  static String orderTicket(String id) => 'orders/$id/ticket';
  static String track(String token) => 'orders/track/$token';

  // ── Payments ──
  static const String paymentRequest = 'payments/request';
  static const String paymentStatus = 'payments/status';
  static String payBazaarPay(String orderId) => 'orders/$orderId/pay-bazaarpay';

  // ── Wallet / coupons ──
  static const String walletTransactions = 'wallet/transactions';
  static const String coupons = 'coupons';
  static const String couponValidate = 'coupons/validate';

  // ── Upload (multipart) ──
  static const String upload = 'upload';

  // ── فایل‌های سفارش با توکن (BE-4) ──
  static String uploadFile(String filename) => 'uploads/$filename';
}
