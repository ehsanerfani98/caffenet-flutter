import 'package:get/get.dart';

import '../controllers/order_form_controller.dart';

class OrderFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OrderFormController(Get.find(), Get.find(), Get.find(), Get.find(), Get.find(), Get.find()), fenix: true);
  }
}
