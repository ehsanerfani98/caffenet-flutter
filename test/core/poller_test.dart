import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:caffenet/app/core/network/api_error.dart';
import 'package:caffenet/app/core/services/poller.dart';
import 'package:caffenet/app/data/models/misc_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Poller — backoff نمایی و توقف (T1.5 AC)', () {
    test('روی موفقیت پریود ثابت می‌ماند', () async {
      var ticks = 0;
      final p = Poller(
        task: () async => ticks++,
        period: const Duration(milliseconds: 30),
        maxPeriod: const Duration(milliseconds: 100),
      )..start();
      await Future.delayed(const Duration(milliseconds: 180));
      p.stop();
      expect(ticks, greaterThanOrEqualTo(3));
    });

    test('روی خطا backoff نمایی اعمال می‌شود', () async {
      var calls = 0;
      final p = Poller(
        task: () async {
          calls++;
          throw ApiError.network('offline');
        },
        period: const Duration(milliseconds: 10),
        maxPeriod: const Duration(milliseconds: 60),
      )..start();
      await Future.delayed(const Duration(milliseconds: 120));
      p.stop();
      // backoff: 1→2→4→… ولی چون maxPeriod 60ms است، حداکثر چند نوبت اجرا می‌شود
      expect(calls, lessThan(6));
      expect(calls, greaterThanOrEqualTo(1));
    });

    test('setBackground(true) توقف؛ false ادامه (lifecycle-aware)', () async {
      var ticks = 0;
      final p = Poller(
        task: () async => ticks++,
        period: const Duration(milliseconds: 20),
      )..start();
      p.setBackground(true);
      final before = ticks;
      await Future.delayed(const Duration(milliseconds: 80));
      expect(ticks, before); // pause
      p.setBackground(false); // tick فوری
      await Future.delayed(const Duration(milliseconds: 40));
      expect(ticks, greaterThan(before));
      p.stop();
    });

    test('onUpdate پس از موفقیت صدا زده می‌شود', () async {
      var updated = 0;
      final p = Poller(
        task: () async {},
        period: const Duration(milliseconds: 20),
        onUpdate: () => updated++,
      )..start();
      await Future.delayed(const Duration(milliseconds: 70));
      p.stop();
      expect(updated, greaterThanOrEqualTo(2));
    });

    test('429 → توقف ۶۵ ثانیه‌ای (احترام rate limit سرور)', () async {
      var calls = 0;
      final p = Poller(
        task: () async {
          calls++;
          throw ApiError.rateLimited('تعداد درخواست‌ها بیش از حد مجاز است.');
        },
        period: const Duration(milliseconds: 10),
      )..start();
      await Future.delayed(const Duration(milliseconds: 60));
      p.stop();
      expect(calls, 1); // بعد از 429 فوراً تکرار نمی‌شود
    });
  });

  group('Poller.hasNewNotification — helper نوتیف محلی (T7.5)', () {
    test('آیتم جدید تشخیص داده می‌شود', () {
      final prev = [const NotificationItem(id: 'n1')];
      final cur = [
        const NotificationItem(id: 'n1'),
        const NotificationItem(id: 'n2'),
      ];
      expect(Poller.hasNewNotification(cur, prev), isTrue);
      expect(Poller.hasNewNotification(cur, cur), isFalse);
    });
  });
}
