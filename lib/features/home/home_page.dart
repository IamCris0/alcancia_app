import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/account_form.dart';
import '../accounts/accounts_view.dart';
import '../categories/categories_view.dart';
import '../categories/category_form.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final onAccounts = _tab == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Alcancía')),
      body: onAccounts ? const AccountsView() : const CategoriesView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onAccounts
            ? showAccountForm(context)
            : showCategoryForm(context, kind: ref.read(categoryKindProvider)),
        icon: const Icon(Icons.add_rounded),
        label: Text(onAccounts ? 'Cuenta' : 'Categoría'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categorías',
          ),
        ],
      ),
    );
  }
}
