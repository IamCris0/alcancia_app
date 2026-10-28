import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/ui/app_card.dart';
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
    final theme = Theme.of(context);
    final kind = ref.watch(categoryKindProvider);
    final categories = ref.watch(categoriesProvider(kind));

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Categorías',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => showCategoryForm(context, kind: kind),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CategoryKind>(
                segments: const [
                  ButtonSegment(
                    value: CategoryKind.expense,
                    label: Text('Gastos'),
                  ),
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
          ),
          Expanded(
            child: categories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => GridView.builder(
                key: ValueKey(kind),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 130,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final c = list[i];
                  return AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () =>
                            showCategoryForm(context, kind: kind, existing: c),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconBadge(
                              iconKey: c.iconKey,
                              color: Color(c.colorValue),
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              c.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                          ],
                        ),
                      )
                      .animate(delay: (30 * i).ms)
                      .fadeIn(duration: 250.ms)
                      .scaleXY(begin: 0.9, curve: Curves.easeOutBack);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
