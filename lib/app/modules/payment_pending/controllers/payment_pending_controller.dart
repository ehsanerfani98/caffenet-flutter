import 'package:get/get.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/poller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// صفحه «پرداخت در جریان است» — Poller ۳ ثانیه روی /payments/status
/// سقف ۱۰ دقیقه (§4.4 پلن — T6.4). سرور idempotent/self-healing است.
class PaymentPendingController extends GetxController {
  PaymentPendingController(this._wallet);

  final WalletRepository _wallet;

  String authority = '';
  int amount = 0;

  final elapsed = 0.obs;
  final checking = false.obs;
  final finished = false.obs; // true = نتیجه قطعی گرفته شد

  Poller? _poller;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      authority = '${args['authority'] ?? ''}';
      amount = (args['amount'] as num?)?.toInt() ?? 0;
    }
    startPolling();
  }

  void startPolling() {
    _poller?.stop();
    _poller = Poller(
      task: _check,
      period: AppConstants.paymentPollPeriod,
      maxPeriod: const Duration(seconds: 15),
    )..start();
  }

  Future<void> _check() async {
    if (finished.value || authority.isEmpty) return;
    elapsed.value += AppConstants.paymentPollPeriod.inSeconds;
    // سقف ۱۰ دقیقه.
    if (elapsed.value >= AppConstants.paymentPollTimeout.inSeconds) {
      _stop(Strings.paymentTimeout, error: true);
      return;
    }
    final st = await _wallet.status(authority);
    if (st.isPaid) {
      _onPaid();
    } else if (st.isFailed) {
      _stop(Strings.paymentFailed, error: true);
    }
    // pending → ادامه polling
  }

  void _onPaid() {
    _poller?.stop();
    finished.value = true;
    _wallet.clearPending();
    CnSnack.success(Strings.paymentSuccess);
    // گام ۵ §4.4: رفرش موجودی → برگشت به wallet.
    Future(() async {
      try {
        await Get.find<AuthRepository>().refreshMe();
      } catch (_) {}
      Future.delayed(const Duration(milliseconds: 900), () {
        if (Get.currentRoute == Routes.paymentPending) {
          Get.offNamed(Routes.wallet);
        }
      });
    });
  }

  void _stop(String message, {required bool error}) {
    _poller?.stop();
    finished.value = true;
    _wallet.clearPending();
    error ? CnSnack.error(message) : CnSnack.info(message);
  }

  /// دکمه «بررسی نتیجه» — fetch فوری خارج از پریود.
  Future<void> checkNow() async {
    if (checking.value || finished.value) return;
    checking.value = true;
    try {
      final st = await _wallet.status(authority);
      if (st.isPaid) {
        _onPaid();
      } else if (st.isFailed) {
        _stop(Strings.paymentFailed, error: true);
      } else {
        CnSnack.info(Strings.paymentPendingBody);
      }
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      CnSnack.error(e.message);
    } finally {
      checking.value = false;
    }
  }

  @override
  void onClose() {
    _poller?.stop();
    super.onClose();
  }
}
