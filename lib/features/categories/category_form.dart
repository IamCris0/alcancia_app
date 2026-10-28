import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';

Future<void> showCategoryForm(
  BuildContext context, {
  required CategoryKind kind,
  Category? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CategoryForm(kind: kind, existing: existing),
  );
}

class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({super.key, required this.kind, this.existing});

  final CategoryKind kind;
  final Category? existing;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late Color _color = widget.existing == null
      ? colorPalette.first
      : Color(widget.existing!.colorValue);
  late String _icon = widget.existing?.iconKey ?? 'other';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre');
      return;
    }
    final db = ref.read(databaseProvider);
    final existing = widget.existing;
    if (existing == null) {
      await db.addCategory(
        CategoriesCompanion.insert(
          name: name,
          kind: widget.kind,
          colorValue: _color.toARGB32(),
          iconKey: _icon,
          // Las nuevas van al final de la lista.
          sortOrder: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ),
      );
    } else {
      await db.updateCategory(
        existing.copyWith(
          name: name,
          colorValue: _color.toARGB32(),
          iconKey: _icon,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archive() async {
    await ref.read(databaseProvider).archiveCategory(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar categoría' : 'Nueva categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 16),
            IconPicker(
              selected: _icon,
              color: _color,
              onChanged: (k) => setState(() => _icon = k),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (editing)
              TextButton(
                onPressed: _archive,
                child: const Text('Archivar categoría'),
              ),
          ],
        ),
      ),
    );
  }
}
