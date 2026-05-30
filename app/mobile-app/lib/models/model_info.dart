/// Información de un modelo disponible (`/models`, `/health`).
class ModelInfo {
  final String name; // baseline | mobilenet
  final String architecture; // "BaselineCNN", "MobileNetV3 (transfer learning)"
  final bool weightsLoaded;
  final String? weightsPath;

  const ModelInfo({
    required this.name,
    required this.architecture,
    required this.weightsLoaded,
    this.weightsPath,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      name: json['name'] as String,
      architecture: json['architecture'] as String,
      weightsLoaded: json['weights_loaded'] as bool? ?? false,
      weightsPath: json['weights_path'] as String?,
    );
  }
}

/// Respuesta de `GET /health`.
class HealthStatus {
  final String status;
  final String version;
  final String device; // cpu | cuda | mps
  final List<ModelInfo> models;

  const HealthStatus({
    required this.status,
    required this.version,
    required this.device,
    required this.models,
  });

  bool get isOk => status.toLowerCase() == 'ok';

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String,
      version: json['version'] as String,
      device: json['device'] as String,
      models: (json['models'] as List<dynamic>)
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
