import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/motion/aurora.dart';
import '../../core/motion/confetti.dart';
import '../../core/motion/floating_coins.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../accounts/account_type_ui.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';

/// Onboarding en 3 pasos: nombre → mascota → primera cuenta.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _name = TextEditingController();
  final _petName = TextEditingController(
    text: MascotSpecies.pig.style.defaultName,
  );
  final _accountName = TextEditingController(text: 'Efectivo');
  final _balance = TextEditingController();
  final _pets = PageController(viewportFraction: 0.62);
  int _step = 0;
  int _direction = 1;
  MascotSpecies _species = MascotSpecies.pig;
  bool _petNameEdited = false;
  String _currency = 'USD';
  String? _error;
  bool _saving = false;
  bool _done = false;

  @override
  void dispose() {
    _name.dispose();
    _petName.dispose();
    _accountName.dispose();
    _balance.dispose();
    _pets.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _direction = step > _step ? 1 : -1;
      _step = step;
      _error = null;
    });
    if (step == 1) {
      // Al volver al carrusel, que muestre la mascota ya elegida.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final index = MascotSpecies.values.indexOf(_species);
        if (_pets.hasClients && _pets.page?.round() != index) {
          _pets.jumpToPage(index);
        }
      });
    }
  }

  void _selectSpecies(int index) {
    final species = MascotSpecies.values[index];
    setState(() {
      _species = species;
      if (!_petNameEdited) _petName.text = species.style.defaultName;
    });
  }

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
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _saving = true;
    });
    await ref.read(currencyProvider.notifier).set(_currency);
    await ref.read(mascotProvider.notifier).set(_species, _petName.text);
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
    if (!mounted) return;
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    // El nombre se guarda al final: su presencia marca el onboarding como hecho.
    await ref.read(userNameProvider.notifier).set(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final steps = [_nameStep, _petStep, _accountStep];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AuroraBackground(
              colors: const [
                AppColors.brand,
                AppColors.pink,
                Color(0xFF4DABF7),
              ],
              opacity: dark ? 0.22 : 0.16,
            ),
          ),
          // Discretas: no deben competir con el texto ni los botones.
          const Positioned.fill(child: FloatingCoins(count: 6, opacity: 0.18)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _step > 0 && !_saving ? 1 : 0,
                        child: IconButton(
                          tooltip: 'Atrás',
                          onPressed: _step > 0 && !_saving
                              ? () => _go(_step - 1)
                              : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      Expanded(
                        child: Center(child: _StepDots(step: _step)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final incoming = child.key == ValueKey(_step);
                      final dx = (incoming ? 0.25 : -0.25) * _direction;
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
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: steps[_step](context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_done)
            _FinishOverlay(
              species: _species,
              userName: _name.text.trim(),
              petName: _petName.text.trim(),
            ),
        ],
      ),
    );
  }

  Widget _nameStep(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(child: MascotView(species: _species, size: 170))
              .animate()
              .scaleXY(begin: 0.4, duration: 800.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 24),
          Text(
            '¡Hola! Bienvenido a PlataPets',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),
          const SizedBox(height: 8),
          Text(
            '¿Cómo te llamas?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Tu nombre'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _nameValid ? _go(1) : null,
          ).animate(delay: 420.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _nameValid ? () => _go(1) : null,
            child: const Text('Continuar'),
          ).animate(delay: 540.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _petStep(BuildContext context) {
    final theme = Theme.of(context);
    final index = MascotSpecies.values.indexOf(_species);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Elige tu compañero',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Te acompañará y reaccionará a tus finanzas.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 270,
            child: PageView.builder(
              controller: _pets,
              itemCount: MascotSpecies.values.length,
              onPageChanged: _selectSpecies,
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _pets,
                builder: (context, child) {
                  final page = _pets.hasClients && _pets.position.haveDimensions
                      ? _pets.page!
                      : index.toDouble();
                  final diff = min((page - i).abs(), 1.0);
                  return Opacity(
                    opacity: 1 - diff * 0.45,
                    child: Transform.scale(scale: 1 - diff * 0.2, child: child),
                  );
                },
                child: _PetCard(
                  species: MascotSpecies.values[i],
                  selected: i == index,
                  onTap: () => _pets.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < MascotSpecies.values.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index
                        ? _species.style.bodyDark
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _petName,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de tu mascota',
                    prefixIcon: Icon(Icons.pets_rounded),
                  ),
                  onChanged: (_) => _petNameEdited = true,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _go(2),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountStep(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MascotView(species: _species, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encantado, ${_name.text.trim()} 🎉',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configuremos tu primera cuenta.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Moneda'),
            items: [
              for (final c in supportedCurrencies)
                DropdownMenuItem(
                  value: c.code,
                  child: Text(
                    '${c.code} · ${c.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _currency = v ?? _currency),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          TextField(
            controller: _accountName,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre de la cuenta'),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
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
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ).animate().shakeX(hz: 5, amount: 4),
                  ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _finish,
            child: const Text('Empezar'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == step ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step
                  ? AppColors.brand
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final MascotSpecies species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = species.style;
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              style.bodyDark.withValues(alpha: selected ? 0.35 : 0.18),
              theme.colorScheme.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? style.bodyDark : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: style.bodyDark.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : softShadow(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MascotView(
              species: species,
              mood: selected ? MascotMood.celebrating : MascotMood.happy,
              size: 150,
              interactive: selected,
            ),
            const SizedBox(height: 8),
            Text(style.label, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _FinishOverlay extends StatelessWidget {
  const _FinishOverlay({
    required this.species,
    required this.userName,
    required this.petName,
  });

  final MascotSpecies species;
  final String userName;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        child: Stack(
          children: [
            const Positioned.fill(child: ConfettiBurst(count: 70)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MascotView(
                    species: species,
                    mood: MascotMood.celebrating,
                    size: 180,
                    interactive: false,
                  ).animate().scaleXY(
                    begin: 0.3,
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Todo listo, $userName!',
                    style: theme.textTheme.headlineSmall,
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.4),
                  const SizedBox(height: 6),
                  Text(
                    '$petName ya está cuidando tus monedas',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).animate(delay: 400.ms).fadeIn(),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms),
    );
  }
}
