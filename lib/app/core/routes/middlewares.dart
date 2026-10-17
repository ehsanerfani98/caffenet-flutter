import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

/// مسیرهای خصوصی — بدون توکن → auth (T3.4 پلن).
class AuthMiddleware extends GetMiddleware {
  const AuthMiddleware({super.priority});

  @override
  RouteSettings? redirect(String? route, bool? isFullyLoaded) {
    final auth = Get.find<AuthService>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: '/auth');
    }
    return null;
  }
}

/// مسیرهای مهمان — با نشست فعال → home.
class GuestMiddleware extends GetMiddleware {
  const GuestMiddleware({super.priority});

  @override
  RouteSettings? redirect(String? route, bool? isFullyLoaded) {
    final auth = Get.find<AuthService>();
    if (auth.isAuthenticated) {
      return const RouteSettings(name: '/home');
    }
    return null;
  }
}
