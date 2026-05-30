import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../models/model_info.dart';
import '../models/prediction.dart';

/// Excepción legible para errores de comunicación con el backend.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente del backend FastAPI de detección de grietas.
///
/// Endpoints cubiertos:
///  - GET  /health
///  - GET  /models
///  - POST /predict?model=...           (multipart `file`)
///  - POST /predict/gradcam?model=...   (multipart `file`)
class ApiService {
  ApiService(this.baseUrl);

  /// URL base sin barra final, p. ej. `http://10.0.2.2:8000`.
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalized$path').replace(queryParameters: query);
  }

  static const Duration _timeout = Duration(seconds: 30);

  /// Comprueba el estado del servicio y los modelos cargados.
  Future<HealthStatus> health() async {
    try {
      final res = await http.get(_uri('/health')).timeout(_timeout);
      if (res.statusCode != 200) {
        throw ApiException('El servidor respondió ${res.statusCode}.',
            statusCode: res.statusCode);
      }
      return HealthStatus.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_friendly(e));
    }
  }

  /// Lista los modelos disponibles y el modelo por defecto.
  Future<({String defaultModel, List<ModelInfo> models})> models() async {
    try {
      final res = await http.get(_uri('/models')).timeout(_timeout);
      if (res.statusCode != 200) {
        throw ApiException('El servidor respondió ${res.statusCode}.',
            statusCode: res.statusCode);
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        defaultModel: json['default'] as String,
        models: (json['models'] as List<dynamic>)
            .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_friendly(e));
    }
  }

  /// Clasifica una imagen. Devuelve la predicción estructurada.
  Future<Prediction> predict({
    required Uint8List bytes,
    required String filename,
    required String model,
    String? mimeType,
  }) async {
    final res = await _multipart('/predict', bytes, filename, model, mimeType);
    return Prediction.fromJson(jsonDecode(res) as Map<String, dynamic>);
  }

  /// Clasifica una imagen y devuelve además el mapa de calor Grad-CAM.
  Future<GradCamResult> predictGradcam({
    required Uint8List bytes,
    required String filename,
    required String model,
    String? mimeType,
  }) async {
    final res =
        await _multipart('/predict/gradcam', bytes, filename, model, mimeType);
    return GradCamResult.fromJson(jsonDecode(res) as Map<String, dynamic>);
  }

  Future<String> _multipart(
    String path,
    Uint8List bytes,
    String filename,
    String model,
    String? mimeType,
  ) async {
    try {
      final req = http.MultipartRequest('POST', _uri(path, {'model': model}))
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          // El backend rechaza el archivo si el content-type no empieza por
          // "image/". image_picker no siempre lo rellena (sobre todo en iOS),
          // así que lo fijamos explícitamente.
          contentType: _imageMediaType(mimeType, filename),
        ));
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        throw ApiException(_extractDetail(res),
            statusCode: res.statusCode);
      }
      return res.body;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_friendly(e));
    }
  }

  /// Determina un `MediaType` de imagen para el envío multipart.
  ///
  /// Usa el `mimeType` que reporte image_picker si es válido; si no, lo
  /// deduce de la extensión del archivo. Nunca devuelve un tipo genérico
  /// (octet-stream), que el backend rechazaría con 415.
  MediaType _imageMediaType(String? mimeType, String filename) {
    if (mimeType != null && mimeType.startsWith('image/')) {
      return MediaType.parse(mimeType);
    }
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    final subtype = switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      'gif' => 'gif',
      'bmp' => 'bmp',
      'heic' || 'heif' => 'heic',
      _ => 'jpeg', // jpg/jpeg y cualquier desconocido
    };
    return MediaType('image', subtype);
  }

  String _extractDetail(http.Response res) {
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return 'Error del servidor (${res.statusCode}).';
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException')) {
      return 'Tiempo de espera agotado. ¿El servidor está activo?';
    }
    if (s.contains('SocketException') ||
        s.contains('Connection') ||
        s.contains('Failed host lookup')) {
      return 'No se pudo conectar con el servidor.\nRevisa la URL en Ajustes.';
    }
    return 'Error de red: $s';
  }
}
