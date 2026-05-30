import 'dart:convert';
import 'dart:typed_data';

import 'prediction.dart';

/// Registro de un análisis realizado, guardado en el historial local.
///
/// Guarda una miniatura de la imagen analizada (JPEG re-encodeado por
/// image_picker) en base64 para poder mostrarla sin acceder de nuevo al
/// archivo original.
class AnalysisRecord {
  final String id;
  final DateTime timestamp;
  final Prediction prediction;

  /// Miniatura de la imagen analizada (base64 sin prefijo data URI).
  final String thumbnailB64;

  const AnalysisRecord({
    required this.id,
    required this.timestamp,
    required this.prediction,
    required this.thumbnailB64,
  });

  Uint8List get thumbnailBytes => base64Decode(thumbnailB64);

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'prediction': prediction.toJson(),
        'thumb': thumbnailB64,
      };

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      prediction: Prediction.fromJson(json['prediction'] as Map<String, dynamic>),
      thumbnailB64: json['thumb'] as String,
    );
  }

  static String encodeList(List<AnalysisRecord> records) =>
      jsonEncode(records.map((e) => e.toJson()).toList());

  static List<AnalysisRecord> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AnalysisRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
