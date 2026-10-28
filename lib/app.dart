import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'core/motion/iris_reveal.dart';
import 'core/theme_settings.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/security/lock_screen.dart';
import 'features/shell/shell_page.dart';
import 'features/splash/splash_page.dart';

class PlataPetsApp extends ConsumerStatefulWidget {
  const PlataPetsApp({super.key});

  @override
  ConsumerState<PlataPetsApp> createState() => _PlataPetsAppState();
}

class _PlataPetsAppState extends ConsumerState<PlataPetsApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    // La paleta se aplica antes de construir el tema.
    AppColors.use(themeSettings.palette);
    ref.listen(themeSettingsProvider, (prev, next) {
      if (prev?.palette != next.palette) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => rebuildAllChildren(context),
        );
      }
    });
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
      content = const LockGate(key: ValueKey('shell'), child: ShellPage());
    }

    return MaterialApp(
      title: 'PlataPets',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeSettings.mode,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        // Apertura tipo "iris": la intro se acerca y se desvanece mientras
        // la app aparece desde un círculo que crece en el centro.
        transitionBuilder: (child, anim) {
          if (child.key == const ValueKey('splash')) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 1.35, end: 1.0).animate(anim),
                child: child,
              ),
            );
          }
          return IrisReveal(animation: anim, child: child);
        },
        child: content,
      ),
    );
  }
}
