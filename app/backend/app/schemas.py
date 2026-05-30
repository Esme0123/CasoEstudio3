"""Modelos Pydantic de respuesta (contrato con la app Flutter)."""
from __future__ import annotations

from pydantic import BaseModel, Field


class ClassProbability(BaseModel):
    label: str = Field(..., description="Nombre interno de la clase (Negative/Positive)")
    label_es: str = Field(..., description="Etiqueta legible en español")
    probability: float = Field(..., ge=0.0, le=1.0)


class Prediction(BaseModel):
    model: str = Field(..., description="Modelo usado para la inferencia")
    label: str = Field(..., description="Clase predicha (nombre interno)")
    label_es: str = Field(..., description="Clase predicha (etiqueta legible)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Probabilidad de la clase predicha")
    probabilities: list[ClassProbability]
    weights_loaded: bool = Field(
        ..., description="True si se cargaron pesos entrenados; False = modelo sin entrenar"
    )


class GradCamResponse(BaseModel):
    prediction: Prediction
    gradcam_image: str = Field(..., description="Imagen del mapa de calor superpuesto (data URI PNG base64)")


class ModelInfo(BaseModel):
    name: str
    architecture: str
    weights_loaded: bool
    weights_path: str | None = None


class ModelsResponse(BaseModel):
    default: str
    models: list[ModelInfo]


class HealthResponse(BaseModel):
    status: str
    version: str
    device: str
    models: list[ModelInfo]
