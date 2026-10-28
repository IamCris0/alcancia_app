import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import '../accounts/account_type_ui.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _name = TextEditingController();
  final _accountName = TextEditingController(text: 'Efectivo');
  final _balance = TextEditingController();
  int _step = 0;
  String _currency = 'USD';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _accountName.dispose();
    _balance.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;

  Future<void> _finish() async {
    final accountName = _accountName.text.trim();
    final raw = _balance.text.trim();
    final cents = raw.isEmpty ? 0 : parseMoneyToCents(raw);
    if (accountName.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la cuenta');
      return;
    }
    if (cents == null) {
      setState(() => _error = 'Saldo inválido');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    await ref.read(currencyProvider.notifier).set(_currency);
    await ref
        .read(databaseProvider)
        .addAccount(
          AccountsCompanion.insert(
            name: accountName,
            type: AccountType.cash,
            colorValue: colorPalette.first.toARGB32(),
            iconKey: AccountType.cash.iconKey,
            initialBalance: Value(cents),
          ),
        );
    // El nombre se guarda al final: su presencia marca el onboarding como hecho.
    await ref.read(userNameProvider.notifier).set(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: 300.ms,
            child: _step == 0 ? _nameStep(context) : _accountStep(context),
          ),
        ),
      ),
    );
  }

  Widget _nameStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('name'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Placeholder de la mascota (se reemplazará por Rive/Lottie).
        const Text(
              '🐷',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 96),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -8,
              end: 8,
              duration: 900.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 24),
        Text(
          '¡Hola! Soy Alcancía',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().slideY(begin: 0.3),
        const SizedBox(height: 8),
        Text(
          '¿Cómo te llamas?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Tu nombre'),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _nameValid ? setState(() => _step = 1) : null,
        ).animate(delay: 350.ms).fadeIn(),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _nameValid ? () => setState(() => _step = 1) : null,
          child: const Text('Continuar'),
        ).animate(delay: 500.ms).fadeIn(),
      ],
    );
  }

  Widget _accountStep(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('account'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Encantado, ${_name.text.trim()} 🎉',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configuremos tu primera cuenta.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Moneda'),
            items: [
              for (final c in supportedCurrencies)
                DropdownMenuItem(
                  value: c.code,
                  child: Text('${c.code} · ${c.name}'),
                ),
            ],
            onChanged: (v) => setState(() => _currency = v ?? _currency),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountName,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre de la cuenta'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _balance,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Saldo actual (opcional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _finish,
            child: const Text('Empezar'),
          ),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _step = 0),
            child: const Text('Atrás'),
          ),
        ],
      ),
    );
  }
}
