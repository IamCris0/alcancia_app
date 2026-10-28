import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/theme.dart';

extension MovementTypeUi on MovementType {
  String get label => switch (this) {
    MovementType.expense => 'Gasto',
    MovementType.income => 'Ingreso',
    MovementType.transfer => 'Transferencia',
  };

  Color get color => switch (this) {
    MovementType.expense => AppColors.expense,
    MovementType.income => AppColors.income,
    MovementType.transfer => AppColors.transfer,
  };

  IconData get icon => switch (this) {
    MovementType.expense => Icons.south_east_rounded,
    MovementType.income => Icons.north_east_rounded,
    MovementType.transfer => Icons.swap_horiz_rounded,
  };

  CategoryKind? get categoryKind => switch (this) {
    MovementType.expense => CategoryKind.expense,
    MovementType.income => CategoryKind.income,
    MovementType.transfer => null,
  };
}
