import 'package:intl/intl.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

/// فرمت‌کننده‌های نمایش — تومان با ارقام فارسی، تاریخ و شماره.
/// مقدار ذخیره‌شده/ارسالی همیشه لاتین است (دکترین §2.1-6 پلن).
class Formatters {
  Formatters._();

  static final NumberFormat _thousands = NumberFormat.decimalPattern('en_US');

  /// 1250000 → «۱٬۲۵۰٬۰۰۰»
  static String toman(int amount) =>
      _thousands.format(amount).toPersianDigit();

  /// 1250000 → «۱٬۲۵۰٬۰۰۰ تومان»
  static String tomanWithUnit(int amount) => '${toman(amount)} تومان';

  /// عدد ساده با ارقام فارسی.
  static String num(int n) => n.toString().toPersianDigit();

  /// ارقام یک رشته (مثل شماره موبایل) را فارسی می‌کند — بدون خرابی صفر ابتدای شماره.
  static String digits(String s) => s.toPersianDigit();

  /// تبدیل ارقام فارسی/عربی به لاتین برای ارسال به سرور.
  static String toLatin(String s) => s.toEnglishDigit();

  /// ISO 8601 سرور → «۱۴۰۳/۰۷/۲۶» (میلادی نمایش‌داده می‌شود — تصمیم باز 13-2).
  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    final f = DateFormat('yyyy/MM/dd', 'en_US');
    return f.format(d.toLocal()).toPersianDigit();
  }

  /// ISO 8601 → «۱۴۰۳/۰۷/۲۶ — ۱۴:۳۰»
  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    final f = DateFormat('yyyy/MM/dd — HH:mm', 'en_US');
    return f.format(d.toLocal()).toPersianDigit();
  }

  /// ISO 8601 → فقط ساعت «۱۴:۳۰»
  static String time(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    return DateFormat('HH:mm', 'en_US').format(d.toLocal()).toPersianDigit();
  }

  /// فاصله تا زمان ISO به شکل خوانا (برای شمارش معکوس و ETA).
  static String durationMinutes(int minutes) {
    if (minutes <= 0) return 'کمتر از یک دقیقه';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${num(m)} دقیقه';
    if (m == 0) return '${num(h)} ساعت';
    return '${num(h)} ساعت و ${num(m)} دقیقه';
  }

  /// حجم فایل خوانا.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '${num(bytes)} بایت';
    if (bytes < 1024 * 1024) return '${num((bytes / 1024).round())} کیلوبایت';
    return '${num((bytes / 1024 / 1024).toStringAsFixed(1))} مگابایت';
  }
}
