import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_page.dart';

class AlcanciaApp extends ConsumerWidget {
  const AlcanciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider);
    return MaterialApp(
      title: 'Alcancía',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: (name == null || name.isEmpty)
          ? const OnboardingPage()
          : const HomePage(),
    );
  }
}
