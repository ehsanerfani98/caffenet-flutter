import 'dart:io';

import 'package:get/get.dart' hide Response;

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

/// لایه Provider — فقط HTTP، بدون کش (بخش 2.2 پلن).
/// Repositoryها روی این لایه کش‌محوری (stale-while-revalidate) را می‌سازند.
class ApiProvider extends GetxService {
  ApiProvider(this._client);

  final ApiClient _client;

  // ── Auth ──
  Future<dynamic> health() => _client.get(ApiEndpoints.health, auth: false);

  Future<dynamic> sendOtp(String phone) =>
      _client.post(ApiEndpoints.sendOtp, body: {'phone': phone}, auth: false);

  Future<dynamic> verifyOtp(String phone, String code) => _client.post(
        ApiEndpoints.verifyOtp,
        body: {'phone': phone, 'code': code, 'mode': 'token'}, // BE-1
        auth: false,
      );

  Future<dynamic> logout() => _client.post(ApiEndpoints.logout);

  Future<dynamic> me() => _client.get(ApiEndpoints.me);

  // ── Settings / Catalog / Slider ──
  Future<dynamic> settings() => _client.get(ApiEndpoints.settings, auth: false);

  Future<dynamic> categories() => _client.get(ApiEndpoints.categories);

  Future<dynamic> services() => _client.get(ApiEndpoints.services);

  Future<dynamic> slider() => _client.get(ApiEndpoints.slider);

  // ── Capacity ──
  Future<dynamic> capacityCurrent() =>
      _client.get(ApiEndpoints.capacityCurrent, auth: false);

  Future<dynamic> capacitySlots({int hours = 48}) =>
      _client.get(ApiEndpoints.capacitySlots, q: {'hours': '$hours'});

  // ── Orders ──
  Future<dynamic> orders() => _client.get(ApiEndpoints.orders);

  Future<dynamic> order(String id) => _client.get(ApiEndpoints.order(id));

  Future<dynamic> storeOrder(Map<String, dynamic> body) =>
      _client.post(ApiEndpoints.orders, body: body);

  Future<dynamic> patchOrder(String id, Map<String, dynamic> body) =>
      _client.patch(ApiEndpoints.order(id), body: body);

  Future<dynamic> deleteOrder(String id) => _client.delete(ApiEndpoints.order(id));

  Future<dynamic> payWallet(String orderId) =>
      _client.post(ApiEndpoints.orderPayWallet(orderId));

  Future<dynamic> orderUpdates(String orderId) =>
      _client.get(ApiEndpoints.orderUpdates(orderId));

  Future<dynamic> reserveSlot(String orderId, String slotId) =>
      _client.post(ApiEndpoints.orderReserve(orderId), body: {'slot_id': slotId});

  Future<dynamic> notifyMe(String orderId) =>
      _client.post(ApiEndpoints.orderNotifyMe(orderId));

  Future<dynamic> cancelOrder(String orderId) =>
      _client.delete(ApiEndpoints.orderCancel(orderId));

  Future<dynamic> sendTicket(String orderId, String message) =>
      _client.post(ApiEndpoints.orderTicket(orderId), body: {'message': message});

  Future<dynamic> rateOrder(String orderId, int rating, String? comment) =>
      _client.patch(ApiEndpoints.order(orderId),
          body: {'rating': rating, if (comment != null && comment.isNotEmpty) 'reviewComment': comment});

  Future<dynamic> track(String token) =>
      _client.get(ApiEndpoints.track(token), auth: false);

  // ── Payments ──
  Future<dynamic> requestTopUp(int amount, String gateway) =>
      _client.post(ApiEndpoints.paymentRequest, body: {'amount': amount, 'gateway': gateway});

  Future<dynamic> paymentStatus(String authority) =>
      _client.get(ApiEndpoints.paymentStatus, q: {'authority': authority});

  // ── Wallet / Coupons ──
  Future<dynamic> walletTransactions() =>
      _client.get(ApiEndpoints.walletTransactions);

  Future<dynamic> coupons() => _client.get(ApiEndpoints.coupons);

  Future<dynamic> validateCoupon(String code, int totalPrice) =>
      _client.post(ApiEndpoints.couponValidate,
          body: {'code': code, 'totalPrice': totalPrice});

  // ── Upload ──
  Future<dynamic> uploadFile(File file) => _client.multipart(
        ApiEndpoints.upload,
        fileField: 'file',
        filePath: file.path,
        fileName: file.path.split('/').last,
      );

  Future<dynamic> deleteUploadedFile(String url) =>
      _client.delete(ApiEndpoints.upload, body: {'url': url});
}
