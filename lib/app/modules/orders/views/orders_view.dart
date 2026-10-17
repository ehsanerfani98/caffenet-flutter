import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/cn_cards.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/order_model.dart';
import '../controllers/orders_controller.dart';

/// سفارش‌ها — پورت دقیق Screens.orders از landing.js:
/// ردیف چیپ فیلترها + کارت سفارش (شماره فارسی + pill + قیمت sky-deep + تاریخ).
class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CnBrandBar(
        title: Strings.barOrdersT1,
        subtitle: Strings.barOrdersT2,
        actions: cnCustomerBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.load(fresh: true),
        child: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 5);
          if (st.isError) {
            return CnErrorRetry(
                message: st.errorMessage, onRetry: () => controller.load(fresh: true));
          }
          return Column(
            children: [
              // ── چیپ‌های فیلتر ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    itemCount: OrdersController.filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = OrdersController.filters[i];
                      return Obx(() => CnChip(
                            label: f.label,
                            active: controller.filter.value == f.key,
                            onTap: () => controller.filter.value = f.key,
                          ));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final list = controller.filtered;
                  if (st.isEmpty || list.isEmpty) {
                    return CnEmptyState(
                      icon: Icons.folder_outlined,
                      title: controller.filter.value == 'all'
                          ? Strings.noOrders
                          : Strings.noOrdersInFilter,
                      subtitle: controller.filter.value == 'all'
                          ? 'از صفحه خدمات شروع کنید'
                          : null,
                      actionLabel: controller.filter.value == 'all'
                          ? Strings.homeNewOrder
                          : null,
                      onAction: () => Get.offAllNamed(Routes.home, predicate: (r) => false),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (c, i) {
                      final o = list[i];
                      return OrderCard(
                        orderNumber: o.orderNumber,
                        status: o.status,
                        serviceTitle: o.serviceTitle,
                        priceText: Formatters.tomanWithUnit(o.payable),
                        trailing: Formatters.date(o.createdAt),
                        trailingColor: CnColors.inkSoft,
                        onTap: () => controller.openDetail(o.id),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: const CnBottomNav(current: 2),
    );
  }
}
