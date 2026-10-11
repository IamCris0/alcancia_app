import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider) ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Alcancía')),
      body: Center(
        child: Text(
          '¡Hola, $name! 👋\nPronto verás aquí tu saldo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
