import 'dart:async';

import 'package:get/get.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/lifecycle_service.dart';
import '../../../core/services/poller.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// Home — ظرفیت + اسلایدر + دسته‌ها + ویژه + سفارش فعال (T4.3/T4.4 پلن).
class HomeController extends GetxController {
  HomeController(
    this._catalog,
    this._slider,
    this._settings,
    this._capacity,
    this._orders,
    this._auth,
    this._lifecycle,
  );

  final CatalogRepository _catalog;
  final SliderRepository _slider;
  final SettingsRepository _settings;
  final CapacityRepository _capacity;
  final OrderRepository _orders;
  final AuthService _auth;
  final LifecycleService _lifecycle;

  /// دسترسی ویو به ریپو کاتالوگ (categoriesRx / featured).
  CatalogRepository get catalog => _catalog;

  final status = RxStatus.empty().obs;
  final capacity = Rxn<CapacitySnapshot>();
  final sliderItems = <SliderItem>[].obs;
  final activeOrder = Rxn<OrderModel>();
  final greeting = Strings.homeGuest.obs;

  Poller? _capacityPoller;
  StreamSubscription? _lifeSub;

  @override
  void onInit() {
    super.onInit();
    final u = _auth.user.value;
    if (u != null) {
      greeting.value = '${Strings.homeGreeting} ${u.name.trim().isNotEmpty ? u.name : Strings.homeGuest}';
    }
    load();
    _lifeSub = _lifecycle.state.listen((s) {
      if (s == AppLifecycleState.resumed) {
        _capacityPoller?.setBackground(false);
      } else {
        _capacityPoller?.setBackground(true);
      }
    });
  }

  Future<void> load({bool fresh = false}) async {
    if (status.value.isLoading) return;
    status(fresh ? RxStatus.success() : RxStatus.loading());
    try {
      // آفلاین: اول L3 → رندر؛ سپس شبکه (stale-while-revalidate).
      await _catalog.loadFromDb();
      final results = await Future.wait<dynamic>([
        _catalog.categories(fresh: fresh),
        _capacity.current(fresh: fresh),
      ]);
      capacity.value = results[1] as CapacitySnapshot;
      try {
        sliderItems.value = await _slider.items(fresh: fresh);
      } catch (_) {} // اسلایدر حیاتی نیست
      try {
        activeOrder.value = await _orders.activeOrder();
      } catch (_) {}
      _startCapacityPoller();
      status(RxStatus.success());
      // سرویس‌ها و تنظیمات را هم prewarm کن (featured + فرم سفارش).
      Future(() async {
        try {
          await _catalog.services(fresh: fresh);
        } catch (_) {}
        try {
          await _settings.business(fresh: fresh);
        } catch (_) {}
      });
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      status(RxStatus.error(e.message));
    }
  }

  void _startCapacityPoller() {
    _capacityPoller?.stop();
    _capacityPoller = Poller(
      task: () async {
        capacity.value = await _capacity.current();
      },
      period: AppConstants.capacityPollPeriod,
      maxPeriod: AppConstants.capacityPollPeriod * 2,
    )..start();
  }

  void openCategory(dynamic category) =>
      Get.toNamed(Routes.catalogCategory, arguments: category);

  void openService(dynamic service) =>
      Get.toNamed(Routes.serviceDetail, arguments: service);

  void openCatalog() => Get.toNamed(Routes.catalog);

  void openActiveOrder() {
    final o = activeOrder.value;
    if (o == null) return;
    if (o.status == 'pending_payment') {
      Get.toNamed(Routes.checkout, arguments: o);
    } else {
      Get.toNamed(Routes.tracker, arguments: {'orderId': o.id});
    }
  }

  @override
  void onClose() {
    _capacityPoller?.stop();
    _lifeSub?.cancel();
    super.onClose();
  }
}

/// helper نمایش ETA فارسی.
String capacityEtaText(CapacitySnapshot? s) {
  if (s == null) return '';
  return '${Strings.capacityEta}: ${'${s.etaMinutes}'.toPersianDigit()} ${Strings.minutes}';
}
