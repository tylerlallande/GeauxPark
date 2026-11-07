import 'package:flutter/material.dart';

/// A lightweight, one-shot reveal inspired by FlutterFX motion examples.
///
/// It intentionally avoids blur, shaders, and looping controllers so it stays
/// inexpensive beside the interactive parking map.
class SmoothReveal extends StatelessWidget {
  const SmoothReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
