import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../values/strings.dart';

/// Bottom nav مشترک ۴ تبه Home/Orders/Wallet/Profile.
class CnBottomNav extends StatelessWidget {
  const CnBottomNav({super.key, required this.current});

  final int current;

  static const List<_NavItem> _items = [
    _NavItem(route: Routes.home, icon: Icons.home_outlined, activeIcon: Icons.home, label: Strings.navHome),
    _NavItem(route: Routes.orders, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: Strings.navOrders),
    _NavItem(route: Routes.wallet, icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: Strings.navWallet),
    _NavItem(route: Routes.profile, icon: Icons.person_outline, activeIcon: Icons.person, label: Strings.navProfile),
  ];

  void _go(int i) {
    if (i == current) return;
    Get.offAllNamed(_items[i].route, predicate: (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current,
      onDestinationSelected: _go,
      destinations: [
        for (var i = 0; i < _items.length; i++)
          NavigationDestination(
            icon: Icon(_items[i].icon),
            selectedIcon: Icon(_items[i].activeIcon),
            label: _items[i].label,
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({required this.route, required this.icon, required this.activeIcon, required this.label});
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
