import 'piggy_mascot.dart';

/// Estado de ánimo de la mascota según cómo va el mes.
MascotMood moodFor({required int income, required int expense}) {
  if (income == 0 && expense == 0) return MascotMood.sleeping;
  if (expense > income) {
    return income == 0 ? MascotMood.neutral : MascotMood.worried;
  }
  return MascotMood.happy;
}

String moodMessage(MascotMood mood) => switch (mood) {
  MascotMood.happy => '¡Vas muy bien este mes!',
  MascotMood.neutral => 'Registra tus ingresos para ver tu balance.',
  MascotMood.worried => 'Ojo: este mes sale más de lo que entra.',
  MascotMood.sleeping => 'Zzz… registra tu primer movimiento.',
};
