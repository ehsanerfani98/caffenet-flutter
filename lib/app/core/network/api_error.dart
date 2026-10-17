/// خطای ساخت‌یافته API — قرارداد بک‌اند: همیشه `{"error": "...", "code"?: "..."}`.
enum ApiErrorKind { network, timeout, auth, validation, permission, rateLimited, notFound, server }

class ApiError implements Exception {
  ApiError({
    required this.kind,
    required this.message,
    this.code,
    this.status,
    this.payload,
  });

  final ApiErrorKind kind;
  final String message;
  final String? code;
  final int? status;
  final dynamic payload;

  factory ApiError.network(String message) =>
      ApiError(kind: ApiErrorKind.network, message: message);

  factory ApiError.timeout(String message) =>
      ApiError(kind: ApiErrorKind.timeout, message: message);

  factory ApiError.auth(String message) =>
      ApiError(kind: ApiErrorKind.auth, message: message, status: 401);

  factory ApiError.validation(String message, {String? code, dynamic payload}) =>
      ApiError(kind: ApiErrorKind.validation, message: message, code: code,
          status: 400, payload: payload);

  factory ApiError.permission(String message) =>
      ApiError(kind: ApiErrorKind.permission, message: message, status: 403);

  factory ApiError.rateLimited(String message) =>
      ApiError(kind: ApiErrorKind.rateLimited, message: message, status: 429);

  factory ApiError.notFound(String message) =>
      ApiError(kind: ApiErrorKind.notFound, message: message, status: 404);

  factory ApiError.server(String message, {int? status}) =>
      ApiError(kind: ApiErrorKind.server, message: message, status: status ?? 500);

  /// خطاهای معنایی شناخته‌شده بک‌اند.
  bool get isInsufficientWallet => code == 'INSUFFICIENT_WALLET';
  bool get isWalletOnly => code == 'WALLET_ONLY';

  /// payload ساخت‌یافته کمبود موجودی: {required, balance, shortfall}.
  int? payloadInt(String key) =>
      payload is Map ? int.tryParse('${payload[key]}') : null;

  @override
  String toString() => 'ApiError($kind, $status, $code): $message';
}
