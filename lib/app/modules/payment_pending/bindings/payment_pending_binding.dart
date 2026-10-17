import 'package:get/get.dart';

import '../controllers/payment_pending_controller.dart';

class PaymentPendingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PaymentPendingController(Get.find()), fenix: true);
  }
}
