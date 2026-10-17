import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/service_model.dart';
import '../controllers/order_form_controller.dart';
import '../../../core/theme/app_text_styles.dart';

/// فرم سفارش داینامیک — رندر بر اساس fields[] سرویس (T5.1).
class OrderFormView extends GetView<OrderFormController> {
  const OrderFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.saveDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(Strings.orderFormTitle),
          actions: [
            IconButton(
              tooltip: Strings.save,
              icon: const Icon(Icons.save_outlined),
              onPressed: () {
                controller.saveDraft();
                CnSnack.info('پیش‌نویس ذخیره شد.');
              },
            ),
          ],
        ),
        body: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 5);
          if (st.isError) return CnErrorRetry(message: st.errorMessage, onRetry: () => controller.initForm());
          return _Form(c: controller);
        }),
        bottomNavigationBar: _SubmitBar(c: controller),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.c});

  final OrderFormController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── مشخصات (فرم داینامیک) ──
        SectionHeader(title: '${Strings.formSectionDetails} — ${c.service.title}'),
        ..._buildDynamicFields(c.service),

        // ── فوریت ──
        SectionHeader(title: Strings.formSectionUrgency),
        Obx(() => SegmentedUrgency(
              value: c.urgency.value,
              urgentMultiplier: c.settings?.urgentMultiplier ?? 1,
              immediateMultiplier: c.settings?.immediateMultiplier ?? 1,
              onChanged: (v) {
                c.urgency.value = v;
                c.saveDraft();
              },
            )),

        // ── روش تحویل ──
        SectionHeader(title: Strings.formSectionDelivery),
        Obx(() => Column(
              children: [
                _DeliveryTile(
                  title: Strings.deliveryDownload,
                  icon: Icons.download_outlined,
                  selected: c.deliveryMethod.value == 'download',
                  onTap: () => c.deliveryMethod.value = 'download',
                ),
                _DeliveryTile(
                  title: Strings.deliveryCourier,
                  icon: Icons.local_shipping_outlined,
                  selected: c.deliveryMethod.value == 'courier',
                  onTap: () => c.deliveryMethod.value = 'courier',
                ),
                _DeliveryTile(
                  title: Strings.deliveryInPerson,
                  icon: Icons.store_outlined,
                  selected: c.deliveryMethod.value == 'in_person',
                  onTap: () => c.deliveryMethod.value = 'in_person',
                ),
                if (c.deliveryMethod.value == 'courier') ...[
                  const SizedBox(height: 8),
                  CnTextField(
                    controller: c.addressCtrl,
                    label: Strings.deliveryAddressLabel,
                    hint: 'آدرس کامل…',
                    maxLines: 2,
                    onChanged: (_) => c.saveDraft(),
                  ),
                  const SizedBox(height: 10),
                  CnTextField(
                    controller: c.postalCtrl,
                    label: Strings.deliveryPostalCode,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => c.saveDraft(),
                  ),
                ],
              ],
            )),

        // ── فایل‌ها ──
        SectionHeader(title: Strings.formSectionFiles),
        Obx(() => FileSection(c: c)),

        // ── کد تخفیف ──
        SectionHeader(title: Strings.formSectionCoupon),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CnTextField(
                controller: c.couponCodeCtrl,
                hint: Strings.couponPlaceholder,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Obx(() => CnButton(
                    label: Strings.couponApply,
                    loading: c.couponChecking.value,
                    onPressed: c.applyCoupon,
                  )),
            ),
          ],
        ),

        // ── راه‌های ارتباطی ──
        SectionHeader(title: Strings.formSectionContact),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ContactChip(label: Strings.contactPhoneCall, value: 'phone_call', c: c),
                _ContactChip(label: Strings.contactSms, value: 'sms', c: c),
                _ContactChip(label: Strings.contactTelegram, value: 'telegram', c: c),
                _ContactChip(label: Strings.contactWhatsapp, value: 'whatsapp', c: c),
              ],
            )),
        Obx(() => c.contactMethods.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(Strings.contactMethodsHint,
                    style: const TextStyle(color: CnColors.rose, fontSize: 12.5)),
              )
            : const SizedBox.shrink()),

        // ── توضیحات ──
        SectionHeader(title: Strings.formSectionNote),
        CnTextField(
          controller: c.noteCtrl,
          hint: Strings.noteHint,
          maxLines: 3,
          onChanged: (_) => c.saveDraft(),
        ),
        const SizedBox(height: 16),
        Text(
          Strings.priceServerNote,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildDynamicFields(ServiceModel s) {
    final widgets = <Widget>[];
    for (final f in s.fields) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _FieldFor(field: f, c: c),
      ));
    }
    if (s.fields.isEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('این خدمت فرم خاصی ندارد؛ مستقیم ادامه دهید.',
            style: Get.context!.textTheme.bodySmall),
      ));
    }
    return widgets;
  }
}

