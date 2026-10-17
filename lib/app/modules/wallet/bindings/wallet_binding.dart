import 'package:get/get.dart';

import '../controllers/wallet_controller.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WalletController(Get.find(), Get.find(), Get.find(), Get.find()), fenix: true);
  }
}
