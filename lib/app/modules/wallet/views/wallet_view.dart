import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/wallet_controller.dart';

/// Wallet — کارت موجودی + تراکنش‌ها + bottom sheet شارژ (T6.2/T6.3).
class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.walletTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: Strings.walletTopUp,
            onPressed: () => _openTopUpSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadTransactions(fresh: true);
          await controller.refreshBalance();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── کارت موجودی ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CnColors.sky, CnColors.skyDeep],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.walletBalance,
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 13,
                          color: Colors.white.withOpacity(.85))),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        Formatters.tomanWithUnit(controller.balance),
                        style: const TextStyle(
                            fontFamily: 'Peyda', fontSize: 28,
                            fontWeight: FontWeight.w700, color: Colors.white),
                      )),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: CnColors.sky,
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(Strings.walletTopUp),
                          onPressed: () => _openTopUpSheet(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: Strings.walletTransactions,
              action: IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => controller.loadTransactions(fresh: true),
              ),
            ),
            Obx(() {
              final st = controller.txStatus.value;
              if (st.isLoading) return const LoadingSkeleton(lines: 4);
              if (st.isError) {
                return CnErrorRetry(
                    message: st.errorMessage,
                    onRetry: () => controller.loadTransactions(fresh: true));
              }
              if (st.isEmpty || controller.transactions.isEmpty) {
                return const CnEmptyState(
                  icon: Icons.receipt_outlined,
                  title: Strings.walletNoTransactions,
                );
              }
              return Column(
                children: controller.transactions
                    .map((t) => _TxTile(
                          typeTitle: t.typeTitle,
                          amount: t.amount,
                          isCredit: t.isCredit,
                          balanceAfter: t.balanceAfter,
                          createdAt: t.createdAt,
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const CnBottomNav(current: 2),
    );
  }

  // ── Bottom sheet شارژ: presets + مبلغ دلخواه + درگاه (T6.3) ──
  void _openTopUpSheet(BuildContext context) {
    final customCtrl = TextEditingController(
      text: controller.prefillAmount > 0 ? '${controller.prefillAmount}' : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Strings.walletTopUp,
                  style: Theme.of(sheetCtx).textTheme.titleLarge),
              const SizedBox(height: 14),

              // presets از settings (T6.3)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in controller.settings?.walletTopUpPresets ?? const [])
                    if (p['sku'] == null) // preset بدون SKU = درگاه وب
                      ChoiceChip(
                        label: Text(Formatters.toman((p['amount'] as num?)?.toInt() ?? 0)),
                        selected: '${(p['amount'] as num?)?.toInt() ?? 0}' ==
                            customCtrl.text,
                        onSelected: (_) {
                          customCtrl.text = '${(p['amount'] as num?)?.toInt() ?? 0}';
                          setState(() {});
                        },
                      ),
                ],
              ),
              const SizedBox(height: 14),

              CnTextField(
                controller: customCtrl,
                label: Strings.topUpCustom,
                hint: '۱۰۰٬۰۰۰',
                keyboardType: TextInputType.number,
                suffix: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 10),
                  child: Text(Strings.toman, style: TextStyle(fontSize: 12.5)),
                ),
              ),

              // ── درگاه‌های مجاز (T6.6) ──
              const SizedBox(height: 14),
              Text(Strings.topUpGateway, style: Theme.of(sheetCtx).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...controller.availableGateways.map((g) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: g.key,
                    groupValue: controller.selectedGateway.value,
                    onChanged: (v) {
                      controller.selectedGateway.value = v!;
                      setState(() {});
                    },
                    title: Row(
                      children: [
                        Icon(g.icon, size: 19, color: CnColors.sky),
                        const SizedBox(width: 8),
                        Text(g.label),
                      ],
                    ),
                  )),

              const SizedBox(height: 12),
              CnButton(
                label: Strings.topUpPay,
                icon: Icons.payment_outlined,
                loading: controller.starting.value,
                onPressed: () {
                  final v = Validators.toLatinDigits(customCtrl.text.trim());
                  final n = int.tryParse(v) ?? 0;
                  final err = Validators.topUpAmount(v);
                  if (err != null) {
                    CnSnack.error(err);
                    return;
                  }
                  Get.back();
                  controller.startTopUp(n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ردیف تراکنش — ورود سبز / خروج قرمز (T6.2).
class _TxTile extends StatelessWidget {
  const _TxTile({
    required this.typeTitle,
    required this.amount,
    required this.isCredit,
    required this.balanceAfter,
    this.createdAt,
  });

  final String typeTitle;
  final int amount;
  final bool isCredit;
  final int balanceAfter;
  final String? createdAt;

  @override
  Widget build(BuildContext context) {
    final color = isCredit ? CnColors.emerald : CnColors.rose;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: color,
        ),
        title: Text(typeTitle, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
            '${Formatters.dateTime(createdAt)} — ${Strings.walletBalance}: ${Formatters.toman(balanceAfter)}',
            style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          '${isCredit ? '+' : '−'}${Formatters.toman(amount)}',
          style: TextStyle(
              fontFamily: 'Peyda', fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}
