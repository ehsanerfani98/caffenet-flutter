import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/order_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/models/order_model.dart';
import '../widgets/tracker_cards.dart';
import '../controllers/tracker_controller.dart';

/// Tracker زنده — نشانگر نوبت + ETA + اسلات + notify-me + لغو (T7.4).
class TrackerView extends GetView<TrackerController> {
  const TrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.trackerTitle)),
      body: Obx(() {
        final st = controller.status.value;
        if (st.isLoading) return const LoadingSkeleton(lines: 3);
        if (st.isError) {
          return CnErrorRetry(message: st.errorMessage, onRetry: controller.reload);
        }
        final o = controller.order.value;
        if (o == null) return const CnEmptyState(title: Strings.noOrders);
        return RefreshIndicator(
          onRefresh: () async => controller.isPublic.value
              ? await controller.searchToken(controller.trackToken.value)
              : null,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LiveBadge(isPublic: controller.isPublic.value),
              StatusCard(o: o),
              EtaCard(o: o),
              if (!controller.isPublic.value) _Actions(c: controller, o: o),
              if (controller.notifications.isNotEmpty) _Notifs(items: controller.notifications),
            ],
          ),
        );
      }),
    );
  }
}

/// نشانگر «زنده» با پالس.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CnColors.emeraldSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: CnColors.emerald, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                isPublic ? Strings.trackPublicTitle : Strings.trackerLive,
                style: const TextStyle(
                    fontFamily: 'Peyda', fontSize: 11.5,
                    fontWeight: FontWeight.w700, color: CnColors.emerald),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// اکشن‌ها: notify-me + رزرو اسلات (long) + لغو.
class _Actions extends StatelessWidget {
  const _Actions({required this.c, required this.o});

  final TrackerController c;
  final OrderModel o;

  @override
  Widget build(BuildContext context) {
    final canAct = OrderStatus.canCancel(o.status);
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CnButton(
                label: Strings.trackerNotifyMe,
                icon: Icons.notifications_active_outlined,
                outlined: true,
                onPressed: c.notifyMe,
              ),
            ),
            if (o.queueType == QueueType.long &&
                (o.reservedSlotId == null || o.reservedSlotId!.isEmpty) &&
                o.status == 'submitted') ...[
              const SizedBox(width: 10),
              Expanded(
                child: CnButton(
                  label: Strings.trackerReserveSlot,
                  icon: Icons.event_available_outlined,
                  onPressed: () => _slotSheet(context),
                ),
              ),
            ],
          ],
        ),
        if (canAct) ...[
          const SizedBox(height: 10),
          CnButton(
            label: Strings.orderCancelTitle,
            outlined: true,
            danger: true,
            onPressed: c.cancel,
          ),
        ],
      ],
    );
  }

  void _slotSheet(BuildContext context) {
    c.loadSlots();
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(Strings.trackerPickSlot,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                if (c.loadingSlots.value)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else if (c.slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(Strings.trackerNoSlots,
                        style: Theme.of(context).textTheme.bodySmall),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: c.slots.length,
                      itemBuilder: (cc, i) {
                        final s = c.slots[i];
                        return ListTile(
                          leading: const Icon(Icons.event_outlined, color: CnColors.sky),
                          title: Text(
                            '${Formatters.dateTime(s.startAt)} — ${Formatters.time(s.endAt)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: s.operatorName.isNotEmpty
                              ? Text('${Strings.trackerOperator}: ${s.operatorName}',
                                  style: Theme.of(context).textTheme.bodySmall)
                              : null,
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => c.reserve(s),
                        );
                      },
                    ),
                  ),
              ],
            )),
      ),
    );
  }
}

class _Notifs extends StatelessWidget {
  const _Notifs({required this.items});

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'اعلان‌ها'),
        for (final n in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.notifications_outlined, color: CnColors.sky),
              title: Text(n.title.isEmpty ? n.type : n.title,
                  style: Theme.of(context).textTheme.titleSmall),
              subtitle: n.body.isNotEmpty
                  ? Text(n.body, style: Theme.of(context).textTheme.bodySmall)
                  : null,
              trailing: n.timestamp == null
                  ? null
                  : Text(Formatters.time(n.timestamp),
                      style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
      ],
    );
  }
}
