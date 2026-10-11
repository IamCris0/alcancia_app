import 'package:flutter/material.dart';

/// Texto que aparece letra a letra. El espacio final se reserva desde el
/// inicio (letras transparentes) para que el diseño no salte.
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.charDuration = const Duration(milliseconds: 26),
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final Duration delay;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  Future<void> _start() async {
    _c.duration = widget.charDuration * widget.text.length;
    _c.value = 0;
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.text, style: style);
    }
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final n = (widget.text.length * _c.value).round();
            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: widget.text.substring(0, n)),
                  TextSpan(
                    text: widget.text.substring(n),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ],
              ),
              style: style,
            );
          },
        ),
      ),
    );
  }
}
