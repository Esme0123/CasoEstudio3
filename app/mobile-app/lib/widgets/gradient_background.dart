import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Fondo de pantalla plano y sólido (sin degradados).
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: child,
    );
  }
}
