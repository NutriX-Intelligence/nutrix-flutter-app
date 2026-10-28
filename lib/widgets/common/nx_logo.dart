import 'package:flutter/material.dart';

/// The NutriX brand mark (transparent PNG, so it sits cleanly on any
/// background in both light and dark mode).
class NxLogo extends StatelessWidget {
  final double size;

  const NxLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'NutriX logo',
    );
  }
}
