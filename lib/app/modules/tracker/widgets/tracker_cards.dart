import 'package:flutter/material.dart';

import '../../../core/constants/order_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/order_model.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({required this.o});

  final OrderModel o;

  @override
  Widget build(BuildContext context) {
    final message = switch (o.status) {
      'pending_payment' => Strings.trackerInQueue,
      'submitted' => Strings.trackerInQueue,
      'processing' => Strings.trackerProcessing,
      'ready' => Strings.trackerReady,
      'delivered' => 'این سفارش تحویل داده شد.',
      'cancelled' => Strings.orderCancelSuccess,
      'failed' => Strings.paymentFailed,
      _ => Strings.trackerInQueue,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(o.serviceTitle, style: Theme.of(context).textTheme.titleLarge),
                ),
                StatusChip(status: o.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${Strings.orderNumber}: ${o.orderNumber}',
                style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            Row(
              children: [
                Icon(_iconFor(o.status), color: OrderStatus.color(o.status), size: 30),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(message, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            if (o.queuePosition != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CnColors.skySoft.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_list_numbered, color: CnColors.sky, size: 22),
                    const SizedBox(width: 8),
                    Text('${Strings.trackerQueuePositionValue}${Formatters.num(o.queuePosition!)}',
                        style: const TextStyle(
                            fontFamily: 'Peyda', fontSize: 16,
                            fontWeight: FontWeight.w700, color: CnColors.sky)),
                  ],
                ),
              ),
            ],
            if ((o.assignedOperatorName ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${Strings.trackerOperator}: ${o.assignedOperatorName}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String s) => switch (s) {
        'pending_payment' => Icons.schedule_outlined,
        'submitted' => Icons.queue_outlined,
        'processing' => Icons.engineering_outlined,
        'ready' => Icons.task_alt_outlined,
        'delivered' => Icons.mark_email_read_outlined,
        'cancelled' || 'failed' => Icons.error_outline,
        _ => Icons.info_outline,
      };
}

class EtaCard extends StatelessWidget {
  const EtaCard({required this.o});

  final OrderModel o;

  @override
  Widget build(BuildContext context) {
    final hasEta = o.estimatedStartAt != null ||
        (o.estimatedWaitMinutes ?? 0) > 0;
    if (!hasEta && o.status != 'processing') return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _etaCell(
                    context,
                    label: Strings.trackerWait,
                    value: o.estimatedWaitMinutes == null
                        ? '—'
                        : Formatters.durationMinutes(o.estimatedWaitMinutes!),
                  ),
                ),
                Expanded(
                  child: _etaCell(
                    context,
                    label: Strings.trackerDuration,
                    value: o.estimatedDurationMinutes == null
                        ? '—'
                        : Formatters.durationMinutes(o.estimatedDurationMinutes!),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _etaCell(
                    context,
                    label: Strings.trackerStartAt,
                    value: Formatters.time(o.estimatedStartAt),
                  ),
                ),
                Expanded(
                  child: _etaCell(
                    context,
                    label: Strings.trackerEndAt,
                    value: Formatters.time(o.estimatedEndAt),
                  ),
                ),
              ],
            ),
            if (o.noResponseDeadline != null &&
                (o.status == 'ready' || o.status == 'processing')) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: CnColors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('${Strings.trackerNoResponse}: ${Formatters.dateTime(o.noResponseDeadline)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _etaCell(BuildContext c, {required String label, required String value}) {
    return Column(
      children: [
        Text(label, style: c.textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontFamily: 'Peyda', fontSize: 13.5,
                fontWeight: FontWeight.w700, color: c.colorScheme.onSurface)),
      ],
    );
  }
}

