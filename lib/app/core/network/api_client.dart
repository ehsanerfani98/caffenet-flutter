import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../services/auth_service.dart';
import '../values/strings.dart';
import 'api_error.dart';

/// پوشه `http` — timeout، هدرها، attach توکن Sanctum، پارس خطای flat بک‌اند،
/// force-logout روی 401 (بخش 4 پلن + اسکلت A پیوست 12).
class ApiClient extends GetxService {
  ApiClient(this._auth);

  final AuthService _auth;
  final http.Client _http = http.Client();
  static const Duration _timeout = Duration(seconds: 25);

  Uri _uri(String path, [Map<String, String>? q]) {
    final p = path.replaceAll(RegExp(r'^/'), '');
    return Uri.parse('${Env.apiBase}/$p').replace(queryParameters: q);
  }

  Map<String, String> _headers({bool auth = true}) => {
        'Accept': 'application/json',
        if (auth && _auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
      };

  // ── متدهای JSON ──
  Future<dynamic> get(String p, {Map<String, String>? q, bool auth = true}) =>
      _send('GET', p, query: q, auth: auth);

  Future<dynamic> post(String p, {Object? body, bool auth = true}) =>
      _send('POST', p, body: body, auth: auth);

  Future<dynamic> patch(String p, {Object? body, bool auth = true}) =>
      _send('PATCH', p, body: body, auth: auth);

  Future<dynamic> put(String p, {Object? body, bool auth = true}) =>
      _send('PUT', p, body: body, auth: auth);

  Future<dynamic> delete(String p, {Object? body, bool auth = true}) =>
      _send('DELETE', p, body: body, auth: auth);

  // ── multipart آپلود (POST /upload — قرارداد UploadController) ──
  Future<dynamic> multipart(
    String p, {
    required String fileField,
    required String filePath,
    String? fileName,
    Map<String, String> fields = const {},
  }) async {
    http.MultipartRequest req;
    try {
      req = http.MultipartRequest('POST', _uri(p))
        ..headers.addAll(_headers())
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(
          fileField, filePath,
          filename: fileName,
        ));
      final streamed = await _http.send(req).timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return _handle('POST', p, res);
    } on TimeoutException {
      throw ApiError.timeout(Strings.errTimeout);
    } on SocketException {
      throw ApiError.network(Strings.errNetwork);
    } on IOException {
      throw ApiError.network(Strings.errNetwork);
    }
  }

  // ── دانلود باینری فایل با توکن (BE-4: GET /api/uploads/{filename}) ──
  Future<Uint8List> download(String p, {bool auth = true}) async {
    final res = await _sendRaw('GET', p, auth: auth);
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    throw _errorFrom(res);
  }

  Future<dynamic> _send(
    String m,
    String p, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async =>
      _handle(m, p, await _sendRaw(m, p, query: query, body: body, auth: auth));

  Future<http.Response> _sendRaw(
    String m,
    String p, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async {
    final req = http.Request(m, _uri(p, query))..headers.addAll(_headers(auth: auth));
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    try {
      return await http.Response.fromStream(await _http.send(req).timeout(_timeout));
    } on TimeoutException {
      throw ApiError.timeout(Strings.errTimeout);
    } on SocketException {
      throw ApiError.network(Strings.errNetwork);
    } on HttpException {
      throw ApiError.network(Strings.errNetwork);
    }
  }

  dynamic _handle(String m, String p, http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        return null;
      }
    }
    throw _errorFrom(res);
  }

  ApiError _errorFrom(http.Response res) {
    dynamic json;
    try {
      if (res.body.isNotEmpty) json = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {}

    final msg = (json is Map && json['error'] is String)
        ? json['error'] as String
        : Strings.unknownError;
    final code = (json is Map && json['code'] is String) ? json['code'] as String : null;

    switch (res.statusCode) {
      case 400:
        return ApiError.validation(msg, code: code, payload: json);
      case 401:
        // force-logout (T1.1 AC) — جریان از طریق سرویس احراز هویت.
        unawaited(_auth.forceLogout());
        return ApiError.auth(msg);
      case 403:
        return ApiError.permission(msg);
      case 404:
        return ApiError.notFound(msg);
      case 429:
        return ApiError.rateLimited(msg);
      default:
        return ApiError.server(msg, status: res.statusCode);
    }
  }

  @override
  void onClose() {
    _http.close();
    super.onClose();
  }
}
