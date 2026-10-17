import 'dart:io';

import 'package:get/get.dart';

import '../../core/cache/db_cache.dart';
import '../../core/cache/kv_cache.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_client.dart';
import '../../data/models/misc_models.dart';
import '../../data/models/order_model.dart';
import '../../data/models/uploaded_file.dart';

/// ریپوی سفارش‌ها — L3 write-through (T7.1 پلن).
class OrderRepository extends GetxService {
  OrderRepository(this._api, this._kv, this._db);

  final ApiClient _api;
  final KvCache _kv;
  final DbCache _db;

  /// لیست سفارش‌ها — کش‌محور: L3 فوری + شبکه (fresh).
  Future<List<OrderModel>> list({bool fresh = false}) async {
    if (!fresh) {
      final cached = await _db.orders();
      if (cached.isNotEmpty) {
        // silent refresh در پس‌زمینه
        Future(() async {
          try {
            await list(fresh: true);
          } catch (_) {}
        });
        return cached.map(OrderModel.fromJson).toList();
      }
    }
    final res = await _api.get('orders');
    final list = (res as List).map(OrderModel.fromJson).toList();
    await _db.upsertOrders((res as List));
    return list;
  }

  Future<OrderModel> show(String id, {bool fresh = false}) async {
    if (!fresh) {
      final cached = await _db.orderById(id);
      if (cached != null) {
        Future(() async {
          try {
            await show(id, fresh: true);
          } catch (_) {}
        });
        return OrderModel.fromJson(cached);
      }
    }
    final res = await _api.get('orders/$id');
    await _db.upsertOrder(res);
    return OrderModel.fromJson(res);
  }

  /// ثبت سفارش — write (network-first) → invalidate کش (T5.7).
  Future<OrderModel> store(Map<String, dynamic> body) async {
    final res = await _api.post('orders', body: body);
    await _db.upsertOrder(res);
    return OrderModel.fromJson(res);
  }

  Future<OrderModel> payWithWallet(String orderId) async {
    final res = await _api.post('orders/$orderId/pay-wallet');
    await _db.upsertOrder(res);
    return OrderModel.fromJson(res);
  }

  Future<OrderModel> update(String orderId, Map<String, dynamic> body) async {
    final res = await _api.patch('orders/$orderId', body: body);
    await _db.upsertOrder(res);
    return OrderModel.fromJson(res);
  }

  Future<void> delete(String orderId) async {
    await _api.delete('orders/$orderId');
    await _db.deleteOrder(orderId);
  }

  // ── Queue operations ──
  Future<OrderUpdateModel> updates(String orderId) async {
    final res = await _api.get('orders/$orderId/updates');
    return OrderUpdateModel.fromJson(res);
  }

  Future<void> reserveSlot(String orderId, String slotId) async {
    await _api.post('orders/$orderId/reserve', body: {'slot_id': slotId});
  }

  Future<void> notifyMe(String orderId) =>
      _api.post('orders/$orderId/notify-me');

  Future<OrderModel> cancel(String orderId) async {
    final res = await _api.delete('orders/$orderId/cancel');
    await _db.upsertOrder(res is Map ? (res as Map)['order'] : res);
    return OrderModel.fromJson((res as Map)['order']);
  }

  Future<List<TicketMessage>> sendTicket(String orderId, String message) async {
    final res = await _api.post('orders/$orderId/ticket', body: {'message': message});
    // پاسخ: order کامل به‌روز شده (تغییر قرارداد ممنوع — از پیوست §4 پلن)
    if (res is Map) {
      final m = res.cast<String, dynamic>();
      final order = m['order'] ?? res;
      if (order is Map) await _db.upsertOrder(order);
      final o = OrderModel.fromJson(order);
      return o.ticketMessages;
    }
    return const [];
  }

