import 'package:get/get.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// Wallet — موجودی + تراکنش‌ها + شارژ با درگاه (T6.1..T6.4/T6.6 پلن).
class WalletController extends GetxController {
  WalletController(this._wallet, this._auth, this._settings, this._launcher);

  final WalletRepository _wallet;
  final AuthService _auth;
  final SettingsRepository _settings;
  final LauncherService _launcher;

  final txStatus = RxStatus.empty().obs;
  final transactions = <WalletTransactionModel>[].obs;
  final selectedGateway = 'online'.obs;
  final starting = false.obs;

  AppSettings? settings;
  int prefillAmount = 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      prefillAmount = (args['topUpAmount'] as num?)?.toInt() ?? 0;
    }
    loadTransactions();
    Future(() async {
      try {
        settings = await _settings.business();
      } catch (_) {
        settings = _settings.cached;
      }
    });
  }

  int get balance => _auth.user.value?.walletBalance ?? 0;

  /// درگاه‌های مجاز بر اساس فلاگ‌های بک‌اند (T6.6).
  List<({String key, String label, IconData icon})> get availableGateways => [
        (
          key: 'online',
          label: Strings.gatewayOnline,
          icon: Icons.credit_card_outlined,
        ),
        if (settings?.bazaarPayEnabled == true)
          (
            key: 'bazaarpay',
            label: Strings.gatewayBazaarPay,
            icon: Icons.storefront_outlined,
          ),
        // IAP کافه‌بازار (gateway:'bazaar') به‌تعویق — T8.6f (نیاز پلاگین IAP).
      ];

  Future<void> loadTransactions({bool fresh = false}) async {
    if (txStatus.value.isLoading) return;
    txStatus(fresh ? RxStatus.success() : RxStatus.loading());
    try {
      final list = await _wallet.transactions(fresh: fresh);
      transactions.value = list;
      txStatus(transactions.isEmpty ? RxStatus.empty() : RxStatus.success());
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      if (transactions.isNotEmpty) {
        txStatus(RxStatus.success());
        CnSnack.error(e.message);
      } else {
        txStatus(RxStatus.error(e.message));
      }
    }
  }

  Future<void> refreshBalance() async {
    try {
      await Get.find<AuthRepository>().refreshMe();
    } catch (_) {}
  }

  /// گام ۱ جریان §4.4: POST /payments/request → مرورگر خارجی → صفحه polling.
  Future<void> startTopUp(int amount) async {
    if (starting.value) return;
    starting.value = true;
    try {
      final req = await _wallet.requestTopUp(amount, selectedGateway.value);
      final opened = await _launcher.openExternal(req.redirectUrl);
      // حتی اگر مرورگر باز نشد، صفحه polling باز می‌شود (سرور self-healing است).
      Get.toNamed(
        Routes.paymentPending,
        arguments: {'authority': req.authority, 'amount': amount},
      );
      if (!opened) CnSnack.info(Strings.paymentPendingBody);
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    } finally {
      starting.value = false;
    }
  }
}
