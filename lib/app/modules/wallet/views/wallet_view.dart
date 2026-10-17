import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/cn_cards.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/wallet_controller.dart';

/// Wallet — پورت دقیق Screens.walletPage از wallet.js پله:
/// کارت گرادیانی موجودی → presets گرید ۲ستونه → مبلغ دلخواه + دکمه شارژ
/// → info-box → تاریخچه تراکنش‌ها با ردیف‌های .list-row.
class WalletView extends GetView<WalletController> {
  WalletView({super.key});

  static const List<int> _defaultPresets = [50000, 100000, 200000, 500000];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presets = _presetAmounts();

    return Scaffold(
      appBar: CnBrandBar(
        title: Strings.barWalletT1,
        subtitle: Strings.barWalletT2,
        actions: cnCustomerBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadTransactions(fresh: true);
          await controller.refreshBalance();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            // ── کارت موجودی — گرادیان sky→sky-deep (بدون دکمه، مثل وب) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CnColors.sky, CnColors.skyDeep],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.walletBalanceCard,
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 12,
                          color: Colors.white.withOpacity(.9))),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        Formatters.toman(auth.user.value?.walletBalance ?? 0),
                        style: TextStyle(
                            fontFamily: 'Peyda', fontSize: 26,
                            fontWeight: FontWeight.w900, color: Colors.white,
                            fontFeatures: const [FontFeature.enable('ss01')]),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(Strings.walletShieldNote,
                            style: TextStyle(
                                fontFamily: 'Peyda', fontSize: 11,
                                color: Colors.white.withOpacity(.8))),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── شارژ کیف پول ──
            SectionHeader(title: Strings.walletTopUp, icon: Icons.add_circle_outline_rounded),
            // presets — گرید ۲ستونه svc-card سبک
            LayoutBuilder(builder: (cc, box) {
              const gap = 10.0;
              final w = (box.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final amount in presets)
                    SizedBox(
                      width: w,
                      child: _PresetCard(
                        amount: amount,
                        onTap: () => _onPresetTap(context, amount),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 14),

            // ── مبلغ دلخواه + دکمه شارژ ──
            CnTextField(
              controller: _customCtrl,
              label: Strings.walletCustomAmountLabel,
              hint: Strings.walletCustomHint,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]'))],
            ),
            const SizedBox(height: 12),
            CnButton(
              label: (controller.settings?.bazaarPayEnabled ?? false)
                  ? Strings.walletTopUpBazaarPay
                  : Strings.walletTopUpOnline,
              icon: Icons.account_balance_wallet_rounded,
              emerald: true,
              onPressed: _submitCustom,
            ),

            CnInfoBox(text: Strings.walletInfoBoxText)
                .paddingOnly(top: 16),

            // ── تاریخچه تراکنش‌ها ──
            SectionHeader(title: Strings.walletHistory, icon: Icons.receipt_long_rounded),
            Obx(() {
              final st = controller.txStatus.value;
              if (st.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CnSpinner()),
                );
              }
              if (st.isError) {
                return CnErrorRetry(
                    message: st.errorMessage,
                    onRetry: () => controller.loadTransactions(fresh: true));
              }
              if (st.isEmpty || controller.transactions.isEmpty) {
                return const CnEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: Strings.walletNoTransactions,
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141E33) : CnColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF24324E) : CnColors.line,
                  ),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < controller.transactions.length; i++) ...[
                      _TxRow(t: controller.transactions[i]),
                      if (i < controller.transactions.length - 1)
                        Divider(height: 1, color: isDark ? const Color(0xFF24324E) : CnColors.line),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const CnBottomNav(current: 3),
    );
  }

  // مقدار انتخاب‌شده توسط preset (فقط برای درگاه آنلاین — مثل وب).
  final TextEditingController _customCtrl = TextEditingController();

  List<int> _presetAmounts() {
    final raw = controller.settings?.walletTopUpPresets ?? const [];
    final amounts = raw
        .where((p) => p['sku'] == null) // preset بدون SKU = درگاه وب
        .map((p) => (p['amount'] as num?)?.toInt() ?? 0)
        .where((n) => n > 0)
        .toList();
    return amounts.isNotEmpty ? amounts : _defaultPresets;
  }

  /// رفتار وب: بازارپی → شارژ فوری با همان مبلغ؛
  /// درگاه آنلاین → انتخاب preset و پر شدن فیلد مبلغ دلخواه.
  void _onPresetTap(BuildContext context, int amount) {
    if (controller.settings?.bazaarPayEnabled ?? false) {
      controller.selectedGateway.value = 'bazaarpay';
      controller.startTopUp(amount);
      return;
    }
    controller.selectedGateway.value = 'online';
    _customCtrl.text = '$amount';
    CnSnack.info('${Formatters.toman(amount)} ${Strings.toman}');
  }

  void _submitCustom() {
    final raw = Validators.toLatinDigits(_customCtrl.text.trim());
    final amount = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount < 10000) {
      CnSnack.warning(Strings.walletMinCharge);
      return;
    }
    if (amount > 50000000) {
      CnSnack.warning(Strings.walletMaxCharge);
      return;
    }
    controller.selectedGateway.value =
        (controller.settings?.bazaarPayEnabled ?? false) ? 'bazaarpay' : 'online';
    controller.startTopUp(amount);
  }
}

/// کارت preset — متن‌وسط: مبلغ ۱۴/۸۰۰ sky-deep + «تومان» ۱۰.۵.
class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.amount, required this.onTap});

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF141E33) : CnColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF24324E) : CnColors.line,
            ),
          ),
          child: Column(
            children: [
              Text(Formatters.num(amount),
                  style: const TextStyle(
                      fontFamily: 'Peyda', fontSize: 14,
                      fontWeight: FontWeight.w800, color: CnColors.skyDeep)),
              const SizedBox(height: 2),
              Text(Strings.toman,
                  style: TextStyle(
                      fontFamily: 'Peyda', fontSize: 10.5,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
            ],
          ),
        ),
      ),
    );
  }
}

/// ردیف تراکنش — پورت walletTxnRow() وب:
/// آیکون tone ورود/خروج + عنوان + (تاریخ • موجودی پس از تراکنش) + مبلغ ±.
class _TxRow extends StatelessWidget {
  const _TxRow({required this.t});

  final dynamic t; // WalletTransactionModel

  @override
  Widget build(BuildContext context) {
    final credit = t.isCredit;
    final color = credit ? CnColors.emerald : CnColors.rose;
    final softText = Theme.of(context).colorScheme.onSurface.withOpacity(.6);
    return CnListRow(
      title: t.typeTitle,
      subtitle:
          '${Formatters.dateTime(t.createdAt)} • ${Strings.walletTxAfterBalance} ${Formatters.toman(t.balanceAfter)}',
      icon: credit ? Icons.add_rounded : Icons.arrow_back_rounded,
      tone: color,
      trailing: Text(
        '${credit ? '+' : '−'}${Formatters.toman(t.amount)}',
        style: TextStyle(
            fontFamily: 'Peyda', fontSize: 12.5,
            fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
