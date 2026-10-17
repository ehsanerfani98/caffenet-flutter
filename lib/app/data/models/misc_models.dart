/// مدل‌های سبک صف/ظرفیت/پرداخت/تنظیمات — این endpointها snake_case برمی‌گردانند
/// (OrderUpdateResource / CapacityResource / TrackController بک‌اند).
library;

import 'package:flutter/foundation.dart';

/// payload سبک polling — GET /orders/{id}/updates.
class OrderUpdateModel {
  const OrderUpdateModel({
    required this.order,
    this.notifications = const [],
    this.serverTime,
  });

  final Map<String, dynamic> order;
  final List<NotificationItem> notifications;
  final String? serverTime;

  factory OrderUpdateModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return OrderUpdateModel(
      order: (m['order'] as Map?)?.cast<String, dynamic>() ?? const {},
      notifications:
          (m['notifications'] as List?)?.map(NotificationItem.fromJson).toList() ?? const [],
      serverTime: m['server_time']?.toString() ?? m['serverTime']?.toString(),
    );
  }
}

/// اعلان سفارش — از /updates و /track/{token}.
class NotificationItem {
  const NotificationItem({
    required this.id,
    this.type = '',
    this.title = '',
    this.body = '',
    this.timestamp,
    this.read = false,
    this.payload = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? timestamp;
  final bool read;
  final Map<String, dynamic> payload;

  factory NotificationItem.fromJson(dynamic raw) {
    if (raw is! Map) return const NotificationItem(id: '');
    final m = raw.cast<String, dynamic>();
    final p = (m['payload'] as Map?)?.cast<String, dynamic>() ?? const {};
    return NotificationItem(
      id: '${m['id'] ?? ''}',
      type: '${m['type'] ?? ''}',
      title: '${p['title'] ?? m['title'] ?? ''}',
      body: '${p['body'] ?? p['message'] ?? m['body'] ?? ''}',
      timestamp: (m['created_at'] ?? m['timestamp'])?.toString(),
      read: m['read'] == true,
      payload: p,
    );
  }
}

/// نشانگر ظرفیت — GET /capacity/current (snake_case سرور).
class CapacitySnapshot {
  const CapacitySnapshot({
    this.tier = 'green',
    this.title = '',
    this.etaMinutes = 0,
    this.firstSlotAt,
    this.updatedAt,
  });

  final String tier;
  final String title;
  final int etaMinutes;
  final String? firstSlotAt;
  final String? updatedAt;

  factory CapacitySnapshot.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return CapacitySnapshot(
      tier: '${m['tier'] ?? 'green'}',
      title: '${m['title'] ?? ''}',
      etaMinutes: (m['eta_minutes'] ?? m['etaMinutes'] as num?)?.toInt() ?? 0,
      firstSlotAt: (m['first_slot_at'] ?? m['firstSlotAt'])?.toString(),
      updatedAt: (m['updated_at'] ?? m['updatedAt'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier, 'title': title, 'eta_minutes': etaMinutes,
        'first_slot_at': firstSlotAt, 'updated_at': updatedAt,
      };
}

/// اسلات رزرو — GET /capacity/slots (snake_case سرور).
class CapacitySlot {
  const CapacitySlot({
    required this.id,
    this.operatorName = '',
    this.startAt,
    this.endAt,
    this.status = 'open',
  });

  final String id;
  final String operatorName;
  final String? startAt;
  final String? endAt;
  final String status;

  factory CapacitySlot.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return CapacitySlot(
      id: '${m['id'] ?? ''}',
      operatorName: '${m['operator_name'] ?? m['operatorName'] ?? ''}',
      startAt: (m['start_at'] ?? m['startAt'])?.toString(),
      endAt: (m['end_at'] ?? m['endAt'])?.toString(),
      status: '${m['status'] ?? 'open'}',
    );
  }
}

/// نتیجه polling پرداخت — GET /payments/status (§4.4 پلن).
class PaymentStatusModel {
  const PaymentStatusModel({
    this.status = 'pending',
    this.purpose = 'wallet',
    this.amount = 0,
    this.refId,
    this.orderId,
  });

  final String status; // paid | pending | failed
  final String purpose;
  final int amount;
  final String? refId;
  final String? orderId;

  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed';

  factory PaymentStatusModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return PaymentStatusModel(
      status: '${m['status'] ?? 'pending'}',
      purpose: '${m['purpose'] ?? 'wallet'}',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      refId: m['refId']?.toString() ?? m['ref_id']?.toString(),
      orderId: m['orderId']?.toString() ?? m['order_id']?.toString(),
    );
  }
}

/// تنظیمات کسب‌وکار — GET /settings (SettingsController::business بک‌اند).
class AppSettings {
  const AppSettings({
    this.raw = const {},
  });

  final Map<String, dynamic> raw;

  bool get smsEnabled => raw['smsEnabled'] != false;
  bool get enableCoupons => raw['enableCoupons'] == true;
  bool get enableWalletPayment => raw['enableWalletPayment'] != false;
  int get fileRetentionDays => _int(raw['fileRetentionDays']);
  int get courierCost => _int(raw['courierCost']);
  double get urgentMultiplier => _double(raw['urgentPriceMultiplier'], 1);
  double get immediateMultiplier => _double(raw['immediatePriceMultiplier'], 1);

  /// فلاگ‌های درگاه‌ها — bazaarPay.enabled از بک‌اند.
  bool get bazaarPayEnabled {
    final bp = raw['bazaarPay'];
    return bp is Map && bp['enabled'] == true;
  }

  bool get bazaarIapEnabled {
    final b = raw['bazaar'];
    return b is Map && b['enabled'] == true;
  }

  bool get bazaarIapTestMode {
    final b = raw['bazaar'];
    return b is Map && b['testMode'] == true;
  }

  /// presets شارژ — [{amount, sku}] (sku فقط برای IAP کافه‌بازار).
  List<Map<String, dynamic>> get walletTopUpPresets {
    final list = raw['walletTopUpPresets'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  String? get supportPhone {
    final v = raw['supportPhone'] ?? raw['phone'];
    return v is String && v.isNotEmpty ? v : null;
  }

  /// فیلدهای پروفایل مهمان — مطابق Screens.profile وب.
  String? get siteTitle {
    final v = raw['siteTitle'];
    return v is String && v.isNotEmpty ? v : null;
  }

  String? get coffeenetAddress {
    final v = raw['coffeenetAddress'];
    return v is String && v.isNotEmpty ? v : null;
  }

  String? get coffeenetPhone {
    final v = raw['coffeenetPhone'];
    return v is String && v.isNotEmpty ? v : null;
  }

  String? get workingHours {
    final v = raw['workingHours'];
    return v is String && v.isNotEmpty ? v : null;
  }

  factory AppSettings.fromJson(dynamic raw) {
    if (raw is! Map) return const AppSettings();
    return AppSettings(raw: raw.cast<String, dynamic>());
  }

  static int _int(dynamic v) => v is int ? v : (int.tryParse('$v') ?? 0);
  static double _double(dynamic v, double dflt) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? dflt;
  }
}

/// ردیف اسلایدر — GET /slider.
class SliderItem {
  const SliderItem({
    required this.id,
    this.imageUrl = '',
    this.title = '',
    this.subtitle = '',
    this.ctaLabel = '',
    this.ctaTarget = '',
  });

  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String ctaTarget;

  factory SliderItem.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return SliderItem(
      id: '${m['id'] ?? ''}',
      imageUrl: '${m['imageUrl'] ?? ''}',
      title: '${m['title'] ?? ''}',
      subtitle: '${m['subtitle'] ?? ''}',
      ctaLabel: '${m['ctaLabel'] ?? ''}',
      ctaTarget: '${m['ctaTarget'] ?? ''}',
    );
  }
}

/// تراکنش کیف پول — Formatter::walletTransaction بک‌اند.
class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    this.orderId,
    this.paymentId,
    required this.type,
    required this.typeTitle,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    this.reference,
    this.note,
    this.createdAt,
  });

  final String id;
  final String? orderId;
  final String? paymentId;
  final String type;
  final String typeTitle;
  final String direction; // credit | debit
  final int amount;
  final int balanceAfter;
  final String? reference;
  final String? note;
  final String? createdAt;

  bool get isCredit => direction == 'credit';

  factory WalletTransactionModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return WalletTransactionModel(
      id: '${m['id'] ?? ''}',
      orderId: m['orderId']?.toString() ?? m['order_id']?.toString(),
      paymentId: m['paymentId']?.toString() ?? m['payment_id']?.toString(),
      type: '${m['type'] ?? ''}',
      typeTitle: '${m['typeTitle'] ?? m['type_title'] ?? ''}',
      direction: '${m['direction'] ?? 'debit'}',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (m['balanceAfter'] as num?)?.toInt() ??
          (m['balance_after'] as num?)?.toInt() ?? 0,
      reference: m['reference']?.toString(),
      note: m['note']?.toString(),
      createdAt: m['createdAt']?.toString() ?? m['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'orderId': orderId, 'paymentId': paymentId, 'type': type,
        'typeTitle': typeTitle, 'direction': direction, 'amount': amount,
        'balanceAfter': balanceAfter, 'reference': reference, 'note': note,
        'createdAt': createdAt,
      };
}

