import 'package:flutter/material.dart';

/// وضعیت‌های سفارش — عیناً مطابق Order model بک‌اند.
class OrderStatus {
  OrderStatus._();

  static const String pendingPayment = 'pending_payment';
  static const String submitted = 'submitted';
  static const String processing = 'processing';
  static const String ready = 'ready';
  static const String delivered = 'delivered';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';

  /// سفارش‌های «فعال» که Tracker/کارت سفارش فعال Home را فعال می‌کنند.
  static const List<String> active = [pendingPayment, submitted, processing, ready];

  static bool isActive(String status) => active.contains(status);

  /// وضعیت‌هایی که لغو/حذف در آن‌ها معنا دارد (بک‌اند delivered/cancelled را رد می‌کند).
  static bool canCancel(String status) =>
      status != delivered && status != cancelled;

  /// وضعیت‌هایی که ویرایش سفارش مجاز است.
  static bool canEdit(String status) => status == pendingPayment;

  /// عنوان فارسی — برگرفته از STATUS_TITLES بک‌اند.
  static String title(String status) => switch (status) {
        pendingPayment => 'در انتظار پرداخت',
        submitted => 'ثبت‌شده — در صف انجام',
        processing => 'در حال انجام',
        ready => 'آماده تحویل',
        delivered => 'تحویل شده',
        failed => 'ناموفق',
        cancelled => 'لغو شده',
        refunded => 'بازگشت وجه',
        _ => status,
      };

  /// رنگ وضعیت‌ها — هماهنگ با پالت PWA.
  static Color color(String status) => switch (status) {
        pendingPayment => const Color(0xFFD97706), // amber
        submitted => const Color(0xFF1559DE), // sky
        processing => const Color(0xFF4F46E5), // indigo
        ready => const Color(0xFF059669), // emerald
        delivered => const Color(0xFF059669),
        failed => const Color(0xFFE11D48), // rose
        cancelled => const Color(0xFF64748B), // slate
        refunded => const Color(0xFF92400E),
        _ => const Color(0xFF64748B),
      };

  /// رنگ پس‌زمینه ملایم چاپ وضعیت.
  static Color softColor(String status) => switch (status) {
        pendingPayment => const Color(0xFFFEF3C7),
        submitted => const Color(0xFFE3EAFC),
        processing => const Color(0xFFE0E7FF),
        ready => const Color(0xFFD1FAE5),
        delivered => const Color(0xFFD1FAE5),
        failed => const Color(0xFFFFE4E6),
        cancelled => const Color(0xFFF1F5F9),
        refunded => const Color(0xFFFEF3C7),
        _ => const Color(0xFFF1F5F9),
      };
}

/// نوع صف سفارش — مطابق OrderTypeClassifierService بک‌اند.
class QueueType {
  QueueType._();

  static const String quick = 'quick';
  static const String normal = 'normal';
  static const String long = 'long';

  static String title(String t) => switch (t) {
        quick => 'سریع (حدود ۵ دقیقه)',
        long => 'حجیم (حدود ۶۰ دقیقه)',
        _ => 'معمولی (حدود ۲۰ دقیقه)',
      };
}

/// سطح‌های ظرفیت — مطابق StatusResolverService بک‌اند.
class CapacityTier {
  CapacityTier._();

  static const String green = 'green';
  static const String yellow = 'yellow';
  static const String orange = 'orange';
  static const String red = 'red';

  static Color color(String tier) => switch (tier) {
        green => const Color(0xFF059669),
        yellow => const Color(0xFFF59E0B),
        orange => const Color(0xFFD97706),
        red => const Color(0xFFE11D48),
        _ => const Color(0xFF059669),
      };
}
