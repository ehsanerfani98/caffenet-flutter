import 'package:get_storage/get_storage.dart';

/// لایه کش L2 — GetStorage با TTL (دکترین §2.4 پلن).
/// همه کلیدها خودکار با پیشوند `cn_` نوشته می‌شوند.
class KvCache {
  KvCache(this._box);

  final GetStorage _box;

  String _k(String key) => key.startsWith('cn_') ? key : 'cn_$key';

  dynamic _entry(String key) {
    final v = _box.read(_k(key));
    if (v == null) return null;
    if (v is! Map) return {'v': v, 't': 0}; // مقدار بدون TTL (legacy)
    return v;
  }

  /// خواندن مقدار JSON با TTL اختیاری — منقضی ⇒ null.
  dynamic readJson(String key, {Duration? maxAge}) {
    final e = _entry(key);
    if (e == null) return null;
    if (maxAge != null && maxAge.inMilliseconds > 0) {
      final t = (e['t'] as num?)?.toInt() ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - t;
      if (age > maxAge.inMilliseconds) return null;
    }
    return e['v'];
  }

  dynamic readRaw(String key) => readJson(key);

  void writeJson(String key, dynamic value) {
    _box.write(_k(key), {
      'v': value,
      't': DateTime.now().millisecondsSinceEpoch,
    });
  }

  bool has(String key) => _box.hasData(_k(key));

  void remove(String key) => _box.remove(_k(key));

  /// پاک‌سازی همه کلیدهای پیشونددار (بدون حذف ترجیحات ثابت).
  void purgeAll() {
    for (final k in _box.getKeys().toList()) {
      if (k is String && k.startsWith('cn_')) _box.remove(k);
    }
  }

  /// پاک‌سازی داده کاربر هنگام logout — ترجیحات (تم/آنبوردینگ) حفظ می‌شود.
  void purgeUserData() {
    for (final k in _box.getKeys().toList()) {
      if (k is! String || !k.startsWith('cn_')) continue;
      if (k == 'cn_theme_mode' || k == 'cn_onboarding_done') continue;
      _box.remove(k);
    }
  }
}