/// کد تخفیف — Formatter::coupon بک‌اند.
class CouponModel {
  const CouponModel({
    required this.id,
    required this.code,
    required this.percent,
    this.maxAmount = 0,
    this.minOrderAmount = 0,
    this.expireDate,
    this.isActive = true,
  });

  final String id;
  final String code;
  final int percent;
  final int maxAmount;
  final int minOrderAmount;
  final String? expireDate;
  final bool isActive;

  factory CouponModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return CouponModel(
      id: '${m['id'] ?? ''}',
      code: '${m['code'] ?? ''}',
      percent: (m['percent'] as num?)?.toInt() ?? 0,
      maxAmount: (m['maxAmount'] as num?)?.toInt() ?? 0,
      minOrderAmount: (m['minOrderAmount'] as num?)?.toInt() ?? 0,
      expireDate: m['expireDate']?.toString() ?? m['expire_date']?.toString(),
      isActive: m['isActive'] != false,
    );
  }
}

/// نتیجه پیگیری عمومی — GET /orders/track/{token} (TrackController بک‌اند).
class TrackResult {
  const TrackResult({
    required this.order,
    this.orderNumber = '',
    this.serviceTitle = '',
    this.notifications = const [],
    this.history = const [],
  });

  final Map<String, dynamic> order;
  final String orderNumber;
  final String serviceTitle;
  final List<NotificationItem> notifications;
  final List<Map<String, dynamic>> history;

  factory TrackResult.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return TrackResult(
      order: (m['order'] as Map?)?.cast<String, dynamic>() ?? const {},
      orderNumber: '${m['order_number'] ?? m['orderNumber'] ?? ''}',
      serviceTitle: '${m['service_title'] ?? m['serviceTitle'] ?? ''}',
      notifications:
          (m['notifications'] as List?)?.map(NotificationItem.fromJson).toList() ?? const [],
      history: (m['history'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
    );
  }
}

/// helper مشترک برای لاگ دیباگ — هرگز توکن/داده حساس لاگ نمی‌شود.
void logDebug(String message) {
  debugPrint('[CaffeNet] $message');
}
