import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../values/strings.dart';

/// اعلان محلی — جانشین Browser Notification در PWA (T1.5 / T7.5 پلن).
/// کانال‌های فارسی: orders (وضعیت سفارش) + wallet (پرداخت).
/// روی تغییر وضعیت polling نمایش داده می‌شود؛ کلیک → صفحه Tracker سفارش.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _seq = 0;

  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onTap,
      );
      await _requestPermissions();
      _ready = true;
    } catch (e) {
      debugPrint('notification init failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}
  }

  void _onTap(NotificationResponse res) {
    final orderId = res.payload;
    if (orderId != null && orderId.isNotEmpty && Get.currentRoute != '/tracker') {
      Get.toNamed('/tracker', arguments: {'orderId': orderId, 'autoStart': true});
    }
  }

  Future<void> show({
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) return;
    _seq = (_seq + 1) % 0x7fffffff;
    final id = _seq;
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == Strings.notifChannelWallet
                ? Strings.notifChannelWalletName
                : Strings.notifChannelOrdersName,
            channelDescription: 'CaffeNet',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
            payload: payload,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('notification show failed: $e');
    }
  }
}
