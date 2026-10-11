import 'package:flutter/material.dart';

import '../accounts/accounts_view.dart';
import '../categories/categories_view.dart';
import '../dashboard/dashboard_view.dart';
import '../movements/movements_view.dart';
import 'floating_nav_bar.dart';

/// Estructura principal: 4 pestañas + botón central para nuevo movimiento.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _tab = 0;

  static const _items = [
    NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    NavItem(
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      'Movimientos',
    ),
    NavItem(
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      'Cuentas',
    ),
    NavItem(Icons.category_outlined, Icons.category_rounded, 'Categorías'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(onSeeAll: () => setState(() => _tab = 1)),
      const MovementsView(),
      const AccountsView(),
      const CategoriesView(),
    ];
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        selected: _tab,
        onSelected: (i) => setState(() => _tab = i),
        onAdd: () => openMovement(context),
      ),
    );
  }
}
