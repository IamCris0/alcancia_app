import '../../core/database/app_database.dart';

class CategoryTotal {
  const CategoryTotal(this.category, this.total);

  final Category? category;
  final int total;
}

/// Resumen de un mes calculado a partir de sus movimientos.
class MonthSummary {
  MonthSummary._({
    required this.income,
    required this.expense,
    required this.byCategory,
    required this.dailyExpense,
  });

  factory MonthSummary.from(List<MovementDetails> list, DateTime month) {
    var income = 0;
    var expense = 0;
    final byCategory = <int?, CategoryTotal>{};
    final days = DateTime(month.year, month.month + 1, 0).day;
    final daily = List<int>.filled(days, 0);

    for (final d in list) {
      final m = d.movement;
      switch (m.type) {
        case MovementType.income:
          income += m.amount;
        case MovementType.expense:
          expense += m.amount;
          final prev = byCategory[m.categoryId];
          byCategory[m.categoryId] = CategoryTotal(
            d.category,
            (prev?.total ?? 0) + m.amount,
          );
          if (m.date.year == month.year && m.date.month == month.month) {
            daily[m.date.day - 1] += m.amount;
          }
        case MovementType.transfer:
          break;
      }
    }

    final sorted = byCategory.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return MonthSummary._(
      income: income,
      expense: expense,
      byCategory: sorted,
      dailyExpense: daily,
    );
  }

  final int income;
  final int expense;

  /// Gastos por categoría, de mayor a menor.
  final List<CategoryTotal> byCategory;

  /// Gasto de cada día del mes (índice 0 = día 1).
  final List<int> dailyExpense;

  int get net => income - expense;
}
