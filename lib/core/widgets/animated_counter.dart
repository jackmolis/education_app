import 'package:flutter/material.dart';

/// Smoothly animates a number from 0 to [end] using a Tween counter.
class AnimatedCounter extends StatelessWidget {
  final int end;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.end,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: end),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: style ?? const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
