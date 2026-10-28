import '../../core/database/app_database.dart';

extension AccountTypeUi on AccountType {
  String get label => switch (this) {
    AccountType.cash => 'Efectivo',
    AccountType.bank => 'Banco',
    AccountType.card => 'Tarjeta',
    AccountType.savings => 'Ahorro',
  };

  String get iconKey => switch (this) {
    AccountType.cash => 'wallet',
    AccountType.bank => 'bank',
    AccountType.card => 'card',
    AccountType.savings => 'savings',
  };
}
