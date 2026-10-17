import 'dart:async';

import '../../data/models/misc_models.dart';
import '../network/api_error.dart';

/// Poller عمومی visibility-aware با backoff نمایی (اسکلت D پیوست 12 پلن).
/// - روی موفقیت: پریود نرمال
/// - روی خطا: 1s → 2s → 4s → … تا maxPeriod
/// - روی 429: توقف تا سر دقیقه بعد (احترام به rate limit سرور)
/// - روی 401: توقف کامل (force-logout در ApiClient انجام شده)
/// - پس‌زمینه: pause؛ بازگشت به foreground: یک tick فوری.
class Poller {
  Poller({
    required this.task,
    this.period = const Duration(seconds: 15),
    this.maxPeriod = const Duration(seconds: 30),
    this.onUpdate,
  });

  final Future<void> Function() task;
  final Duration period;
  final Duration maxPeriod;

  /// فراخوانی وقتی task موفق شد (برای نوتیفیکیشن محلی روی تغییر وضعیت).
  final void Function()? onUpdate;

  Timer? _t;
  Duration _backoff = const Duration(seconds: 1);
  bool _paused = false;
  bool _running = false;
  bool _busy = false;

  void start() {
    if (_running) return;
    _running = true;
    _schedule(period);
  }

  void _schedule(Duration d) {
    _t?.cancel();
    _t = Timer(d, _tick);
  }

  Future<void> _tick() async {
    if (!_running || _paused) {
      if (_running) _schedule(period);
      return;
    }
    if (_busy) {
      _schedule(period);
      return;
    }
    _busy = true;
    try {
      await task();
      _backoff = const Duration(seconds: 1);
      onUpdate?.call();
      _schedule(period);
    } on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return; // forceLogout شد — توقف
      if (e.kind == ApiErrorKind.rateLimited) {
        _schedule(const Duration(seconds: 65));
        return;
      }
      final next = _backoff * 2;
      _backoff = next > maxPeriod ? maxPeriod : next;
      _schedule(_backoff);
    } catch (_) {
      final next = _backoff * 2;
      _backoff = next > maxPeriod ? maxPeriod : next;
      _schedule(_backoff);
    } finally {
      _busy = false;
    }
  }

  /// lifecycle-aware — پس‌زمینه: توقف؛ foreground: tick فوری (§4.3 پلن).
  void setBackground(bool bg) {
    _paused = bg;
    if (!bg && _running) _tick();
  }

  void stop() {
    _t?.cancel();
    _t = null;
    _running = false;
  }

  bool get isRunning => _running;

  /// helper: آیا آیتم اعلان جدیدتر از قبلی است (برای نوتیف محلی T7.5).
  static bool hasNewNotification(
    List<NotificationItem> current,
    List<NotificationItem> previous,
  ) {
    if (previous.isEmpty) return current.isNotEmpty;
    final prevIds = previous.map((e) => e.id).toSet();
    return current.any((e) => !prevIds.contains(e.id));
  }
}
