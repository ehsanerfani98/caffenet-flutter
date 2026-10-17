import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// رصد چرخه عمر اپ برای Pollerها (§4.3 پلن: پس‌زمینه → پریود ۶۰ثانیه،
/// foreground → tick فوری). یک Observer سراسری + Rx state.
class LifecycleService extends GetxService with WidgetsBindingObserver {
  final Rx<AppLifecycleState> state = AppLifecycleState.resumed.obs;

  bool get isBackground =>
      state.value == AppLifecycleState.paused ||
      state.value == AppLifecycleState.hidden ||
      state.value == AppLifecycleState.detached;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    state.value = s;
  }
}
