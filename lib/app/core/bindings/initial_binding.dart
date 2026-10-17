import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../cache/db_cache.dart';
import '../cache/kv_cache.dart';
import '../network/api_client.dart';
import '../services/auth_service.dart';
import '../services/launcher_service.dart';
import '../services/local_notification_service.dart';
import '../services/lifecycle_service.dart';
import '../../data/providers/api_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/order_wallet_repository.dart';

/// DI زیرساخت — سرویس‌های permanent (اسکلت E پیوست 12 پلن).
/// Repositoryها lazy + fenix؛ Controllerها در Binding هر ماژول.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ── زیرساخت permanent ──
    Get.put(KvCache(GetStorage()), permanent: true); // GetStorage() = singleton
    Get.put(DbCache(), permanent: true);
    Get.put(AuthService(Get.find<KvCache>()), permanent: true);
    Get.put(ApiClient(Get.find<AuthService>()), permanent: true);
    Get.put(ApiProvider(Get.find<ApiClient>()), permanent: true);
    Get.put(LifecycleService(), permanent: true);
    Get.put(LauncherService(), permanent: true);

    // ── Repositoryها (lazy با fenix — بازسازی پس از dispose) ──
    Get.lazyPut(() => AuthRepository(Get.find<ApiProvider>(), Get.find<AuthService>()),
        fenix: true);
    Get.lazyPut(
        () => CatalogRepository(Get.find<ApiProvider>(), Get.find<KvCache>(), Get.find<DbCache>()),
        fenix: true);
    Get.lazyPut(
        () => SliderRepository(Get.find<ApiProvider>(), Get.find<KvCache>()), fenix: true);
    Get.lazyPut(
        () => SettingsRepository(Get.find<ApiProvider>(), Get.find<KvCache>()), fenix: true);
    Get.lazyPut(
        () => CapacityRepository(Get.find<ApiProvider>(), Get.find<KvCache>()), fenix: true);
    Get.lazyPut(
        () => OrderRepository(
            Get.find<ApiProvider>(), Get.find<KvCache>(), Get.find<DbCache>()),
        fenix: true);
    Get.lazyPut(
        () => WalletRepository(
            Get.find<ApiProvider>(), Get.find<KvCache>(), Get.find<DbCache>()),
        fenix: true);
    Get.lazyPut(() => UploadRepository(Get.find<ApiProvider>()), fenix: true);
  }
}
