import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/core/bindings/initial_binding.dart';
import 'app/core/config/env.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/routes/app_routes.dart';
import 'app/core/services/local_notification_service.dart';
import 'app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // اعلان محلی (T1.5) — جایگزین Browser Notification در PWA.
  await Get.put(LocalNotificationService(), permanent: true).init();

  if (Env.debugLog) {
    debugPrint('[CaffeNet] API base: ${Env.baseUrl}');
  }

  runApp(const CaffeNetApp());
}

class CaffeNetApp extends StatelessWidget {
  const CaffeNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'کافی‌نت احسان',
      debugShowCheckedModeBanner: false,

      // ── RTL-First (دکترین §2.1-6 پلن) ──
      locale: const Locale('fa', 'IR'),
      fallbackLocale: const Locale('fa', 'IR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],

      // ── Theme ──
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // ── Routing ──
      initialRoute: Routes.splash,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      smartManagement: SmartManagement.full,
    );
  }
}
