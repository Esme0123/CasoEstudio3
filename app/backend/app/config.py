"""Configuración central del backend.

Las rutas y parámetros se pueden sobrescribir con variables de entorno
(prefijo ``APP_``), p. ej. ``APP_MODELS_DIR=/ruta/a/pesos``.
"""
from __future__ import annotations

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Directorio raíz del backend (.../app/backend)
BACKEND_ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", env_file=".env", extra="ignore")

    # --- Metadatos del servicio ---
    title: str = "API Clasificación de Grietas"
    version: str = "1.0.0"
    description: str = (
        "Servicio de inferencia para detección de grietas en superficies. "
        "Compara una CNN entrenada desde cero (Baseline) con un modelo de "
        "transferencia (MobileNet)."
    )

    # --- Carpeta donde se buscan los pesos entrenados (.pth) ---
    models_dir: Path = BACKEND_ROOT / "models"

    # Nombre del archivo de pesos esperado por cada modelo.
    baseline_weights: str = "baseline_cnn.pth"
    mobilenet_weights: str = "mobilenet_v4.pth"

    # Modelo usado por defecto cuando el cliente no especifica uno.
    default_model: str = "mobilenet"

    # --- Preprocesamiento (debe coincidir con el entrenamiento) ---
    image_size: int = 224
    norm_mean: tuple[float, float, float] = (0.485, 0.456, 0.406)
    norm_std: tuple[float, float, float] = (0.229, 0.224, 0.225)

    # Clases en el orden que produce torchvision.ImageFolder (alfabético).
    # Dataset surface-crack-detection: carpetas "Negative" y "Positive".
    class_names: tuple[str, str] = ("Negative", "Positive")
    # Etiquetas legibles para mostrar en la app.
    class_labels_es: tuple[str, str] = ("Sin grieta", "Con grieta")


settings = Settings()
