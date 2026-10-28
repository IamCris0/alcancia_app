import 'package:flutter/material.dart';

/// Iconos disponibles para cuentas y categorías. Se guarda la clave (String)
/// en la base de datos, no el código del icono.
const appIcons = <String, IconData>{
  'restaurant': Icons.restaurant_rounded,
  'coffee': Icons.coffee_rounded,
  'bus': Icons.directions_bus_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'home': Icons.home_rounded,
  'health': Icons.medical_services_rounded,
  'fitness': Icons.fitness_center_rounded,
  'games': Icons.sports_esports_rounded,
  'movie': Icons.movie_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'school': Icons.school_rounded,
  'bill': Icons.receipt_long_rounded,
  'phone': Icons.phone_android_rounded,
  'pets': Icons.pets_rounded,
  'travel': Icons.flight_rounded,
  'payments': Icons.payments_rounded,
  'work': Icons.work_rounded,
  'gift': Icons.card_giftcard_rounded,
  'trending': Icons.trending_up_rounded,
  'savings': Icons.savings_rounded,
  'bank': Icons.account_balance_rounded,
  'card': Icons.credit_card_rounded,
  'wallet': Icons.account_balance_wallet_rounded,
  'other': Icons.more_horiz_rounded,
};

IconData iconFor(String key) => appIcons[key] ?? Icons.category_rounded;
