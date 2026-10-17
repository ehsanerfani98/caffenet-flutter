import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/profile_controller.dart';

/// Profile — کارت کاربر + لینک‌ها + خروج (T8.2).
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.profileTitle)),
      body: RefreshIndicator(
        onRefresh: controller.refreshMe,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── کارت کاربر ──
            Obx(() {
              final u = controller.user.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: CnColors.skySoft,
                        child: Text(
                          (u?.name.isNotEmpty == true ? u!.name.characters.first : '؟'),
                          style: const TextStyle(
                              fontFamily: 'Peyda', fontSize: 22,
                              fontWeight: FontWeight.w700, color: CnColors.sky),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u?.name.isEmpty == true || u == null
                                    ? Strings.homeGuest
                                    : u!.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 3),
                            Text(Formatters.digits(u?.phone ?? ''),
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Chip(
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  label: Text(controller.roleTitle(u?.role ?? 'customer')),
                                  backgroundColor: u?.role == 'customer'
                                      ? CnColors.emeraldSoft
                                      : CnColors.indigoSoft,
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                      fontSize: 11.5,
                                      color: u?.role == 'customer'
                                          ? CnColors.emerald
                                          : CnColors.indigo),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${Strings.walletBalance}: ${Formatters.toman(u?.walletBalance ?? 0)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: controller.refreshMe,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // ── لینک‌ها ──
            _navTile(context, Icons.account_balance_wallet_outlined, Strings.walletTitle,
                () => Get.offAllNamed('/wallet', predicate: (r) => false)),
            _navTile(context, Icons.receipt_long_outlined, Strings.ordersTitle,
                () => Get.offAllNamed('/orders', predicate: (r) => false)),
            _navTile(context, Icons.settings_outlined, Strings.settingsTitle,
                () => Get.toNamed('/settings')),
            _navTile(context, Icons.gavel_outlined, Strings.settingsTerms,
                () => _open(context, '${Env.appUrl}/terms')),
            _navTile(context, Icons.privacy_tip_outlined, Strings.settingsPrivacy,
                () => _open(context, '${Env.appUrl}/privacy')),

            const SizedBox(height: 20),
            CnButton(
              label: Strings.profileLogout,
              icon: Icons.logout,
              danger: true,
              outlined: true,
              onPressed: controller.logout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CnBottomNav(current: 3),
    );
  }

  Widget _navTile(BuildContext c, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: CnColors.sky),
        title: Text(title, style: c.textTheme.titleSmall),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  void _open(BuildContext c, String url) {
    Get.find<LauncherService>().openExternal(url);
  }
}
