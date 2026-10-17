import 'package:get/get.dart';

import '../../core/cache/db_cache.dart';
import '../../core/cache/kv_cache.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/network/api_client.dart';
import '../../data/models/misc_models.dart';

/// ریپوی تنظیمات کسب‌وکار — L2 با TTL ۱۰ دقیقه (T4.1 پلن).
class SettingsRepository extends GetxService {
  SettingsRepository(this._api, this._kv);

  final ApiClient _api;
  final KvCache _kv;
  static const _ttl = Duration(minutes: 10);

  AppSettings? _memory;

  /// کش‌محور: حافظه → L2 (TTL) → شبکه.
  Future<AppSettings> business({bool fresh = false}) async {
    if (!fresh && _memory != null) return _memory!;
    final cached = fresh ? null : _kv.readJson(StorageKeys.settings, maxAge: _ttl);
    if (cached != null) {
      _memory = AppSettings.fromJson(cached);
      return _memory!;
    }
    final res = await _api.get('settings', auth: false);
    _kv.writeJson(StorageKeys.settings, res);
    _memory = AppSettings.fromJson(res);
    return _memory!;
  }

  /// آخرین settings موجود حتی منقضی (حالت آفلاین).
  AppSettings? get cached {
    _memory ??= AppSettings.fromJson(_kv.readJson(StorageKeys.settings) ?? const {});
    return _memory;
  }

  void invalidate() {
    _memory = null;
    _kv.remove(StorageKeys.settings);
  }
}

/// ریپوی ظرفیت — L2 با TTL ۳۰ ثانیه (T4.3 پلن).
class CapacityRepository extends GetxService {
  CapacityRepository(this._api, this._kv);

  final ApiClient _api;
  final KvCache _kv;
  static const _ttl = Duration(seconds: 30);

  Future<CapacitySnapshot> current({bool fresh = false}) async {
    final cached = fresh ? null : _kv.readJson(StorageKeys.capacity, maxAge: _ttl);
    if (cached != null) return CapacitySnapshot.fromJson(cached);
    final res = await _api.get('capacity/current', auth: false);
    _kv.writeJson(StorageKeys.capacity, res);
    return CapacitySnapshot.fromJson(res);
  }

  /// آخرین snapshot حتی منقضی — برای رندر آفلاین Home.
  CapacitySnapshot? get cached {
    final raw = _kv.readJson(StorageKeys.capacity);
    return raw == null ? null : CapacitySnapshot.fromJson(raw);
  }

  Future<List<CapacitySlot>> slots({int hours = 48}) async {
    final res = await _api.get('capacity/slots', q: {'hours': '$hours'});
    final list = (res as Map?)?['slots'] as List? ?? (res as List?);
    return (list ?? []).map(CapacitySlot.fromJson).toList();
  }
}

/// ریپوی کاتالوگ — L2 + L3 با write-through (T4.2 پلن).
class CatalogRepository extends GetxService {
  CatalogRepository(this._api, this._kv, this._db);

  final ApiClient _api;
  final KvCache _kv;
  final DbCache _db;
  static const _ttl = Duration(hours: 6);

  final RxList<CategoryModel> categoriesRx = <CategoryModel>[].obs;
  final RxList<ServiceModel> servicesRx = <ServiceModel>[].obs;

  /// دسته‌ها — کش‌محور (حافظه → L2 TTL → شبکه → L2+L3).
  Future<List<CategoryModel>> categories({bool fresh = false}) async {
    if (!fresh && categoriesRx.isNotEmpty) return categoriesRx;
    final cached = fresh ? null : _kv.readJson(StorageKeys.categories, maxAge: _ttl);
    if (cached != null) {
      final list = (cached as List).map(CategoryModel.fromJson).toList();
      categoriesRx.value = list;
      unawaitedWrite(list);
      return list;
    }
    final res = await _api.get('categories');
    final list = (res as List).map(CategoryModel.fromJson).toList();
    _kv.writeJson(StorageKeys.categories, res);
    await _db.upsertCatalog('category', (res as List));
    categoriesRx.value = list;
    return list;
  }

  /// خدمات (با fields برای فرم داینامیک) — الگوی پیوست B پلن.
  Future<List<ServiceModel>> services({bool fresh = false}) async {
    if (!fresh && servicesRx.isNotEmpty) return servicesRx;
    final res = await _api.get('services');
    final list = (res as List).map(ServiceModel.fromJson).toList();
    await _db.upsertCatalog('service', (res as List));
    servicesRx.value = list;
    return list;
  }

  /// خدمات یک دسته.
  Future<List<ServiceModel>> servicesByCategory(String categoryId) async {
    final all = await services();
    return all.where((s) => s.categoryId == categoryId).toList();
  }

  /// خدمات ویژه (isFeatured).
  Future<List<ServiceModel>> featured() async {
    final all = await services();
    return all.where((s) => s.isFeatured).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// جستجوی محلی روی کش (آفلاین — T4.5).
  List<ServiceModel> searchLocal(String query) {
    if (query.trim().isEmpty) return servicesRx;
    final q = query.trim().toLowerCase();
    return servicesRx
        .where((s) => s.title.toLowerCase().contains(q) || s.description.toLowerCase().contains(q))
        .toList();
  }

  /// آفلاین: کاتالوگ از L3.
  Future<void> loadFromDb() async {
    final cats = await _db.catalog('category');
    final svcs = await _db.catalog('service');
    if (categoriesRx.isEmpty && cats.isNotEmpty) {
      categoriesRx.value = cats.map(CategoryModel.fromJson).toList();
    }
    if (servicesRx.isEmpty && svcs.isNotEmpty) {
      servicesRx.value = svcs.map(ServiceModel.fromJson).toList();
    }
  }

  void unawaitedWrite(List<CategoryModel> list) {
    // L3 write-through دسته‌ها (بدون انتظار).
    Future(() async {
      try {
        await _db.upsertCatalog('category', list.map((c) => c.toJson()).toList());
      } catch (_) {}
    });
  }

  void invalidate() {
    categoriesRx.clear();
    servicesRx.clear();
    _kv.remove(StorageKeys.categories);
  }
}

/// ریپوی اسلایدر — L2 (T4.4 پلن).
class SliderRepository extends GetxService {
  SliderRepository(this._api, this._kv);

  final ApiClient _api;
  final KvCache _kv;
  static const _ttl = Duration(minutes: 10);

  Future<List<SliderItem>> items({bool fresh = false}) async {
    final cached = fresh ? null : _kv.readJson(StorageKeys.slider, maxAge: _ttl);
    if (cached != null) return (cached as List).map(SliderItem.fromJson).toList();
    final res = await _api.get('slider');
    final list = ((res as Map?)?['sliders'] as List?) ?? (res as List?);
    _kv.writeJson(StorageKeys.slider, list ?? const []);
    return (list ?? []).map(SliderItem.fromJson).toList();
  }
}
