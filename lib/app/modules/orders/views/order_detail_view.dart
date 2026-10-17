import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../controllers/orders_controller.dart';

/// جزئیات سفارش: تایم‌لاین + فرم فقط‌خواندنی + فایل‌ها + تیکت + امتیاز (T7.3).
class OrderDetailView extends GetView<OrderDetailController> {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.ordersTitle),
        actions: [
          Obx(() {
            final o = controller.order.value;
            if (o == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.gps_fixed),
              tooltip: Strings.trackerTitle,
              onPressed: () =>
                  Get.toNamed(Routes.tracker, arguments: {'orderId': o.id}),
            );
          }),
        ],
      ),
      body: Obx(() {
        final st = controller.status.value;
        if (st.isLoading) return const LoadingSkeleton(lines: 4);
        if (st.isError) {
          return CnErrorRetry(message: st.errorMessage, onRetry: () => controller.load());
        }
        final o = controller.order.value;
        if (o == null) return const CnEmptyState(title: Strings.noOrders);
        return RefreshIndicator(
          onRefresh: () => controller.load(fresh: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(o: o),
              if (OrderStatus.canCancel(o.status) && o.status != 'refunded') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CnButton(
                        label: Strings.orderCancelTitle,
                        outlined: true,
                        danger: true,
                        onPressed: controller.cancel,
                      ),
                    ),
                    if (o.status == 'pending_payment') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: CnButton(
                          label: Strings.checkoutWalletPay,
                          onPressed: () =>
                              Get.toNamed(Routes.checkout, arguments: o),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              _Timeline(logs: o.logs),
              _FormDataSection(o: o),
              _FilesSection(o: o),
              _TicketSection(c: controller),
              if (controller.canRate) _RatingSection(c: controller),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.o});

  final OrderModel o;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(o.serviceTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                StatusChip(status: o.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('${Strings.orderNumber}: ${o.orderNumber}',
                style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            PriceRow(label: Strings.orderTotal, amount: Formatters.tomanWithUnit(o.totalPrice)),
            if (o.discountAmount > 0)
              PriceRow(label: Strings.discount, amount: '−${Formatters.tomanWithUnit(o.discountAmount)}',
                  color: CnColors.emerald),
            PriceRow(label: Strings.payable, amount: Formatters.tomanWithUnit(o.payable), bold: true),
            if (o.trackToken != null && o.trackToken!.isNotEmpty) ...[
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.link, size: 20, color: CnColors.sky),
                title: Text(Strings.trackTokenLink,
                    style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(
                  '…/track/${o.trackToken}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    final url = '${Env.appUrl}/track/${o.trackToken}';
                    Clipboard.setData(ClipboardData(text: url));
                    CnSnack.success('لینک پیگیری کپی شد.');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.logs});

  final List<OrderLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: Strings.orderTimeline),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final l in logs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                              color: CnColors.sky, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.action, style: Theme.of(context).textTheme.bodyMedium),
                              Text(
                                '${Formatters.dateTime(l.timestamp)}${l.performedBy.isNotEmpty ? ' — ${l.performedBy}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (l.note.isNotEmpty)
                                Text(l.note, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// helper مپ label فیلدها از کاتالوگ (اگر کش شده باشد).
String? _fieldLabel(ServiceModel? s, String key) {
  if (s == null) return null;
  for (final f in s.fields) {
    if (f.id == key) return f.label;
  }
  return null;
}

class _FormDataSection extends StatelessWidget {
  const _FormDataSection({required this.o});

  final OrderModel o;

  @override
  Widget build(BuildContext context) {
    if (o.formData.isEmpty) return const SizedBox.shrink();
    ServiceModel? service;
    try {
      final repo = Get.find<CatalogRepository>();
      for (final s in repo.servicesRx) {
        if (s.id == o.serviceId) {
          service = s;
          break;
        }
      }
    } catch (_) {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: Strings.orderFormData),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final e in o.formData.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_fieldLabel(service, e.key) ?? e.key}: ',
                            style: Theme.of(context).textTheme.bodySmall),
                        Expanded(
                          child: Text('${e.value}',
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                if (o.customerNote != null && o.customerNote!.isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(o.customerNote!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({required this.o});

  final OrderModel o;

  @override
  Widget build(BuildContext context) {
    if (o.customerFiles.isEmpty && o.resultFiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: Strings.orderFiles),
        if (o.customerFiles.isNotEmpty)
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(Strings.orderCustomerFiles,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                ),
                for (final f in o.customerFiles) _fileTile(context, f),
              ],
            ),
          ),
        if (o.resultFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: CnColors.emeraldSoft.withOpacity(.4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(Strings.orderResultFiles,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                ),
                for (final f in o.resultFiles) _fileTile(context, f),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _fileTile(BuildContext context, UploadedFile f) {
    final filename = f.url.split('/').last;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.description_outlined, color: CnColors.sky),
      title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(Formatters.fileSize(f.size),
          style: Theme.of(context).textTheme.bodySmall),
      trailing: TextButton.icon(
        icon: const Icon(Icons.download, size: 17),
        label: const Text(Strings.orderDownloadFile, style: TextStyle(fontSize: 12.5)),
        onPressed: () => _download(context, filename),
      ),
    );
  }

  /// دانلود فایل با توکن (BE-4: GET /api/uploads/{filename}) → share/save.
  Future<void> _download(BuildContext context, String filename) async {
    try {
      final api = Get.find<ApiClient>();
      final bytes = await api.download('uploads/$filename');
      CnSnack.success('فایل دریافت شد (${Formatters.fileSize(bytes.length)}).');
      // ذخیره/اشتراک فایل با share sheet سیستم — MVP: snackbar.
    } on ApiError catch (e) {
      CnSnack.error(e.message);
    }
  }
}

/// گفتگوی تیکت سفارش (T7.6).
class _TicketSection extends StatelessWidget {
  const _TicketSection({required this.c});

  final OrderDetailController c;

  @override
  Widget build(BuildContext context) {
    final o = c.order.value;
    final msgs = o?.ticketMessages ?? const <TicketMessage>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: Strings.orderTicketTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (msgs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(Strings.orderNoTicket,
                        style: Theme.of(context).textTheme.bodySmall),
                  )
                else
                  ...msgs.map((m) => Align(
                        alignment: m.isMine
                            ? AlignmentDirectional.centerStart
                            : AlignmentDirectional.centerEnd,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .75),
                          decoration: BoxDecoration(
                            color: m.isMine ? CnColors.skySoft : CnColors.slateSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m.senderName} — ${Formatters.dateTime(m.timestamp)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(m.message,
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      )),
                const Divider(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: c.ticketCtrl,
                        decoration: const InputDecoration(
                            hintText: Strings.orderTicketHint),
                        onSubmitted: (_) => c.sendTicket(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() => IconButton.filled(
                          onPressed: c.ticketSending.value ? null : c.sendTicket,
                          icon: c.ticketSending.value
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, size: 19),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// امتیازدهی بعد از delivered (T7.7).
class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.c});

  final OrderDetailController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: Strings.orderRateTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final v = i + 1;
                        return IconButton(
                          icon: Icon(
                            v <= c.rating.value ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: CnColors.amber,
                            size: 34,
                          ),
                          onPressed: () => c.rating.value = v,
                        );
                      }),
                    )),
                CnTextField(
                  controller: c.reviewCtrl,
                  hint: Strings.orderRateHint,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Obx(() => CnButton(
                      label: Strings.orderRateSubmit,
                      loading: c.ratingSaving.value,
                      onPressed: c.saveRating,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
