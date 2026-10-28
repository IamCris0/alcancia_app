import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import 'category_form.dart';

/// Tipo de categorías que se está viendo (gastos / ingresos).
class CategoryKindNotifier extends Notifier<CategoryKind> {
  @override
  CategoryKind build() => CategoryKind.expense;

  void set(CategoryKind kind) => state = kind;
}

final categoryKindProvider =
    NotifierProvider<CategoryKindNotifier, CategoryKind>(
      CategoryKindNotifier.new,
    );

class CategoriesView extends ConsumerWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(categoryKindProvider);
    final categories = ref.watch(categoriesProvider(kind));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<CategoryKind>(
            segments: const [
              ButtonSegment(value: CategoryKind.expense, label: Text('Gastos')),
              ButtonSegment(
                value: CategoryKind.income,
                label: Text('Ingresos'),
              ),
            ],
            selected: {kind},
            onSelectionChanged: (s) =>
                ref.read(categoryKindProvider.notifier).set(s.first),
          ),
        ),
        Expanded(
          child: categories.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                for (final c in list)
                  Card(
                    child: ListTile(
                      leading: IconBadge(
                        iconKey: c.iconKey,
                        color: Color(c.colorValue),
                      ),
                      title: Text(c.name),
                      onTap: () =>
                          showCategoryForm(context, kind: kind, existing: c),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
