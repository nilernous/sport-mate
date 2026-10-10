import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/shopping_providers.dart';

/// Branch indexes of the shell route in app_router.dart.
abstract final class ShellBranch {
  static const home = 0;
  static const shop = 1;
  static const cart = 2;
  static const account = 3;
  static const admin = 4;
}

class _Destination {
  const _Destination(this.branch, this.icon, this.selectedIcon, this.label);

  final int branch;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Bottom navigation whose tabs depend on the signed-in role:
/// customers and guests shop, Staff/Admin get the Admin Panel instead of a cart.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final cartCount = ref.watch(cartCountProvider);

    final destinations = [
      if (auth.isStaffOrAdmin) const _Destination(ShellBranch.admin, Icons.dashboard_outlined, Icons.dashboard, 'Manage'),
      const _Destination(ShellBranch.home, Icons.home_outlined, Icons.home, 'Home'),
      const _Destination(ShellBranch.shop, Icons.storefront_outlined, Icons.storefront, 'Shop'),
      if (!auth.isStaffOrAdmin) const _Destination(ShellBranch.cart, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Cart'),
      const _Destination(ShellBranch.account, Icons.person_outline, Icons.person, 'Account'),
    ];
    final selected = destinations.indexWhere((d) => d.branch == shell.currentIndex);

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (i) {
          final branch = destinations[i].branch;
          if (branch == ShellBranch.cart && !auth.isLoggedIn) {
            context.push('/login?from=/cart');
            return;
          }
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.branch == ShellBranch.cart && cartCount > 0
                  ? Badge(label: Text('$cartCount'), child: Icon(d.icon))
                  : Icon(d.icon),
              selectedIcon: d.branch == ShellBranch.cart && cartCount > 0
                  ? Badge(label: Text('$cartCount'), child: Icon(d.selectedIcon))
                  : Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