  Future<OrderModel> rate(String orderId, int rating, String? comment) async {
    final res = await _api.patch('orders/$orderId', body: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'reviewComment': comment,
    });
    await _db.upsertOrder(res);
    return OrderModel.fromJson(res);
  }

  /// اعتبارسنجی کد تخفیف (T5.5) — قرارداد: {code, totalPrice}.
  Future<dynamic> validateCoupon(String code, int totalPrice) async {
    final res = await _api.post('coupons/validate',
        body: {'code': code, 'totalPrice': totalPrice});
    return res;
  }

  /// پیگیری عمومی با توکن (بدون لاگین — T7.8).
  Future<TrackResult> track(String token) async {
    final res = await _api.get('orders/track/$token', auth: false);
    return TrackResult.fromJson(res);
  }

  /// سفارش‌های فعال از کش (کارت Home).
  Future<OrderModel?> activeOrder() async {
    final cached = await _db.orders();
    for (final raw in cached) {
      final o = OrderModel.fromJson(raw);
      if (o.isActive) return o;
    }
    return null;
  }
}

/// ریپوی کیف پول — T6.1 پلن.
class WalletRepository extends GetxService {
  WalletRepository(this._api, this._kv, this._db);

  final ApiClient _api;
  final KvCache _kv;
  final DbCache _db;

  Future<List<WalletTransactionModel>> transactions({bool fresh = false}) async {
    if (!fresh) {
      final cached = await _db.walletTxs();
      if (cached.isNotEmpty) {
        Future(() async {
          try {
            await transactions(fresh: true);
          } catch (_) {}
        });
        return cached.map(WalletTransactionModel.fromJson).toList();
      }
    }
    final res = await _api.get('wallet/transactions');
    final list = (res as List?) ?? const [];
    await _db.upsertWalletTxs(list);
    return list.map(WalletTransactionModel.fromJson).toList();
  }

  /// درخواست شارژ → {gateway, paymentId, authority, redirectUrl} (§4.4 پلن).
  Future<TopUpRequest> requestTopUp(int amount, String gateway) async {
    final res = await _api.post('payments/request', body: {
      'amount': amount,
      'gateway': gateway,
    });
    final m = (res as Map).cast<String, dynamic>();
    final req = TopUpRequest(
      paymentId: '${m['paymentId'] ?? ''}',
      authority: '${m['authority'] ?? ''}',
      redirectUrl: '${m['redirectUrl'] ?? ''}',
      gateway: '${m['gateway'] ?? gateway}',
    );
    // ثبت برای self-healing (T6.5): اگر کاربر برنگشت، در شروع بعدی چک می‌شود.
    _kv.writeJson(StorageKeys.pendingPayment, {
      'authority': req.authority,
      'amount': amount,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
    });
    return req;
  }

  /// وضعیت پرداخت — idempotent و self-healing سمت سرور.
  Future<PaymentStatusModel> status(String authority) async {
    final res = await _api.get('payments/status', q: {'authority': authority});
    return PaymentStatusModel.fromJson(res);
  }

  /// چک‌پرداخت بازیابی در شروع اپ (T6.5).
  /// نتیجه: paid → true (نیاز رفرش موجودی)، failed/none → false.
  Future<PaymentStatusModel?> checkPendingPayment() async {
    final raw = _kv.readJson(StorageKeys.pendingPayment);
    if (raw is! Map) return null;
    final authority = '${raw['authority'] ?? ''}';
    if (authority.isEmpty) return null;
    try {
      final st = await status(authority);
      _kv.remove(StorageKeys.pendingPayment);
      return st;
    } on ApiError {
      return null;
    }
  }

  void clearPending() => _kv.remove(StorageKeys.pendingPayment);
}

class TopUpRequest {
  const TopUpRequest({
    required this.paymentId,
    required this.authority,
    required this.redirectUrl,
    required this.gateway,
  });

  final String paymentId;
  final String authority;
  final String redirectUrl;
  final String gateway;
}

/// ریپوی آپلود — T5.4 پلن.
class UploadRepository extends GetxService {
  UploadRepository(this._api);

  final ApiClient _api;

  Future<UploadedFile> upload(File file) async {
    final res = await _api.multipart('upload', fileField: 'file', filePath: file.path);
    final m = (res as Map).cast<String, dynamic>();
    return UploadedFile.fromJson(m['file'] ?? m);
  }

  Future<void> delete(String url) =>
      _api.delete('upload', body: {'url': url});
}
