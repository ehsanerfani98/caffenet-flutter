import 'package:get/get.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// Orders — لیست با فیلتر وضعیت (T7.2) + جزئیات (T7.3) + تیکت (T7.6) + امتیاز (T7.7).
class OrdersController extends GetxController {
  OrdersController(this._orders, this._auth);

  final OrderRepository _orders;
  final AuthService _auth;

  final status = RxStatus.empty().obs;
  final orders = <OrderModel>[].obs;
  final filter = 'all'.obs;

  /// فیلترهای وب (landing.js orders): همه/در جریان/آماده/تحویل/لغو/عودت.
  static const List<({String key, String label})> filters = [
    (key: 'all', label: Strings.ordersAll),
    (key: 'open', label: Strings.ordersOpen),
    (key: 'ready', label: Strings.ordersReadyFilter),
    (key: 'delivered', label: Strings.ordersDeliveredFilter),
    (key: 'cancelled', label: Strings.ordersCancelledFilter),
    (key: 'refunded', label: Strings.ordersRefundedFilter),
  ];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List<OrderModel> get filtered {
    // پورت renderList() وب: OPEN = pending_payment/submitted/processing (بدون ready)
    if (filter.value == 'all') return orders;
    if (filter.value == 'open') {
      const open = ['pending_payment', 'submitted', 'processing'];
      return orders.where((o) => open.contains(o.status)).toList();
    }
    return orders.where((o) => o.status == filter.value).toList();
  }

  Future<void> load({bool fresh = false}) async {
    if (status.value.isLoading) return;
    status(fresh ? RxStatus.success() : RxStatus.loading());
    try {
      final list = await _orders.list(fresh: fresh);
      orders.value = list;
      status(orders.isEmpty ? RxStatus.empty() : RxStatus.success());
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      if (orders.isNotEmpty) {
        status(RxStatus.success());
        CnSnack.error(e.message);
      } else {
        status(RxStatus.error(e.message));
      }
    }
  }

  void openDetail(String id) => Get.toNamed(Routes.orderDetail, arguments: id);

  void openTracker(String id) =>
      Get.toNamed(Routes.tracker, arguments: {'orderId': id});
}

/// کنترلر جزئیات سفارش.
class OrderDetailController extends GetxController {
  OrderDetailController(this._orders, this._auth);

  final OrderRepository _orders;
  final AuthService _auth;

  late String orderId;
  final order = Rxn<OrderModel>();
  final status = RxStatus.empty().obs;
  final ticketSending = false.obs;
  final ratingSaving = false.obs;
  final ticketCtrl = TextEditingController();
  final rating = 0.obs;
  final reviewCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId = args is String ? args : '${args?['orderId'] ?? ''}';
    load();
  }

  Future<void> load({bool fresh = false}) async {
    status(RxStatus.loading());
    try {
      final o = await _orders.show(orderId, fresh: fresh);
      order.value = o;
      rating.value = o.rating ?? 0;
      reviewCtrl.text = o.reviewComment ?? '';
      status(RxStatus.success());
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      status(RxStatus.error(e.message));
    }
  }

  // ── تیکت (T7.6) ──
  Future<void> sendTicket() async {
    final msg = ticketCtrl.text.trim();
    if (msg.isEmpty) return;
    ticketSending.value = true;
    try {
      await _orders.sendTicket(orderId, msg);
      ticketCtrl.clear();
      await load(fresh: true);
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    } finally {
      ticketSending.value = false;
    }
  }

  // ── امتیاز (T7.7 — فقط delivered و یک‌بار) ──
  bool get canRate =>
      order.value?.status == 'delivered' && (order.value?.rating == null);

  Future<void> saveRating() async {
    if (rating.value == 0) {
      CnSnack.error('امتیاز را انتخاب کنید.');
      return;
    }
    ratingSaving.value = true;
    try {
      await _orders.rate(orderId, rating.value, reviewCtrl.text.trim());
      CnSnack.success(Strings.orderRated);
      await load(fresh: true);
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    } finally {
      ratingSaving.value = false;
    }
  }

  // ── لغو ──
  Future<void> cancel() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text(Strings.orderCancelTitle),
      content: const Text(Strings.orderCancelBody),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text(Strings.cancel)),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CnColors.rose),
            onPressed: () => Get.back(result: true),
            child: const Text(Strings.yes)),
      ],
    ));
    if (ok != true) return;
    try {
      await _orders.cancel(orderId);
      CnSnack.success(Strings.orderCancelSuccess);
      await load(fresh: true);
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    }
  }

  // ── حذف ──
  Future<void> delete() async {
    try {
      await _orders.delete(orderId);
      CnSnack.success(Strings.orderDeleted);
      Get.back();
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    }
  }

  @override
  void onClose() {
    ticketCtrl.dispose();
    reviewCtrl.dispose();
    super.onClose();
  }
}