/// رندر یک فیلد داینامیک بر اساس type (T5.1).
class _FieldFor extends StatelessWidget {
  const _FieldFor({required this.field, required this.c});

  final dynamic field;
  final OrderFormController c;

  @override
  Widget build(BuildContext context) {
    final f = field;
    switch (f.type) {
      case 'select':
        return Obx(() {
          final sel = c.selectCtrls[f.id]?.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${f.label}${f.required ? ' *' : ''}',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: sel,
                hint: Text(f.placeholder.isEmpty ? 'انتخاب کنید' : f.placeholder,
                    style: const TextStyle(fontSize: 13.5)),
                items: (f.options as List)
                    .map((o) => DropdownMenuItem(value: '$o', child: Text('$o', style: const TextStyle(fontSize: 13.5))))
                    .toList(),
                onChanged: (v) {
                  c.selectCtrls[f.id]?.value = v;
                  c.saveDraft();
                },
                decoration: const InputDecoration(),
              ),
            ],
          );
        });
      case 'checkbox':
        return Obx(() => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('${f.label}${f.required ? ' *' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium),
              value: c.boolCtrls[f.id]?.value ?? false,
              onChanged: (v) {
                c.boolCtrls[f.id]?.value = v ?? false;
                c.saveDraft();
              },
            ));
      case 'textarea':
        return CnTextField(
          controller: c.textCtrlFor(f.id),
          label: '${f.label}${f.required ? ' *' : ''}',
          hint: f.placeholder,
          maxLines: 3,
          onChanged: (_) => c.saveDraft(),
        );
      case 'date':
        return CnTextField(
          controller: c.textCtrlFor(f.id),
          label: '${f.label}${f.required ? ' *' : ''}',
          hint: '۱۴۰۳/۰۱/۰۱',
          keyboardType: TextInputType.datetime,
          onChanged: (_) => c.saveDraft(),
        );
      case 'number':
        return CnTextField(
          controller: c.textCtrlFor(f.id),
          label: '${f.label}${f.required ? ' *' : ''}',
          hint: f.placeholder,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => c.saveDraft(),
        );
      default:
        return CnTextField(
          controller: c.textCtrlFor(f.id),
          label: '${f.label}${f.required ? ' *' : ''}',
          hint: f.placeholder,
          onChanged: (_) => c.saveDraft(),
        );
    }
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? CnColors.skySoft.withOpacity(.6) : null,
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(icon, color: selected ? CnColors.sky : CnColors.inkSoft),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        trailing: selected
            ? const Icon(Icons.check_circle, color: CnColors.sky)
            : const Icon(Icons.circle_outlined, color: CnColors.line),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.label, required this.value, required this.c});

  final String label;
  final String value;
  final OrderFormController c;

  @override
  Widget build(BuildContext context) {
    final selected = c.contactMethods.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) {
          c.contactMethods.add(value);
        } else {
          c.contactMethods.remove(value);
        }
        c.saveDraft();
      },
    );
  }
}

/// بخش فایل‌ها: افزودن عکس/سند + لیست + حذف (T5.4).
class FileSection extends StatelessWidget {
  const FileSection({super.key, required this.c});

  final OrderFormController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text(Strings.pickImage, style: TextStyle(fontSize: 13)),
                onPressed: c.uploading.value ? null : c.pickImage,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text(Strings.pickDocument, style: TextStyle(fontSize: 13)),
                onPressed: c.uploading.value ? null : c.pickDocument,
              ),
            ),
          ],
        ),
        if (c.uploading.value) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(Strings.uploadProgress, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
        ...c.files.map((f) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.description_outlined, color: CnColors.sky),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(Formatters.fileSize(f.size),
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: CnColors.rose),
                onPressed: () => c.removeFile(f),
              ),
            )),
      ],
    );
  }
}

/// نوار پایین: برآورد هزینه + دکمه ثبت (T5.3/T5.7).
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.c});

  final OrderFormController c;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Strings.pricePreviewTitle, style: Theme.of(context).textTheme.bodySmall),
                  Obx(() => Text(
                        Formatters.tomanWithUnit(c.pricePreview),
                        style: AppTextStyles.price(context),
                      )),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Obx(() => CnButton(
                    label: Strings.submitOrder,
                    loading: c.submitting.value,
                    onPressed: () async {
                      final ok = await _confirm(context);
                      if (ok == true) c.submit();
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text(Strings.submitOrderConfirmTitle),
        content: const Text(Strings.submitOrderConfirmBody),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text(Strings.cancel)),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text(Strings.yes)),
        ],
      ),
    );
  }
}
