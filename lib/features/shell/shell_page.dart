import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/dashboard_view.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../movements/movements_view.dart';
import '../plans/plans_providers.dart';
import '../plans/plans_view.dart';
import '../profile/profile_view.dart';
import 'floating_nav_bar.dart';

/// Estructura principal: 4 pestañas + botón central para nuevo movimiento.
/// Al cambiar de pestaña el contenido se desliza en la dirección del cambio.
class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  int _tab = 0;
  int _direction = 1;

  static const _items = [
    NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    NavItem(
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      'Movimientos',
    ),
    NavItem(Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Metas'),
    NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    // Al abrir: premiar meses cerrados y logros pendientes.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Primero los recurrentes automáticos vencidos, luego premios.
      await ref.read(recurringServiceProvider).processDue();
      final result = await ref.read(gamificationServiceProvider).syncOnStart();
      if (!mounted) return;
      await syncReminders(ProviderScope.containerOf(context, listen: false));
      if (mounted && result.hasCelebrations) {
        await showCelebrations(context, result);
      }
    });
  }

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
      DashboardView(
        onSeeAll: () => _select(1),
        onOpenProfile: () => _select(3),
      ),
      const MovementsView(),
      const PlansView(),
      const ProfileView(),
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
