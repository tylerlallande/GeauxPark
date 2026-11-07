import 'package:flutter/material.dart';

/// A finite loading sheen inspired by FlutterFX's shimmer examples.
///
/// The animation runs once instead of looping, which keeps widget tests
/// deterministic and avoids continuous painting on slower demo devices.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 16,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + value * 2.5, 0),
            end: Alignment(-0.5 + value * 2.5, 0),
            colors: [
              colors.surfaceContainerHighest,
              Color.lerp(colors.surfaceContainerHighest, colors.surface, 0.7)!,
              colors.surfaceContainerHighest,
            ],
          ),
        ),
      ),
    );
  }
}
