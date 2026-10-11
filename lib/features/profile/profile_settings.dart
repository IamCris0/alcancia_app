import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/ui/pressable.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';

Future<void> showMascotSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _MascotSheet(),
    );

class _MascotSheet extends ConsumerStatefulWidget {
  const _MascotSheet();

  @override
  ConsumerState<_MascotSheet> createState() => _MascotSheetState();
}

class _MascotSheetState extends ConsumerState<_MascotSheet> {
  late MascotSpecies _species = ref.read(mascotProvider).species;
  late final _name = TextEditingController(text: ref.read(mascotProvider).name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessory = ref.watch(mascotProvider).accessory;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu mascota', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final s in MascotSpecies.values)
                Pressable(
                  semanticLabel: s.style.label,
                  onTap: () => setState(() {
                    // Si el nombre era el sugerido, sugerir el de la nueva.
                    if (_name.text == _species.style.defaultName) {
                      _name.text = s.style.defaultName;
                    }
                    _species = s;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: s == _species
                          ? s.style.bodyDark.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: s == _species
                            ? s.style.bodyDark
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: MascotView(
                      species: s,
                      accessory: accessory,
                      mood: s == _species
                          ? MascotMood.celebrating
                          : MascotMood.happy,
                      size: 64,
                      interactive: false,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.pets_rounded),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await ref.read(mascotProvider.notifier).set(_species, _name.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

Future<void> showCurrencySettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(currencyProvider);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in supportedCurrencies)
                  ListTile(
                    leading: CircleAvatar(child: Text(c.symbol)),
                    title: Text(c.name),
                    subtitle: Text(c.code),
                    trailing: c.code == current
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    onTap: () async {
                      await ref.read(currencyProvider.notifier).set(c.code);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );

Future<void> showNameSettings(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final controller = TextEditingController(
        text: ref.read(userNameProvider),
      );
      return AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref.read(userNameProvider.notifier).set(controller.text);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  ),
);
