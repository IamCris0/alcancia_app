import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/theme_settings.dart';
import '../../core/ui/pressable.dart';

Future<void> showThemeSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => const _ThemeSheet(),
);

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tema', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded),
                  label: Text('Oscuro'),
                ),
              ],
              selected: {settings.mode},
              onSelectionChanged: (s) => notifier.setMode(s.first),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final p in AppPalette.values)
                  Pressable(
                    semanticLabel: p.colors.label,
                    onTap: () => notifier.setPalette(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: p.colors.hero,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: p == settings.palette
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              p.colors.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (p == settings.palette)
                            const Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
