import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/shell_page.dart';

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
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: (name == null || name.isEmpty)
            ? const OnboardingPage()
            : const ShellPage(),
      ),
    );
  }
}
