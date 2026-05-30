// Modelos de datos que reflejan el contrato JSON del backend FastAPI.

/// Probabilidad de una clase concreta.
class ClassProbability {
  final String label; // "Negative" | "Positive"
  final String labelEs; // "Sin grieta" | "Con grieta"
  final double probability; // 0..1

  const ClassProbability({
    required this.label,
    required this.labelEs,
    required this.probability,
  });

  factory ClassProbability.fromJson(Map<String, dynamic> json) {
    return ClassProbability(
      label: json['label'] as String,
      labelEs: json['label_es'] as String,
      probability: (json['probability'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'label_es': labelEs,
        'probability': probability,
      };
}

/// Resultado de una predicción (`POST /predict`).
class Prediction {
  final String model; // baseline | mobilenet
  final String label; // Negative | Positive
  final String labelEs; // Sin grieta | Con grieta
  final double confidence; // 0..1
  final List<ClassProbability> probabilities;
  final bool weightsLoaded;

  const Prediction({
    required this.model,
    required this.label,
    required this.labelEs,
    required this.confidence,
    required this.probabilities,
    required this.weightsLoaded,
  });

  /// `true` si la predicción es "Con grieta" (clase Positive).
  bool get hasCrack => label == 'Positive';

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      model: json['model'] as String,
      label: json['label'] as String,
      labelEs: json['label_es'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: (json['probabilities'] as List<dynamic>)
          .map((e) => ClassProbability.fromJson(e as Map<String, dynamic>))
          .toList(),
      weightsLoaded: json['weights_loaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'label': label,
        'label_es': labelEs,
        'confidence': confidence,
        'probabilities': probabilities.map((e) => e.toJson()).toList(),
        'weights_loaded': weightsLoaded,
      };
}

/// Resultado de `POST /predict/gradcam`.
class GradCamResult {
  final Prediction prediction;

  /// Imagen del mapa de calor como data URI PNG base64.
  final String gradcamDataUri;

  const GradCamResult({
    required this.prediction,
    required this.gradcamDataUri,
  });

  factory GradCamResult.fromJson(Map<String, dynamic> json) {
    return GradCamResult(
      prediction: Prediction.fromJson(json['prediction'] as Map<String, dynamic>),
      gradcamDataUri: json['gradcam_image'] as String,
    );
  }
}
