import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema de diseño de FisuraScan.
///
/// Estilo profesional y plano: tema claro, colores sólidos (sin degradados ni
/// tonos neón), bordes sutiles y sombras suaves.
class AppColors {
  AppColors._();

  // Fondos y superficies
  static const Color bg = Color(0xFFF4F6F9); // fondo de la app
  static const Color surface = Color(0xFFFFFFFF); // tarjetas
  static const Color surfaceAlt = Color(0xFFEDF1F5); // inputs, segmentos
  static const Color stroke = Color(0xFFDCE2EA); // bordes
  static const Color strokeStrong = Color(0xFFC6CFDA);

  // Marca (azul corporativo sólido)
  static const Color primary = Color(0xFF1F5FA8);
  static const Color primaryDark = Color(0xFF174B86);
  static const Color primarySoft = Color(0xFFE7EFF8); // fondo tenue

  // Texto
  static const Color textHi = Color(0xFF1A2330);
  static const Color textMid = Color(0xFF55606E);
  static const Color textLow = Color(0xFF8A94A2);

  // Semánticos (tonos apagados, no neón)
  static const Color danger = Color(0xFFC0413A); // con grieta
  static const Color dangerSoft = Color(0xFFF9EBEA);
  static const Color success = Color(0xFF2E7D5B); // sin grieta
  static const Color successSoft = Color(0xFFE8F2EC);
  static const Color warning = Color(0xFFB26A12);
  static const Color warningSoft = Color(0xFFF8F0E2);

  // Sombra base
  static Color get shadow => const Color(0xFF1A2330).withValues(alpha: 0.08);
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textHi,
          displayColor: AppColors.textHi,
          fontFamily: 'Roboto',
        )
        .copyWith(
          displaySmall: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.textHi,
          ),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textHi,
          ),
          titleMedium: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
          bodyMedium: const TextStyle(color: AppColors.textMid, height: 1.45),
          labelLarge: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textHi),
        titleTextStyle: TextStyle(
          color: AppColors.textHi,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      dividerColor: AppColors.stroke,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textHi,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
