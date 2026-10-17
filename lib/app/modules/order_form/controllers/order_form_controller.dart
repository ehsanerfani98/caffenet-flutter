import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/cache/kv_cache.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/uploaded_file.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/order_wallet_repository.dart';

/// فرم سفارش داینامیک — قلب اپ (T5.1..T5.7 پلن).
class OrderFormController extends GetxController {
  OrderFormController(
    this._catalog,
    this._orders,
    this._upload,
    this._settings,
    this._kv,
    this._auth,
  );

  final CatalogRepository _catalog;
  final OrderRepository _orders;
  final UploadRepository _upload;
  final SettingsRepository _settings;
  final KvCache _kv;
  final AuthService _auth;

  late ServiceModel service;
  AppSettings? settings;

  final status = RxStatus.empty().obs;
  final submitting = false.obs;
  final uploading = false.obs;

  // ── فرم داینامیک ──
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, RxBool> boolCtrls = {};
  final Map<String, Rxn<String>> selectCtrls = {};

  // ── انتخاب‌ها ──
  final urgency = 'normal'.obs;
  final deliveryMethod = 'download'.obs;
  final addressCtrl = TextEditingController();
  final postalCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final contactMethods = <String>[].obs;

  // ── فایل‌ها + کد تخفیف ──
  final files = <UploadedFile>[].obs;
  final couponCodeCtrl = TextEditingController();
  final couponChecking = false.obs;
  final couponDiscount = 0.obs;
  final couponTitle = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ServiceModel) {
      service = args;
    } else {
      // مسیر مستقیم بدون آرگومان — بازگشت.
      status(RxStatus.error('خدمت انتخاب نشده است.'));
      return;
    }
    initForm();
  }

  /// ساخت/بازسازی فرم — از view هم قابل فراخوانی (retry).
  Future<void> initForm() async {
    status(RxStatus.loading());
    try {
      settings = await _settings.business();
      // سرویس تازه (fields ممکن است تغییر کرده باشد).
      try {
        final all = await _catalog.services();
        final fresh = all.where((s) => s.id == service.id).firstOrNull;
        if (fresh != null) service = fresh;
      } catch (_) {}
      _buildForm();
      _restoreDraft();
      status(RxStatus.success());
    } on ApiError catch (e) {
      _buildForm(); // فرم از fields کش‌شده ساخته می‌شود
      _restoreDraft();
      status(RxStatus.success());
      CnSnack.error(e.message);
    }
  }

  void _buildForm() {
    for (final f in service.fields) {
      switch (f.type) {
        case 'checkbox':
          boolCtrls[f.id] = false.obs;
        case 'select':
          selectCtrls[f.id] = Rxn<String>();
        default:
          _textCtrls[f.id] = TextEditingController();
      }
    }
    // راه ارتباطی پیش‌فرض: تماس.
    contactMethods.add('phone_call');
  }

  // ── Draft (L2 — کلید cn_draft_{serviceId} — T5.1) ──
  void saveDraft() {
    if (status.value.isLoading) return;
    final draft = {
      'form': formValues(),
      'urgency': urgency.value,
      'delivery': deliveryMethod.value,
      'address': addressCtrl.text,
      'postal': postalCtrl.text,
      'note': noteCtrl.text,
      'contacts': contactMethods.toList(),
      'coupon': couponCodeCtrl.text,
    };
    _kv.writeJson(StorageKeys.orderDraft(service.id), draft);
  }

  void _restoreDraft() {
    final raw = _kv.readJson(StorageKeys.orderDraft(service.id));
    if (raw is! Map) return;
    try {
      final d = raw.cast<String, dynamic>();
      final form = (d['form'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in form.entries) {
        if (_textCtrls[e.key] != null) _textCtrls[e.key]!.text = '${e.value ?? ''}';
        if (boolCtrls[e.key] != null) boolCtrls[e.key]!.value = e.value == true;
        if (selectCtrls[e.key] != null && '${e.value}'.isNotEmpty) {
          selectCtrls[e.key]!.value = '${e.value}';
        }
      }
      urgency.value = '${d['urgency'] ?? 'normal'}';
      deliveryMethod.value = '${d['delivery'] ?? 'download'}';
      addressCtrl.text = '${d['address'] ?? ''}';
      postalCtrl.text = '${d['postal'] ?? ''}';
      noteCtrl.text = '${d['note'] ?? ''}';
      if (d['contacts'] is List && (d['contacts'] as List).isNotEmpty) {
        contactMethods.value = (d['contacts'] as List).map((e) => '$e').toList();
      }
      couponCodeCtrl.text = '${d['coupon'] ?? ''}';
      Get.snackbar(Strings.appName, Strings.draftRestored, snackPosition: SnackPosition.TOP);
    } catch (_) {}
  }

  /// کنترلر متن یک فیلد داینامیک (برای view).
  TextEditingController textCtrlFor(String id) =>
      _textCtrls[id] ?? TextEditingController();

  Map<String, dynamic> formValues() {
    final out = <String, dynamic>{};
    for (final f in service.fields) {
      switch (f.type) {
        case 'checkbox':
          out[f.id] = boolCtrls[f.id]?.value ?? false;
        case 'select':
          out[f.id] = selectCtrls[f.id]?.value ?? '';
        default:
          out[f.id] = _textCtrls[f.id]?.text.trim() ?? '';
      }
    }
    return out;
  }

  // ── اعتبارسنجی مشترک با سرور (T5.1/T5.2/T5.6) ──
  String? validateForm() {
    for (final f in service.fields) {
      if (!f.required) continue;
      final v = switch (f.type) {
        'checkbox' => boolCtrls[f.id]?.value == true,
        'select' => (selectCtrls[f.id]?.value ?? '').isNotEmpty,
        _ => (_textCtrls[f.id]?.text.trim() ?? '').isNotEmpty,
      };
      if (!v) return 'تکمیل فیلد «${f.label}» الزامی است.';
    }
    if (deliveryMethod.value == 'courier' && addressCtrl.text.trim().isEmpty) {
      return Strings.deliveryAddressRequired;
    }
    if (contactMethods.isEmpty) return Strings.contactMethodsHint;
    return null;
  }

  // ── پیش‌نمایش قیمت محلی (T5.3 — فقط نمایشی؛ سرور حقیقت است) ──
  int get pricePreview {
    var total = service.basePrice;
    final m = urgency.value == 'immediate'
        ? (settings?.immediateMultiplier ?? 1)
        : urgency.value == 'urgent'
            ? (settings?.urgentMultiplier ?? 1)
            : 1.0;
    total = (total * m).round();
    // فرمول‌های ساده: ضرب مقدار عددی × قیمت پایه (mirror ساده PricingService).
    for (final f in service.fields) {
      if (f.type == 'number') {
        final n = num.tryParse(_textCtrls[f.id]?.text ?? '');
        if (n != null && n > 0) total += (n * service.basePrice).round();
      }
    }
    if (deliveryMethod.value == 'courier') {
      total += settings?.courierCost ?? 0;
    }
    final d = couponDiscount.value;
    if (d > 0 && d < total) total -= d;
    return total;
  }

  // ── کد تخفیف (T5.5) ──
  Future<void> applyCoupon() async {
    final code = couponCodeCtrl.text.trim();
    couponDiscount.value = 0;
    couponTitle.value = null;
    if (code.isEmpty) return;
    if (settings?.enableCoupons != true) {
      CnSnack.error('کد تخفیف فعال نیست.');
      return;
    }
    couponChecking.value = true;
    try {
      final res = await _orders.validateCoupon(code, pricePreview + couponDiscount.value);
      final m = (res as Map).cast<String, dynamic>();
      couponDiscount.value = (m['discount'] as num?)?.toInt() ?? 0;
      couponTitle.value = '${(m['coupon'] as Map?)?['code'] ?? code}';
      CnSnack.success(Strings.couponApplied);
    } on ApiError catch (e) {
      // 400 → {valid:false, error:...} — پیام فارسی سرور عیناً
      CnSnack.error(e.message);
    } finally {
      couponChecking.value = false;
    }
  }

  // ── آپلود فایل (T5.4) ──
  Future<void> pickImage() => _pick(true);

  Future<void> pickDocument() => _pick(false);

  Future<void> _pick(bool isImage) async {
    try {
      File? file;
      if (isImage) {
        final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (x != null) file = File(x.path);
      } else {
        final r = await FilePicker.platform.pickFiles(withData: false);
        final p = r?.files.single.path;
        if (p != null) file = File(p);
      }
      if (file == null) return;
      if (file.lengthSync() > AppConstants.maxUploadBytes) {
        CnSnack.error(Strings.fileTooLarge);
        return;
      }
      uploading.value = true;
      final uploaded = await _upload.upload(file);
      files.add(uploaded);
      saveDraft();
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    } catch (_) {
      CnSnack.error(Strings.uploadFailed);
    } finally {
      uploading.value = false;
    }
  }

  Future<void> removeFile(UploadedFile f) async {
    try {
      await _upload.delete(f.url);
    } catch (_) {}
    files.remove(f);
    saveDraft();
  }

  // ── ارسال سفارش (T5.7) ──
  Future<void> submit() async {
    final err = validateForm();
    if (err != null) {
      CnSnack.error(err);
      return;
    }
    submitting.value = true;
    try {
      final order = await _orders.store({
        'serviceId': service.id,
        'formData': formValues(),
        'contactMethods': contactMethods.toList(),
        'urgency': urgency.value,
        'deliveryMethod': deliveryMethod.value,
        if (deliveryMethod.value == 'courier') 'deliveryAddress': addressCtrl.text.trim(),
        if (deliveryMethod.value == 'courier' && postalCtrl.text.trim().isNotEmpty)
          'deliveryPostalCode': postalCtrl.text.trim(),
        if (couponCodeCtrl.text.trim().isNotEmpty && couponDiscount.value > 0)
          'couponCode': couponCodeCtrl.text.trim(),
        if (noteCtrl.text.trim().isNotEmpty) 'customerNote': noteCtrl.text.trim(),
        'customerFiles': files.map((f) => f.toJson()).toList(),
      });
      _kv.remove(StorageKeys.orderDraft(service.id));
      Get.offNamed(Routes.checkout, arguments: order);
    } on ApiError catch (e) {
      if (e.isInsufficientWallet) {
        // §4.4 پلن: دیالوگ «شارژ X تومان» → جریان شارژ → بازگشت به فرم (draft حفظ شده)
        _showShortfallDialog(e);
        return;
      }
      CnSnack.error(e.message);
    } finally {
      submitting.value = false;
    }
  }

  void _showShortfallDialog(ApiError e) {
    final shortfall = e.payloadInt('shortfall') ?? 0;
    Get.dialog(
      AlertDialog(
        title: const Text(Strings.insufficientBalanceTitle),
        content: Text(
          '${Strings.insufficientBalanceBody}\n\n${Strings.shortage}: ${Formatters.tomanWithUnit(shortfall)}',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text(Strings.cancel)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(Routes.wallet, arguments: {'topUpAmount': shortfall});
            },
            child: const Text(Strings.topUpNow),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    addressCtrl.dispose();
    postalCtrl.dispose();
    noteCtrl.dispose();
    couponCodeCtrl.dispose();
    super.onClose();
  }
}
