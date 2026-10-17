/// اعتبارسنجی‌های سمت کلاینت — قرارداد یکسان با بک‌اند.
class Validators {
  Validators._();

  static final RegExp _mobile = RegExp(r'^09\d{9}$');

  /// موبایل ایرانی 09xxxxxxxxx — ارقام فارسی/عربی پذیرفته و لاتین می‌شود.
  static String? phone(String? value) {
    final v = normalizePhone(value ?? '');
    if (v.isEmpty) return 'شماره موبایل را وارد کنید.';
    if (!_mobile.hasMatch(v)) return 'شماره موبایل معتبر نیست.';
    return null;
  }

  /// نرمال‌سازی شماره: ارقام فارسی→لاتین، 0098/+98/98→0.
  static String normalizePhone(String raw) {
    var s = raw.trim();
    s = s.replaceAllMapped(RegExp('[۰-۹]'), (m) {
      const fa = '۰۱۲۳۴۵۶۷۸۹';
      return fa.indexOf(m[0]!).toString();
    });
    s = s.replaceAllMapped(RegExp('[٠-٩]'), (m) {
      const ar = '٠١٢٣٤٥٦٧٨٩';
      return ar.indexOf(m[0]!).toString();
    });
    s = s.replaceAll(RegExp(r'[\s-]'), '');
    if (s.startsWith('+98')) s = '0${s.substring(3)}';
    if (s.startsWith('0098')) s = '0${s.substring(4)}';
    if (s.startsWith('98') && s.length == 12) s = '0${s.substring(2)}';
    if (s.length == 10 && s.startsWith('9')) s = '0$s';
    return s;
  }

  /// مبلغ شارژ کیف پول — سقف‌های PaymentService بک‌اند.
  static String? topUpAmount(String? value, {int min = 10000, int max = 50000000}) {
    final n = int.tryParse(toLatinDigits(value ?? ''));
    if (n == null || n <= 0) return 'مبلغ را وارد کنید.';
    if (n < min || n > max) return 'مبلغ شارژ باید بین ۱۰٬۰۰۰ تا ۵۰٬۰۰۰٬۰۰۰ تومان باشد.';
    return null;
  }

  /// کد OTP پنج‌رقمی.
  static String? otp(String? value) {
    final v = toLatinDigits(value ?? '');
    if (v.length != 5) return 'کد ۵ رقمی را کامل وارد کنید.';
    return null;
  }

  static final RegExp _faDigits = RegExp('[۰-۹٠-٩]');

  static String toLatinDigits(String s) {
    return s.replaceAllMapped(_faDigits, (m) {
      final ch = m[0]!;
      const fa = '۰۱۲۳۴۵۶۷۸۹';
      const ar = '٠١٢٣٤٥٦٧٨٩';
      final fi = fa.indexOf(ch);
      if (fi >= 0) return fi.toString();
      return ar.indexOf(ch).toString();
    });
  }

  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'تکمیل این فیلد الزامی است.';
    }
    return null;
  }
}
