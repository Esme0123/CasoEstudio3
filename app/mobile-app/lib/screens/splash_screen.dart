import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/gradient_background.dart';
import 'shell_screen.dart';

/// Pantalla de bienvenida con animación de entrada.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondary) => const ShellScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AnimatedBrandLogo(size: 104),
                  const SizedBox(height: 28),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Fisura',
                          style: TextStyle(
                            color: AppColors.textHi,
                            fontWeight: FontWeight.w800,
                            fontSize: 34,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: 'Scan',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 34,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.tagline,
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
