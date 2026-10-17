import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/checkout_controller.dart';
import '../../../core/theme/app_text_styles.dart';

/// صفحه پرداخت سفارش — خلاصه + موجودی + دکمه پرداخت کیف پولی (T5.8).
class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final o = controller.order;
    if (o == null) {
      return const Scaffold(body: CnEmptyState(title: Strings.noOrders));
    }
    final enough = controller.balance >= o.payable;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.checkoutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── خلاصه سفارش ──
          Card(
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
                      StatusChip(status: o.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${Strings.orderNumber}: ${o.orderNumber}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Divider(height: 24),
                  PriceRow(label: Strings.orderTotal, amount: Formatters.tomanWithUnit(o.totalPrice)),
                  if (o.discountAmount > 0)
                    PriceRow(
                      label: '${Strings.discount}${o.discountAmount}',
                      amount: '−${Formatters.tomanWithUnit(o.discountAmount)}',
                      color: CnColors.emerald,
                    ),
                  const Divider(height: 24),
                  PriceRow(
                    label: Strings.payable,
                    amount: Formatters.tomanWithUnit(o.payable),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── موجودی ──
          Card(
            color: enough ? CnColors.emeraldSoft.withOpacity(.5) : CnColors.amberSoft,
            child: ListTile(
              leading: Icon(
                enough ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: enough ? CnColors.emerald : CnColors.amber,
              ),
              title: Text(Strings.checkoutBalance, style: Theme.of(context).textTheme.titleSmall),
              subtitle: Obx(() => Text(
                    '${Formatters.tomanWithUnit(controller.balance)}',
                    style: AppTextStyles.price(context,
                        color: enough ? CnColors.emerald : CnColors.amber),
                  )),
              trailing: TextButton(
                onPressed: controller.refreshBalance,
                child: const Icon(Icons.refresh, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => CnButton(
                label: Strings.checkoutWalletPay,
                icon: Icons.account_balance_wallet_outlined,
                loading: controller.paying.value,
                onPressed: controller.pay,
              )),
          if (!enough) ...[
            const SizedBox(height: 10),
            CnButton(
              label: Strings.topUpNow,
              outlined: true,
              onPressed: () => Get.toNamed('/wallet',
                  arguments: {'topUpAmount': o.payable - controller.balance}),
            ),
          ],
        ],
      ),
    );
  }
}
