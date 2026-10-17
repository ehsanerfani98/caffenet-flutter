import 'package:get/get.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// Checkout — خلاصه سفارش + پرداخت کیف پولی (T5.8 + §4.4 پلن).
class CheckoutController extends GetxController {
  CheckoutController(this._orders, this._auth);

  final OrderRepository _orders;
  final AuthService _auth;

  OrderModel? order;
  final paying = false.obs;

  int get balance => _auth.user.value?.walletBalance ?? 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    order = args is OrderModel ? args : null;
    refreshBalance();
  }

  Future<void> refreshBalance() async {
    try {
      await Get.find<AuthRepository>().refreshMe();
    } catch (_) {}
  }

  Future<void> pay() async {
    final o = order;
    if (o == null) return;
    paying.value = true;
    try {
      final paid = await _orders.payWithWallet(o.id);
      CnSnack.success(Strings.orderPaidSuccess);
      Get.offAllNamed(Routes.tracker, arguments: {'orderId': paid.id});
    } on ApiError catch (e) {
      if (e.isInsufficientWallet) {
        final shortfall = e.payloadInt('shortfall') ?? (o.payable - balance);
        Get.dialog(_shortfallDialog(shortfall));
      } else {
        CnSnack.error(e.message);
      }
    } finally {
      paying.value = false;
    }
  }

  Widget _shortfallDialog(int shortfall) {
    return AlertDialog(
      title: const Text(Strings.insufficientBalanceTitle),
      content: Text(
        '${Strings.insufficientBalanceBody}\n\n${Strings.shortage}: ${Formatters.tomanWithUnit(shortfall)}',
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text(Strings.cancel)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            Get.toNamed(Routes.wallet, arguments: {'topUpAmount': shortfall});
          },
          child: const Text(Strings.topUpNow),
        ),
      ],
    );
  }
}
