import 'package:flutter_test/flutter_test.dart';

import 'package:caffenet/app/core/network/api_error.dart';
import 'package:caffenet/app/data/models/misc_models.dart';
import 'package:caffenet/app/data/models/order_model.dart';
import 'package:caffenet/app/data/models/service_model.dart';
import 'package:caffenet/app/data/models/user_model.dart';

void main() {
  group('ApiError — قرارداد خطای flat بک‌اند', () {
    test('INSUFFICIENT_WALLET با payload ساخت‌یافته', () {
      final e = ApiError.validation(
        'موجودی کیف پول کافی نیست؛ لطفاً ابتدا کیف پول خود را شارژ کنید.',
        code: 'INSUFFICIENT_WALLET',
        payload: {'required': 120000, 'balance': 50000, 'shortfall': 70000},
      );
      expect(e.isInsufficientWallet, isTrue);
      expect(e.payloadInt('shortfall'), 70000);
      expect(e.payloadInt('balance'), 50000);
    });

    test('انواع خطا', () {
      expect(ApiError.auth('x').kind, ApiErrorKind.auth);
      expect(ApiError.rateLimited('x').status, 429);
      expect(ApiError.timeout('x').kind, ApiErrorKind.timeout);
      expect(ApiError.network('x').kind, ApiErrorKind.network);
    });
  });

  group('UserModel — Formatter::user', () {
    test('fromJson کامل', () {
      final u = UserModel.fromJson({
        'id': 'usr1',
        'phone': '09123456789',
        'name': 'احسان',
        'role': 'customer',
        'permissions': ['orders.view'],
        'walletBalance': 150000,
        'createdAt': '2026-10-01T10:00:00Z',
        'isBlocked': false,
      });
      expect(u.walletBalance, 150000);
      expect(u.isBlocked, isFalse);
      expect(u.permissions, ['orders.view']);
      expect(u.toJson()['walletBalance'], 150000);
    });

    test('null-safe (فیلدهای غایب)', () {
      final u = UserModel.fromJson({'id': 'x'});
      expect(u.name, '');
      expect(u.walletBalance, 0);
      expect(u.permissions, isEmpty);
    });
  });

  group('ServiceModel — فرم داینامیک', () {
    test('نوع ناشناخته → text (ریسک §9)', () {
      final s = ServiceModel.fromJson({
        'id': 'srv1',
        'categoryId': 'cat1',
        'title': 'پرینت',
        'basePrice': 5000,
        'fields': [
          {'id': 'pages', 'label': 'تعداد صفحات', 'type': 'number', 'required': true},
          {'id': 'weird', 'label': 'ناشناخته', 'type': 'hologram'},
        ],
      });
      expect(s.fields[0].type, 'number');
      expect(s.fields[1].type, 'text'); // fallback
      expect(s.fields[0].required, isTrue);
    });

    test('required به شکل‌های مختلف', () {
      final s = ServiceModel.fromJson({
        'id': 's',
        'categoryId': 'c',
        'title': 't',
        'basePrice': 0,
        'fields': [
          {'id': 'a', 'label': 'A', 'type': 'text', 'required': 1},
          {'id': 'b', 'label': 'B', 'type': 'text', 'required': true},
          {'id': 'c', 'label': 'C', 'type': 'text'},
        ],
      });
      expect(s.fields[0].required, isTrue);
      expect(s.fields[1].required, isTrue);
      expect(s.fields[2].required, isFalse);
    });
  });

  group('OrderModel — applyUpdate با snake_case (OrderUpdateResource)', () {
    test('اعمال payload سبک polling', () {
      final o = OrderModel.fromJson({
        'id': 'o1',
        'orderNumber': 'CN-1',
        'serviceId': 's',
        'serviceTitle': 'پرینت',
        'status': 'submitted',
        'urgency': 'normal',
        'deliveryMethod': 'download',
        'totalPrice': 10000,
        'discountAmount': 0,
        'paidAmount': 10000,
        'queueType': 'quick',
        'queuePosition': 4,
      });
      final u = o.applyUpdate({
        'status': 'processing',
        'status_title': 'در حال انجام',
        'queue_position': 2,
        'estimated_wait_minutes': 5,
        'estimated_start_at': '2026-10-18T10:00:00Z',
        'updated_at': '2026-10-18T10:05:00Z',
      });
      expect(u.status, 'processing');
      expect(u.queuePosition, 2);
      expect(u.estimatedWaitMinutes, 5);
      expect(u.totalPrice, 10000); // بقیه فیلدها حفظ
      expect(u.isActive, isTrue);
    });

    test('payable محاسبه', () {
      final o = OrderModel.fromJson({
        'id': 'o',
        'orderNumber': 'x',
        'serviceId': 's',
        'serviceTitle': 't',
        'status': 'pending_payment',
        'urgency': 'normal',
        'deliveryMethod': 'download',
        'totalPrice': 50000,
        'discountAmount': 10000,
        'paidAmount': 0,
      });
      expect(o.payable, 40000);
    });
  });

  group('CapacitySnapshot / PaymentStatus — snake_case سرور', () {
    test('CapacitySnapshot', () {
      final c = CapacitySnapshot.fromJson({
        'tier': 'orange',
        'title': 'شلوغ',
        'eta_minutes': 35,
        'first_slot_at': '2026-10-18T12:00:00Z',
        'updated_at': '2026-10-18T10:00:00Z',
      });
      expect(c.tier, 'orange');
      expect(c.etaMinutes, 35);
      expect(c.toJson()['eta_minutes'], 35);
    });

    test('PaymentStatus', () {
      final p = PaymentStatusModel.fromJson({
        'status': 'paid',
        'purpose': 'wallet',
        'amount': 100000,
        'refId': 'rzp-123',
        'orderId': null,
      });
      expect(p.isPaid, isTrue);
      expect(p.amount, 100000);
    });

    test('CapacitySlot snake_case', () {
      final s = CapacitySlot.fromJson({
        'id': 'slot1',
        'operator_name': 'علی',
        'start_at': '2026-10-18T12:00:00Z',
        'end_at': '2026-10-18T12:30:00Z',
        'status': 'open',
      });
      expect(s.operatorName, 'علی');
      expect(s.startAt, isNotNull);
    });
  });
}
