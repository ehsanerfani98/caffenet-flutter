import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/cn_cards.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../controllers/profile_controller.dart';

/// Profile — پورت دقیق Screens.profile از landing.js پله:
/// کارت وسط‌چین کاربر (آواتار 64 sky-soft radius 20) + ردیف کیف پول +
/// کارت ردیف‌ها + دکمه خروج rose؛ حالت مهمان: کارت ورود + info-box تماس.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? const Color(0xFF24324E) : CnColors.line;
    final cardColor = isDark ? const Color(0xFF141E33) : CnColors.card;

    Widget box({required Widget child, EdgeInsets padding = const EdgeInsets.all(24)}) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: child,
      );
    }

    return Scaffold(
      appBar: CnBrandBar(
        title: Strings.barProfileT1,
        subtitle: Strings.barProfileT2,
        actions: cnCustomerBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshMe,
        child: Obx(() {
          final u = auth.user.value;
          final guest = u == null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            children: [
              if (guest) ...[
                // ── کارت مهمان ──
                box(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: CnColors.skySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 34, color: CnColors.skyDeep),
                      ),
                      const SizedBox(height: 12),
                      Text(Strings.profileGuestName,
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(Strings.profileGuestSub,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                      const SizedBox(height: 16),
                      CnButton(
                        label: Strings.profileLoginCta,
                        icon: Icons.lock_rounded,
                        onPressed: () => Get.toNamed(Routes.auth),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GuestInfoBox(),
              ] else ...[
                // ── کارت کاربر ──
                box(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: CnColors.skySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 34, color: CnColors.skyDeep),
                      ),
                      const SizedBox(height: 12),
                      Text(u!.name.isNotEmpty ? u.name : Strings.profileGuestName,
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(Formatters.digits(u.phone),
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                      const SizedBox(height: 8),
                      // pill نقش — tone submitted مثل وب
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CnColors.skySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(controller.roleTitle(u.role),
                            style: const TextStyle(
                                fontFamily: 'Peyda', fontSize: 11,
                                fontWeight: FontWeight.w700, color: CnColors.skyDeep)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── ردیف کیف پول (فقط مشتری) ──
                if (u.role == 'customer')
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: line),
                    ),
                    child: CnListRow(
                      title: Strings.profileWalletRow,
                      subtitle:
                          '${Strings.walletBalance}: ${Formatters.toman(u.walletBalance)}',
                      icon: Icons.account_balance_wallet_rounded,
                      tone: CnColors.emerald,
                      trailing: Icon(Icons.chevron_left_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(.4)),
                      onTap: () => Get.offAllNamed(Routes.wallet, predicate: (r) => false),
                    ),
                  ),

                // ── کارت ردیف‌ها ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: line),
                  ),
                  child: Column(
                    children: [
                      CnListRow(
                        title: Strings.settingsTitle,
                        subtitle: Strings.settingsTheme,
                        icon: Icons.settings_outlined,
                        tone: CnColors.indigo,
                        onTap: () => Get.toNamed(Routes.settings),
                      ),
                      Divider(height: 1, color: line),
                      CnListRow(
                        title: Strings.profileNotify,
                        subtitle: Strings.profileNotifySub,
                        icon: Icons.notifications_rounded,
                        tone: CnColors.sky,
                        onTap: () => CnSnack.info(Strings.profileNotifySub),
                      ),
                      Divider(height: 1, color: line),
                      CnListRow(
                        title: Strings.profilePrivacy,
                        subtitle: Strings.profilePrivacySub,
                        icon: Icons.shield_rounded,
                        tone: CnColors.slate,
                        onTap: () =>
                            Get.find<LauncherService>().openExternal('${Env.appUrl}/terms'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── خروج ──
                CnButton(
                  label: Strings.profileLogout,
                  icon: Icons.logout_rounded,
                  danger: true,
                  onPressed: controller.logout,
                ),
              ],
            ],
          );
        }),
      ),
      bottomNavigationBar: const CnBottomNav(current: 4),
    );
  }
}

/// info-box مهمان — عنوان سایت بولد + آدرس/تلفن/ساعت کاری (مطابق وب).
class _GuestInfoBox extends StatelessWidget {
  _GuestInfoBox();

  @override
  Widget build(BuildContext context) {
    AppSettings? settings;
    try {
      settings = Get.find<SettingsRepository>().cached;
    } catch (_) {}
    final lines = <String>[
      if ((settings?.coffeenetAddress ?? '').isNotEmpty)
        '${Strings.profileAddressPrefix}${settings!.coffeenetAddress}',
      if ((settings?.coffeenetPhone ?? '').isNotEmpty)
        '${Strings.profilePhonePrefix}${Formatters.digits(settings!.coffeenetPhone!)}',
      if ((settings?.workingHours ?? '').isNotEmpty)
        '${Strings.profileHoursPrefix}${settings!.workingHours}',
    ];
    return CnInfoBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(settings?.siteTitle ?? Strings.appName,
              style: const TextStyle(
                  fontFamily: 'Peyda', fontSize: 12,
                  fontWeight: FontWeight.w700, color: CnColors.skyDeep)),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final l in lines)
              Text(l,
                  style: const TextStyle(
                      fontFamily: 'Peyda', fontSize: 12,
                      height: 1.9, color: CnColors.skyDeep)),
          ],
        ],
      ),
    );
  }
}
