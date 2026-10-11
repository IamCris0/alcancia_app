import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_valid) return;
    await ref.read(userNameProvider.notifier).set(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Placeholder de la mascota (se reemplazará por Rive/Lottie).
              const Text(
                    '🐷',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 96),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: -8,
                    end: 8,
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              Text(
                '¡Hola! Soy Alcancía',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                '¿Cómo te llamas?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ).animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Tu nombre'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ).animate(delay: 350.ms).fadeIn(),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _valid ? _submit : null,
                child: const Text('Comenzar'),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
