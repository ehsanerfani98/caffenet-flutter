import 'package:flutter_test/flutter_test.dart';

import 'package:caffenet/app/core/utils/validators.dart';
import 'package:caffenet/app/core/utils/formatters.dart';

void main() {
  group('Validators.phone — قرارداد AuthService::normalizePhone بک‌اند', () {
    test('09xxxxxxxxx معتبر', () {
      expect(Validators.phone('09123456789'), isNull);
    });

    test('98/0098/+98 → 0', () {
      expect(Validators.normalizePhone('+989123456789'), '09123456789');
      expect(Validators.normalizePhone('00989123456789'), '09123456789');
      expect(Validators.normalizePhone('989123456789'), '09123456789');
      expect(Validators.normalizePhone('9123456789'), '09123456789');
    });

    test('ارقام فارسی → لاتین', () {
      expect(Validators.normalizePhone('۰۹۱۲۳۴۵۶۷۸۹'), '09123456789');
      expect(Validators.normalizePhone('٠٩١٢٣٤٥٦٧٨٩'), '09123456789');
    });

    test('شماره نامعتبر', () {
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('0912345678'), isNotNull);
      expect(Validators.phone('08123456789'), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });
  });

  group('Validators.topUpAmount — سقف‌های PaymentService بک‌اند', () {
    test('حد پایین/بالا', () {
      expect(Validators.topUpAmount('5000'), isNotNull); // < 10k
      expect(Validators.topUpAmount('10000'), isNull);
      expect(Validators.topUpAmount('50000000'), isNull);
      expect(Validators.topUpAmount('60000000'), isNotNull);
      expect(Validators.topUpAmount('abc'), isNotNull);
    });

    test('ارقام فارسی پذیرفته می‌شود', () {
      expect(Validators.topUpAmount('۱۰۰۰۰۰'), isNull);
    });
  });

  group('Validators.otp — کد ۵ رقمی', () {
    test('طول ۵ لاتین', () {
      expect(Validators.otp('12345'), isNull);
      expect(Validators.otp('1234'), isNotNull);
      expect(Validators.otp('123456'), isNotNull);
    });

    test('ارقام فارسی → لاتین', () {
      expect(Validators.otp('۱۲۳۴۵'), isNull);
    });
  });

  group('Formatters — تومان با ارقام فارسی', () {
    test('toman جداکننده هزارگان', () {
      expect(Formatters.toman(1250000), contains('۱'));
      expect(Formatters.toman(0), '۰');
    });

    test('durationMinutes', () {
      expect(Formatters.durationMinutes(0), 'کمتر از یک دقیقه');
      expect(Formatters.durationMinutes(45), contains('۴۵ دقیقه'));
      expect(Formatters.durationMinutes(90), contains('۱ ساعت'));
    });
  });
}
