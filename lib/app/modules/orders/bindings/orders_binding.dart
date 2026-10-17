import 'package:get/get.dart';

import '../controllers/orders_controller.dart';

class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OrdersController(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => OrderDetailController(Get.find(), Get.find()), fenix: true);
  }
}
