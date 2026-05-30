import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Constantes globales y valores por defecto de FisuraScan.
class AppConstants {
  AppConstants._();

  static const String appName = 'FisuraScan';
  static const String tagline = 'Detección de grietas con IA';

  /// URL por defecto del backend según la plataforma de ejecución.
  ///
  /// - Emulador Android: `10.0.2.2` apunta al `localhost` del host.
  /// - iOS simulator / escritorio / web: `localhost`.
  /// En dispositivo físico el usuario debe poner la IP LAN de su máquina
  /// desde la pantalla de Ajustes.
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {
      // Platform no disponible (web): ignorado.
    }
    return 'http://localhost:8000';
  }

  /// Clave de SharedPreferences para la URL del servidor.
  static const String kBaseUrl = 'fs_base_url';

  /// Clave de SharedPreferences para el modelo seleccionado.
  static const String kModel = 'fs_model';

  /// Clave de SharedPreferences para el historial serializado.
  static const String kHistory = 'fs_history';
}

/// Identificadores de los modelos servidos por el backend.
class ModelIds {
  ModelIds._();
  static const String baseline = 'baseline';
  static const String mobilenet = 'mobilenet';
}
