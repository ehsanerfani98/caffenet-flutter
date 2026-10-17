import 'package:get/get.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/api_error.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/lifecycle_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/poller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// Tracker زنده — Poller ۱۵ ثانیه روی /orders/{id}/updates (T7.4)
/// + Local Notification روی تغییر وضعیت (T7.5) + رزرو اسلات + notify-me + لغو.
class TrackerController extends GetxController {
  TrackerController(
    this._orders,
    this._capacity,
    this._auth,
    this._lifecycle,
    this._notif,
  );

  final OrderRepository _orders;
  final CapacityRepository _capacity;
  final AuthService _auth;
  final LifecycleService _lifecycle;
  final LocalNotificationService _notif;

  final order = Rxn<OrderModel>();
  final notifications = <NotificationItem>[].obs;
  final status = RxStatus.empty().obs;
  final isPublic = false.obs;
  final trackToken = ''.obs;

  final slots = <CapacitySlot>[].obs;
  final loadingSlots = false.obs;

  String _lastStatus = '';
  String _orderId = '';

  Poller? _poller;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String) {
      // لینک اشتراکی: token
      isPublic.value = true;
      trackToken.value = args;
      _loadPublic();
    } else if (args is Map) {
      final token = args['token'];
      if (token is String && token.isNotEmpty) {
        isPublic.value = true;
        trackToken.value = token;
        _loadPublic();
        return;
      }
      final oid = args['orderId'];
      if (oid is String && oid.isNotEmpty) {
        _loadOrder(oid, autoStart: args['autoStart'] == true);
      }
    }
  }

  Future<void> _loadOrder(String id, {bool autoStart = false}) async {
    _orderId = id;
    status(RxStatus.loading());
    try {
      final o = await _orders.show(id);
      order.value = o;
      _lastStatus = o.status;
      _lastNotifCount = 0;
      status(RxStatus.success());
      _startPolling();
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      status(RxStatus.error(e.message));
    }
  }

  /// پیگیری عمومی (بدون لاگین — T7.8).
  Future<void> _loadPublic() async {
    status(RxStatus.loading());
    try {
      final res = await _orders.track(trackToken.value);
      order.value = OrderModel.fromJson({
        ...res.order,
        'orderNumber': res.orderNumber,
        'serviceTitle': res.serviceTitle,
      });
      notifications.value = res.notifications;
      _lastStatus = '${res.order['status'] ?? ''}';
      status(RxStatus.success());
    } on ApiError catch (e) {
      status(RxStatus.error(
          e.kind == ApiErrorKind.notFound ? Strings.trackNotFound : e.message));
    }
  }

  /// تلاش مجدد از ویو (retry).
  Future<void> reload() async {
    if (isPublic.value) {
      await _loadPublic();
    } else if (_orderId.isNotEmpty) {
      await _loadOrder(_orderId);
    }
  }

  /// جستجوی توکن در صفحه عمومی.
  Future<void> searchToken(String token) async {
    if (token.trim().isEmpty) return;
    trackToken.value = token.trim();
    await _loadPublic();
  }

  // ── Polling ۱۵ ثانیه (T7.4) ──
  void _startPolling() {
    _poller?.stop();
    _poller = Poller(
      task: _fetchUpdates,
      period: AppConstants.orderPollPeriod,
      maxPeriod: const Duration(seconds: 60),
      onUpdate: _onUpdate,
    )..start();
    // lifecycle: پس‌زمینه → pause؛ foreground → tick فوری.
    _lifecycle.state.listen((s) {
      _poller?.setBackground(s == AppLifecycleState.resumed ? false : true);
    });
  }

  Future<void> _fetchUpdates() async {
    if (isPublic.value) {
      // نسخه عمومی: هر ۳۰ ثانیه همان endpoint track.
      final res = await _orders.track(trackToken.value);
      order.value = OrderModel.fromJson({
        ...res.order,
        'orderNumber': res.orderNumber,
        'serviceTitle': res.serviceTitle,
      });
      notifications.value = res.notifications;
      return;
    }
    final o = order.value;
    if (o == null) return;
    final up = await _orders.updates(o.id);
    final prev = o;
    final next = prev.applyUpdate(up.order.cast<String, dynamic>());
    order.value = next;
    // notifications برای نوتیف محلی (T7.5).
    if (up.notifications.isNotEmpty) notifications.value = up.notifications;
  }

  void _onUpdate() {
    if (isPublic.value) return;
    final o = order.value;
    if (o == null) return;
    // نوتیف محلی روی تغییر وضعیت (T7.5).
    if (_lastStatus.isNotEmpty && o.status != _lastStatus) {
      final payload = switch (o.status) {
        'processing' => (
          title: Strings.notifOrderStarted,
          body: '${o.serviceTitle} — ${Strings.trackerProcessing}'
        ),
        'ready' => (
          title: Strings.notifOrderReady,
          body: '${o.serviceTitle} — ${Strings.trackerReady}'
        ),
        'cancelled' => (title: Strings.notifCancelled, body: o.serviceTitle),
        'submitted' when _lastStatus == 'processing' => (
          title: Strings.notifRequeued,
          body: o.serviceTitle
        ),
        _ => null,
      };
      if (payload != null) {
        _notif.show(
          channelId: Strings.notifChannelOrders,
          title: payload.title,
          body: payload.body,
          payload: o.id,
        );
      }
      _lastStatus = o.status;
    }
  }

  // ── notify-me (T7.4) ──
  Future<void> notifyMe() async {
    final o = order.value;
    if (o == null || isPublic.value) return;
    try {
      await _orders.notifyMe(o.id);
      CnSnack.success(Strings.trackerNotifyMeDone);
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    }
  }

  // ── رزرو اسلات برای سفارش long (T7.4) ──
  Future<void> loadSlots() async {
    loadingSlots.value = true;
    try {
      slots.value = await _capacity.slots();
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    } finally {
      loadingSlots.value = false;
    }
  }

  Future<void> reserve(CapacitySlot slot) async {
    final o = order.value;
    if (o == null) return;
    try {
      await _orders.reserveSlot(o.id, slot.id);
      CnSnack.success(Strings.trackerSlotReserved);
      Get.back();
      await _fetchUpdates();
      _onUpdate();
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    }
  }

  // ── لغو ──
  Future<void> cancel() async {
    final o = order.value;
    if (o == null || isPublic.value) return;
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text(Strings.orderCancelTitle),
      content: const Text(Strings.orderCancelBody),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text(Strings.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: CnColors.rose),
          onPressed: () => Get.back(result: true),
          child: const Text(Strings.yes),
        ),
      ],
    ));
    if (ok != true) return;
    try {
      await _orders.cancel(o.id);
      CnSnack.success(Strings.orderCancelSuccess);
      await _fetchUpdates();
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    }
  }

  String etaStartText() {
    final o = order.value;
    if (o == null) return '—';
    return Formatters.time(o.estimatedStartAt);
  }

  @override
  void onClose() {
    _poller?.stop();
    super.onClose();
  }
}
