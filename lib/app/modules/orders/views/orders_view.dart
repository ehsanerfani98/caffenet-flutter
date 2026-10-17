import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/order_model.dart';
import '../controllers/orders_controller.dart';
import '../../../core/theme/app_text_styles.dart';

/// لیست سفارش‌ها با فیلتر وضعیت (T7.2).
class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.ordersTitle)),
      body: Column(
        children: [
          // ── فیلترها ──
          SizedBox(
            height: 42,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final f in OrdersController.filters)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(f.label),
                          selected: controller.filter.value == f.key,
                          onSelected: (_) => controller.filter.value = f.key,
                        ),
                      ),
                  ],
                )),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.load(fresh: true),
              child: Obx(() {
                final st = controller.status.value;
                if (st.isLoading) return const LoadingSkeleton(lines: 5);
                if (st.isError) {
                  return CnErrorRetry(
                      message: st.errorMessage,
                      onRetry: () => controller.load(fresh: true));
                }
                final list = controller.filtered;
                if (st.isEmpty || list.isEmpty) {
                  return CnEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: Strings.noOrders,
                    actionLabel: Strings.homeNewOrder,
                    onAction: () => Get.offAllNamed(Routes.home),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (c, i) => _OrderTile(
                    order: list[i],
                    onTap: () => controller.openDetail(list[i].id),
                    onTrack: () => controller.openTracker(list[i].id),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CnBottomNav(current: 1),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap, required this.onTrack});

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order.serviceTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    StatusChip(status: order.status, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${Strings.orderNumber}: ${order.orderNumber} — ${Formatters.date(order.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(Formatters.tomanWithUnit(order.payable),
                        style: AppTextStyles.price(context)),
                    const Spacer(),
                    if (order.isActive)
                      TextButton.icon(
                        icon: const Icon(Icons.gps_fixed, size: 16),
                        label: const Text(Strings.homeTrackOrder,
                            style: TextStyle(fontSize: 12.5)),
                        onPressed: onTrack,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
