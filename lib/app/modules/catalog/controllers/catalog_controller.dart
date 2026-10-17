import 'package:get/get.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/catalog_repository.dart';

/// Catalog — دسته → خدمات با جستجوی محلی (T4.5) + جزئیات خدمت (T4.6).
class CatalogController extends GetxController {
  CatalogController(this._repo);

  final CatalogRepository _repo;

  final status = RxStatus.empty().obs;
  final services = <ServiceModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final query = ''.obs;

  CategoryModel? category; // آرگومان صفحه دسته
  ServiceModel? service; // آرگومان صفحه جزئیات

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is CategoryModel) category = args;
    if (args is ServiceModel) service = args;
    load();
  }

  Future<void> load({bool fresh = false}) async {
    status(RxStatus.loading());
    try {
      if (categories.isEmpty) {
        categories.value = await _repo.categories(fresh: fresh);
      }
      final all = await _repo.services(fresh: fresh);
      services.value = category == null
          ? all
          : all.where((s) => s.categoryId == category!.id).toList();
      status(services.isEmpty ? RxStatus.empty() : RxStatus.success());
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;
      if (services.isNotEmpty) {
        status(RxStatus.success());
        CnSnack.error(e.message);
      } else {
        status(RxStatus.error(e.message));
      }
    }
  }

  /// جستجوی محلی روی کش L3 (بدون network — T4.5).
  List<ServiceModel> get filtered {
    final q = query.value.trim();
    if (q.isEmpty) return services;
    return services
        .where((s) => s.title.contains(q) || s.description.contains(q))
        .toList();
  }

  /// ثبت سفارش — فقط مشتری (T4.6: پیام مناسب برای staff).
  void openOrderForm(ServiceModel s) {
    Get.toNamed(Routes.orderForm, arguments: s);
  }
}
