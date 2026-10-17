import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import '../values/strings.dart';

/// Bottom nav — پورت دقیق .bottom-nav از CSS پله:
/// نوار سفید با حاشیه بالا، بدون indicator متریال؛
/// آیکون 22 + برچسب 10.5/600؛ فعال sky؛ badge قرمز (سفارش‌های در جریان).
/// چینش نقش‌محور مثل app.js:
///   مهمان:    خانه / دسته‌بندی / پروفایل
///   مشتری:    خانه / دسته‌بندی / سفارش‌ها / کیف پول / پروفایل
class CnBottomNav extends StatelessWidget {
  const CnBottomNav({super.key, required this.current, this.pendingBadge});

  /// ایندکس فعال در لیست آیتم‌های نقش فعلی.
  final int current;

  /// تعداد سفارش‌های در جریان (badge قرمز روی تب سفارش‌ها).
  final int? pendingBadge;

  static const _badgeColor = Color(0xFFE11D48);

  List<({String route, IconData icon, IconData activeIcon, String label, bool badge})> _items(
      String? role) {
    if (role == null) {
      return const [
        (route: Routes.home, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: Strings.navHome, badge: false),
        (route: Routes.catalog, icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: Strings.navCatalog, badge: false),
        (route: Routes.profile, icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: Strings.navProfile, badge: false),
      ];
    }
    return const [
      (route: Routes.home, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: Strings.navHome, badge: false),
      (route: Routes.catalog, icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: Strings.navCatalog, badge: false),
      (route: Routes.orders, icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded, label: Strings.navOrders, badge: true),
      (route: Routes.wallet, icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: Strings.navWallet, badge: false),
      (route: Routes.profile, icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: Strings.navProfile, badge: false),
    ];
  }

  void _go(String route) {
    // مثل وب: ناوبری تب‌ها کل استک را پاک می‌کند.
    Get.offAllNamed(route, predicate: (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? const Color(0xFF24324E) : CnColors.line;
    final cardColor = isDark ? const Color(0xFF141E33) : CnColors.card;
    final role = Get.find<AuthService>().user.value?.role;
    final items = _items(role);
    final active = current.clamp(0, items.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: CnColors.dark.withOpacity(.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: line)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    active: i == active,
                    badge: (items[i].badge && pendingBadge != null && pendingBadge! > 0)
                        ? pendingBadge
                        : null,
                    onTap: () => _go(items[i].route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final ({String route, IconData icon, IconData activeIcon, String label, bool badge}) item;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? CnColors.sky : CnColors.inkSoft;
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(item.label,
                  style: TextStyle(
                      fontFamily: 'Peyda', fontSize: 10.5,
                      fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 6,
              end: MediaQuery.of(context).size.width / (5 * 2) - 20,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: CnBottomNav._badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    Formatters.num(badge!),
                    style: const TextStyle(
                        fontFamily: 'Peyda', fontSize: 9.5,
                        fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
