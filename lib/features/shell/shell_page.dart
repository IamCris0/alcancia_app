import 'package:flutter/material.dart';

import '../accounts/accounts_view.dart';
import '../categories/categories_view.dart';
import '../dashboard/dashboard_view.dart';
import '../movements/movements_view.dart';
import 'floating_nav_bar.dart';

/// Estructura principal: 4 pestañas + botón central para nuevo movimiento.
/// Al cambiar de pestaña el contenido se desliza en la dirección del cambio.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _tab = 0;
  int _direction = 1;

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

  void _select(int tab) {
    if (tab == _tab) return;
    setState(() {
      _direction = tab > _tab ? 1 : -1;
      _tab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(onSeeAll: () => _select(1)),
      const MovementsView(),
      const AccountsView(),
      const CategoriesView(),
    ];
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          final incoming = child.key == ValueKey(_tab);
          final dx = (incoming ? 0.08 : -0.08) * _direction;
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: Offset(dx, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        selected: _tab,
        onSelected: _select,
        onAdd: (center) => openMovement(context, origin: center),
      ),
    );
  }
}
