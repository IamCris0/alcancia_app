import 'app_database.dart';

class AccountWithBalance {
  const AccountWithBalance(this.account, this.balance);

  final Account account;

  /// Saldo inicial + movimientos, en centavos.
  final int balance;
}

class MovementDetails {
  const MovementDetails({
    required this.movement,
    required this.account,
    this.toAccount,
    this.category,
  });

  final Movement movement;
  final Account account;
  final Account? toAccount;
  final Category? category;

  bool get isTransfer => movement.type == MovementType.transfer;

  /// Efecto sobre el patrimonio total: las transferencias no lo cambian.
  int get signedAmount => switch (movement.type) {
    MovementType.income => movement.amount,
    MovementType.expense => -movement.amount,
    MovementType.transfer => 0,
  };
}

/// Filtro para consultar movimientos. Tiene igualdad por valor para poder
/// usarse como parámetro de un provider `family`.
class MovementFilter {
  const MovementFilter({
    this.from,
    this.to,
    this.type,
    this.accountId,
    this.query = '',
    this.limit,
  });

  /// Movimientos del mes que contiene a [month].
  factory MovementFilter.month(
    DateTime month, {
    MovementType? type,
    String query = '',
  }) => MovementFilter(
    from: DateTime(month.year, month.month),
    to: DateTime(month.year, month.month + 1),
    type: type,
    query: query,
  );

  /// Inclusivo.
  final DateTime? from;

  /// Exclusivo.
  final DateTime? to;
  final MovementType? type;
  final int? accountId;
  final String query;
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is MovementFilter &&
      other.from == from &&
      other.to == to &&
      other.type == type &&
      other.accountId == accountId &&
      other.query == query &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(from, to, type, accountId, query, limit);
}
