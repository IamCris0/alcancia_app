import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/shell_page.dart';
import 'features/splash/splash_page.dart';

class AlcanciaApp extends ConsumerStatefulWidget {
  const AlcanciaApp({super.key});

  @override
  ConsumerState<AlcanciaApp> createState() => _AlcanciaAppState();
}

class _AlcanciaAppState extends ConsumerState<AlcanciaApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider);
    final showSplash = ref.watch(showSplashProvider) && !_splashDone;

    final Widget content;
    if (showSplash) {
      content = SplashPage(
        key: const ValueKey('splash'),
        onDone: () => setState(() => _splashDone = true),
      );
    } else if (name == null || name.isEmpty) {
      content = const OnboardingPage(key: ValueKey('onboarding'));
    } else {
      content = const ShellPage(key: ValueKey('shell'));
    }

    return MaterialApp(
      title: 'Alcancía',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        // La pantalla nueva entra con un leve zoom mientras la anterior se
        // desvanece.
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 1.06, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: content,
      ),
    );
  }
}
